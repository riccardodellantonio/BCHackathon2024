codeunit 50200 "Generate Email Text Proposal"
{
    trigger OnRun()
    begin
        GenerateItemProposal();
    end;

    procedure SetUserPrompt(InputUserPrompt: Text)
    begin
        UserPrompt := InputUserPrompt;
    end;

    procedure SetSourceSalesHeader(SalesHeader2: Record "Sales Header")
    begin
        SourceSalesHeader := SalesHeader2;
    end;

    procedure GetResult(var TempBOSSEmailTextProposal2: Record "BOSS Email Text Proposal" temporary)
    begin
        TempBOSSEmailTextProposal2.Copy(TempBOSSEmailTextProposal, true);
    end;

    local procedure GenerateItemProposal()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        TmpText: Text;
        Counter: Integer;
        JsonManagement: Codeunit "JSON Management";
        JsonArrayText: Text;
        ArrayJSONManagement: Codeunit "JSON Management";
        EmailJsonObject: Text;
        ObjectJSONManagement: Codeunit "JSON Management";
        i: Integer;
        ObjectText: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        TmpText := Chat(GetSystemPrompt(), GetFinalUserPrompt(UserPrompt));

        // Try to parse Json instead
        TmpText := CopyStr(TmpText, TmpText.IndexOf('{'), TmpText.LastIndexOf('}') - TmpText.IndexOf('{') + 1);

        JSONManagement.InitializeObject(TmpText);
        if JSONManagement.GetArrayPropertyValueAsStringByName('emails', JsonArrayText) then begin
            Counter := 1;
            ArrayJSONManagement.InitializeCollection(JsonArrayText);
            for i := 0 to ArrayJSONManagement.GetCollectionCount() - 1 do begin
                ArrayJSONManagement.GetObjectFromCollectionByIndex(EmailJsonObject, i);
                ObjectJSONManagement.InitializeObject(EmailJsonObject);
                TempBOSSEmailTextProposal.Init();
                TempBOSSEmailTextProposal."Entry No." := Counter;
                ObjectJSONManagement.GetStringPropertyValueByName('description', ObjectText);
                TempBOSSEmailTextProposal.Description := CopyStr(ObjectText, 1, MaxStrLen(TempBOSSEmailTextProposal.Description));
                ObjectJSONManagement.GetStringPropertyValueByName('content', ObjectText);
                TempBOSSEmailTextProposal.EmailContent.CreateOutStream(OutStr);
                OutStr.WriteText(ObjectText);
                if (tempBOSSEmailTextProposal.Insert()) then
                    Counter += 1;
            end;
        end;
    end;

    procedure Chat(ChatSystemPrompt: Text; ChatUserPrompt: Text): Text
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        BOSSIsolatedStorageWrapper: Codeunit "BOSSIsolated Storage Wrapper";
        Result: Text;
    begin
        // These funtions in the "Azure Open AI" codeunit will be available in Business Central online later this year.
        // You will need to use your own key for Azure OpenAI for all your Copilot features (for both development and production).
        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", BOSSIsolatedStorageWrapper.GetEndpoint(), BOSSIsolatedStorageWrapper.GetDeployment(), BOSSIsolatedStorageWrapper.GetSecretKey());

        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Generate Email Text");

        AOAIChatCompletionParams.SetMaxTokens(2500);
        AOAIChatCompletionParams.SetTemperature(0.4);

        AOAIChatMessages.AddSystemMessage(ChatSystemPrompt);
        AOAIChatMessages.AddUserMessage(ChatUserPrompt);

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);

        if AOAIOperationResponse.IsSuccess() then
            Result := AOAIChatMessages.GetLastMessage()
        else
            Error(AOAIOperationResponse.GetError());

        exit(Result);
    end;

    local procedure GetFinalUserPrompt(InputUserPrompt: Text) FinalUserPrompt: Text
    var
        Customer: Record Customer;
        TypeHelper: Codeunit "Type Helper";
        JsonManagement: Codeunit "JSON Management";
        RootElement: XmlElement;
        Element: XmlElement;
        XmlDoc: XmlDocument;
        XmlText: Text;
    begin
        if (SourceSalesHeader."No." <> '') then begin
            Customer.Get(SourceSalesHeader."Bill-to Customer No.");
            XmlDoc := XmlDocument.Create();
            FinalUserPrompt := 'These are the informations about the customer in json format:' + TypeHelper.NewLine();
            RootElement := XmlElement.Create('CustomerInformations');

            Element := XmlElement.Create('Customer');

            AddXMLElementItem(Element, 'Name', Format(customer.Name));

            RootElement.Add(Element);
            Clear(Element);

            Element := XmlElement.Create('SalesQuoteInformation');
            Element.Add(GetSalesQuoteAsXmlElement());
            RootElement.Add(Element);
        end;
        XmlDoc.Add(RootElement);
        XmlDoc.WriteTo(XmlText);

        FinalUserPrompt += JsonManagement.XMLTextToJSONText(XmlText);
        if (InputUserPrompt <> '') then begin
            FinalUserPrompt += TypeHelper.NewLine();
            FinalUserPrompt += InputUserPrompt;
        end;

    end;

    local procedure AddXMLElementItem(var parentElement: XmlElement; xmlTag: Text; xmlValue: Text)
    Element: XmlElement;
    begin
        Element := xmlElement.Create(xmlTag);
        Element.Add(XmlText.Create(xmlValue));
        parentElement.Add(Element);
    end;

    local procedure GetSalesQuoteAsXmlElement(): XmlElement
    var
        SalesLine: Record "Sales Line";
        SalesHeaderElement: XmlElement;
        SalesLinesElement: XmlElement;
        SalesLineElement: XmlElement;
    begin
        SalesHeaderElement := XmlElement.Create('SalesQuote');
        AddXMLElementItem(SalesHeaderElement, 'PostingDate', Format(SourceSalesHeader."Posting Date"));
        AddXMLElementItem(SalesHeaderElement, 'DocumentNo', Format(SourceSalesHeader."No."));
        AddXMLElementItem(SalesHeaderElement, 'Description', Format(SourceSalesHeader."Your Reference"));
        AddXMLElementItem(SalesHeaderElement, 'Amount', Format(SourceSalesHeader."Amount"));
        AddXMLElementItem(SalesHeaderElement, 'DueDate', Format(SourceSalesHeader."Due Date"));
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SourceSalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SourceSalesHeader."No.");
        if SalesLine.FindSet() then begin
            SalesLinesElement := XmlElement.Create('SalesLines');
            repeat
                SalesLineElement := XmlElement.Create('SalesLine');
                AddXMLElementItem(SalesLineElement, 'No', Format(SalesLine."No."));
                AddXMLElementItem(SalesLineElement, 'Description', Format(SalesLine.Description));
                AddXMLElementItem(SalesLineElement, 'Quantity', Format(SalesLine.Quantity));
                AddXMLElementItem(SalesLineElement, 'UnitPrice', Format(SalesLine."Unit Price"));
                AddXMLElementItem(SalesLineElement, 'Amount', Format(SalesLine.Amount));
                SalesLinesElement.Add(SalesLineElement);
            until SalesLine.Next() = 0;
            SalesHeaderElement.Add(SalesLinesElement);
        end;
        exit(SalesHeaderElement);
    end;

    local procedure GetSystemPrompt() SystemPrompt: Text
    begin
        SystemPrompt += 'The user will provide a customer description, and the sales quote that the customer requested. Your task is to create an email text proposal for the customer.';
        SystemPrompt += 'Try to describe the sales quote content without generating lists or tables.';
        SystemPrompt += 'The output should be in json, containing a short description of the email content (use description tag), and the generated Email body with HTML formatting (use content tag).';
        SystemPrompt += 'Use the name Boss Info AG as the sender of the email.';
        SystemPrompt += 'Generate JSON output without additional tags.';
        SystemPrompt += 'The JSON result should follow this schema: { "emails": [ { "description": VALUE, "content": VALUE }, ... ] }';
        SystemPrompt += 'Propose 3 different versions.';
    end;

    var
        SourceSalesHeader: Record "Sales Header";
        TempBOSSEmailTextProposal: Record "BOSS Email Text Proposal" temporary;
        UserPrompt: Text;
}