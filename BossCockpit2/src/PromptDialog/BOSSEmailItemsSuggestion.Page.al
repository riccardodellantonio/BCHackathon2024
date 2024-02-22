page 50202 "BOSS Email Items Suggestion"
{
    PageType = PromptDialog;
    Extensible = false;
    IsPreview = true;
    Caption = 'Create Items Suggestion Lines with Copilot';

    layout
    {
        area(Prompt)
        {
            field(ChatRequest; ChatRequest)
            {
                ShowCaption = false;
                MultiLine = true;
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    CurrPage.Update();
                end;
            }
        }

        area(Content)
        {
            part(SubsProposalSub; "Sales Quote Lines Proposal GPT")
            {
                ApplicationArea = All;
            }
        }
    }
    actions
    {
        area(SystemActions)
        {
            systemaction(Generate)
            {
                Caption = 'Generate';

                trigger OnAction()
                begin
                    RunGeneration();
                end;
            }
            systemaction(OK)
            {
                Caption = 'Confirm';
            }
            systemaction(Cancel)
            {
                Caption = 'Discard';
            }
            systemaction(Regenerate)
            {
                Caption = 'Regenerate';
                trigger OnAction()
                begin
                    RunGeneration();
                end;
            }
        }
    }

    trigger OnInit()
    var
        ChatRequestDefaultTxt: Label 'Format the reasoning tag as HTML';
    begin
        ChatRequest := ChatRequestDefaultTxt;
        CurrPage.PromptMode := PromptMode::Generate;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        SalesQuoteLinesProposal: Record "Sales Quote Lines Propoasal" temporary;
    begin
        if CloseAction = CloseAction::OK then begin
            CurrPage.SubsProposalSub.Page.RetrieveSelectedLines(SalesQuoteLinesProposal);
            if (SalesQuoteLinesProposal.Reasoning <> '') then
                UpdateEmailBodyText(SalesQuoteLinesProposal);
        end;
    end;

    local procedure RunGeneration()
    var
        Attempts: Integer;
    begin
        CurrPage.Caption := ChatRequest;
        GenSalesQuoteLines.SetUserPrompt(ChatRequest);
        GenSalesQuoteLines.SetSalesQuote(SalesQuote);

        TempSalesQuoteLinesProposal.Reset();
        TempSalesQuoteLinesProposal.DeleteAll();

        Attempts := 0;
        while TempSalesQuoteLinesProposal.IsEmpty and (Attempts < 5) do begin
            if GenSalesQuoteLines.Run() then
                GenSalesQuoteLines.GetResult(TempSalesQuoteLinesProposal);
            Attempts += 1;
        end;

        if (Attempts < 5) then
            Load(TempSalesQuoteLinesProposal)
        else
            Error('Something went wrong. Please try again. ' + GetLastErrorText());
    end;

    procedure SetSourceSalesQuote(SalesQuote2: Record "Sales Header")
    begin
        SalesQuote := SalesQuote2;
    end;

    procedure Load(var TempCustomerSubstAIProposal: Record "Sales Quote Lines Propoasal" temporary)
    begin
        CurrPage.SubsProposalSub.Page.Load(TempCustomerSubstAIProposal);
        CurrPage.Update(false);
    end;

    local procedure UpdateEmailBodyText(var SalesQuoteLinesProposal: Record "Sales Quote Lines Propoasal" temporary)
    var
        BOSSEmailTextBuffer: Record "BOSS Email Text Buffer";
        OutStr: OutStream;
        InStr: InStream;
        EmailText: Text;
        StringBuffer: TextBuilder;
        AdditionalItemsTxt: Label 'The System found additional items which could interest you. Please find the reasoning below: ';
    begin
        if not (BOSSEmailTextBuffer.Get(format(UserId))) then begin
            BOSSEmailTextBuffer.Init();
            BOSSEmailTextBuffer."User ID" := format(UserId);
            BOSSEmailTextBuffer.Insert();
        end;

        Clear(StringBuffer);
        BOSSEmailTextBuffer.CalcFields(EmailBody);
        BOSSEmailTextBuffer.EmailBody.CreateInStream(InStr);
        while not InStr.EOS do begin
            InStr.ReadText(EmailText);
            StringBuffer.Append(EmailText);
        end;

        if SalesQuoteLinesProposal.FindSet() then begin
            StringBuffer.Append('<p><b><i>' + AdditionalItemsTxt + '</i></b></p>');
            repeat
                StringBuffer.Append('<p>' + GetItemPictureAsHTMLTag(SalesQuoteLinesProposal."No.") + '<i>' + SalesQuoteLinesProposal.Desription + ' (' + SalesQuoteLinesProposal."No." + ') - ' + SalesQuoteLinesProposal.Reasoning + '</i></p>');
            until SalesQuoteLinesProposal.Next() = 0;
        end;

        Clear(BOSSEmailTextBuffer.EmailBody);
        BOSSEmailTextBuffer.EmailBody.CreateOutStream(OutStr);
        OutStr.Write(StringBuffer.ToText());
        BOSSEmailTextBuffer.Modify();
    end;

    local procedure GetItemPictureAsHTMLTag(ItemNo: Code[20]): Text
    var
        Item: Record Item;
        TenantMedia: Record "Tenant Media";
        Base64Converter: Codeunit "Base64 Convert";
        InStr: InStream;
        PictureBase64: Text;
    begin
        PictureBase64 := '';
        if Item.get(ItemNo) then
            if (Item.Picture.Count > 0) then
                if TenantMedia.Get(Item.Picture.Item(1)) then begin
                    TenantMedia.CalcFields(Content);
                    TenantMedia.Content.CreateInStream(InStr);
                    PictureBase64 := Base64Converter.ToBase64(InStr, false);
                end;

        if (PictureBase64 <> '') then
            exit('<img src="data:image/jpeg;base64,' + PictureBase64 + '" alt="Item Picture" width="100" height="100">');

        exit('');
    end;

    var
        TempSalesQuoteLinesProposal: Record "Sales Quote Lines Propoasal" temporary;
        GenSalesQuoteLines: Codeunit "Gen. Sales Quote Lines";
        SalesQuote: Record "Sales Header";
        ChatRequest: Text;
}