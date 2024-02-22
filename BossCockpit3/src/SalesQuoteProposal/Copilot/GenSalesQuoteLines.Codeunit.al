codeunit 50305 "Gen. Sales Quote Lines"
{
    trigger OnRun()
    begin
        Clear(AlreadySuggestedLines);
        Clear(UniqueItemCount);
        Clear(SalesLineItemFilter);
        Generate();
    end;

    procedure SetSalesQuote(SalesHeader2: Record "Sales Header")
    begin
        SalesHeader := SalesHeader2;
    end;

    procedure SetUserPrompt(InputUserPrompt: Text)
    begin
        UserPrompt := InputUserPrompt;
    end;

    procedure SetSystemPrompt(_SystemPrompt: Text)
    begin
        SystemPrompt := SystemPrompt;
    end;

    procedure GetResult(var InputTempSalesQuoteLinesProposal: Record "Sales Quote Lines Propoasal" temporary)
    begin
        InputTempSalesQuoteLinesProposal.Copy(TempSalesQuoteLinesProposal, true);
    end;

    local procedure Generate()
    var
        Item_l: Record Item;
        CopilotFunctions: Codeunit "Copilot Functions";
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        JsonToken, JsonToken2 : JsonToken;
        JsonValue: JsonValue;
        CopilotOutput, SystemFinalPrompt, UserFinalPrompt : text;
    begin
        //Even if Systemprompt set by another app (BossCockpit2 in our case) make sure that output is the same
        if SystemPrompt <> '' then
            SystemFinalPrompt := SystemPrompt + 'Generate JSON output without additional tags.' +
            'JSON should be build as follows: "Items": ["Item": {"No": VALUE, "Reasoning": Value}, ... ]'
        else
            SystemFinalPrompt := GetSystemPrompt();

        //Create suggestion per item to minimalize token ussage.
        repeat
            UserFinalPrompt := GetFinalUserPrompt(UserPrompt);
            CopilotOutput := CopilotFunctions.Chat(SystemFinalPrompt, UserFinalPrompt, 0.2);
            //Get rid of additional content and hope that it is a valid JSON.
            CopilotOutput := CopyStr(CopilotOutput, CopilotOutput.IndexOf('{'), CopilotOutput.LastIndexOf('}') - CopilotOutput.IndexOf('{') + 1);

            if JsonObject.ReadFrom(CopilotOutput) then begin

                JsonObject.Get('Items', JsonToken);
                JsonArray := JsonToken.AsArray();

                foreach JsonToken in JsonArray do begin
                    JsonObject := JsonToken.AsObject();

                    if JsonObject.Contains('Item') then begin
                        JsonObject.Get('Item', JsonToken);
                        JsonObject := JsonToken.AsObject();
                    end;

                    JsonObject.Get('No', JsonToken2);
                    JsonValue := JsonToken2.AsValue();
                    TempSalesQuoteLinesProposal."No." := CopyStr(JsonValue.AsCode(), 1, MaxStrLen(TempSalesQuoteLinesProposal."No."));

                    if Item_l.get(TempSalesQuoteLinesProposal."No.") then begin
                        TempSalesQuoteLinesProposal.Init();

                        JsonObject.Get('Reasoning', JsonToken2);
                        JsonValue := JsonToken2.AsValue();
                        TempSalesQuoteLinesProposal.Reasoning := CopyStr(JsonValue.AsText(), 1, MaxStrLen(TempSalesQuoteLinesProposal.Reasoning));

                        TempSalesQuoteLinesProposal.Desription := Item_l.Description;

                        if not TempSalesQuoteLinesProposal.Insert() then
                            if TempSalesQuoteLinesProposal.Get(TempSalesQuoteLinesProposal."No.") then begin
                                TempSalesQuoteLinesProposal.Reasoning := CopyStr(TempSalesQuoteLinesProposal.Reasoning + JsonValue.AsText(), 1, MaxStrLen(TempSalesQuoteLinesProposal.Reasoning));
                                TempSalesQuoteLinesProposal.Modify();
                            end;
                    end
                end;
            end else
                Error(InvalidAnswer_Err);
        until UniqueItemCount = AlreadySuggestedLines.Count;

        //Sumarize the reasoning, make sure there are no repetitions
        if TempSalesQuoteLinesProposal.FindSet() then
            repeat
                CopilotOutput := CopilotFunctions.Chat(getReasoningSystemPrompt(), TempSalesQuoteLinesProposal.Reasoning, 0.3);
                CopilotOutput := CopyStr(CopilotOutput, CopilotOutput.IndexOf('{'), CopilotOutput.LastIndexOf('}') - CopilotOutput.IndexOf('{') + 1);
                JsonObject.ReadFrom(CopilotOutput);
                JsonObject.Get('Reasoning', JsonToken);
                TempSalesQuoteLinesProposal.Reasoning := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(TempSalesQuoteLinesProposal.Reasoning));
                TempSalesQuoteLinesProposal.Modify();
            until TempSalesQuoteLinesProposal.Next() = 0;
    end;


    local procedure GetSystemPrompt() FinalSystemPrompt: Text
    begin
        FinalSystemPrompt :=
            'The user will give you information about the current sales quote they are creating for a customer.' +
            'User will also provide the items he wants to offer to this customer.' +
            'Your task is to suggest additional items that the user could sell to this customer. You have to choose this items of out those which were provided to you' +
            'To do this, you will be given another dataset with information about which items are sold together with this item/s and to which customers.' +
            'In Tag "Additional User Description" you will find aswell additional informations. Try to optimize search according to those informations' +
            'Provide vareity reasoning for your choices for every item, including attributes.' +
            'Generate JSON output without additional tags.' +
            'JSON should be build as follows: "Items": ["Item": {"No": VALUE, "Reasoning": Value}, ... ]';
    end;

    local procedure getReasoningSystemPrompt() ReasoningSystemPrompt: Text
    begin
        ReasoningSystemPrompt :=
        'User is offering the customer additional items for sell.' +
        'You will be provided with reasoning why the customer would want to buy this item' +
        'If you find any repeatitions in this text could you sumarize them?' +
        'Generate JSON output without additional tags.' +
        'JSON should be build as follows: {"Reasoning": VALUE}';
    end;

    local procedure GetFinalUserPrompt(AddUserInput: Text) FinalPrompt: Text
    var
        SalesLine: Record "Sales Line";
        JsonObject, SalesQuoteObject, SalesLinesObject : JsonObject;
        ItemNo: Code[20];
    begin
        SalesQuoteObject.Add('Additional User Description', AddUserInput);
        SalesQuoteObject.Add('Customer Name', SalesHeader."Sell-to Customer Name");


        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SetItemCount(SalesLine);

        if SalesLineItemFilter <> '' then
            SalesLine.SetFilter("No.", '<>%1', SalesLineItemFilter);


        SalesLine.SetLoadFields("No.", Description, "Description 2", "Item Category Code");
        if SalesLine.FindFirst() then begin
            AlreadySuggestedLines.Add(SalesLine."No.");
            SalesLinesObject.Add('No.', SalesLine."No.");
            SalesLinesObject.Add('Description', SalesLine.Description + SalesLine."Description 2");
            SalesLinesObject.Add('Category Code', SalesLine."Item Category Code");
            SalesLinesObject.Add('Attributes', GetItemAttributes(SalesLine."No."));
            SalesLinesObject.Add('Commonly Sold With', GetCommonlySoldWithItems(SalesLine));
        end;

        SalesQuoteObject.Add('Item', SalesLinesObject);
        JsonObject.Add('Sales Quote', SalesQuoteObject);
        JsonObject.WriteTo(FinalPrompt);

        foreach ItemNo in AlreadySuggestedLines do
            SalesLineItemFilter := ItemNo + '|';
        SalesLineItemFilter := CopyStr(SalesLineItemFilter, 1, SalesLineItemFilter.LastIndexOf('|') - 1);
    end;

    local procedure GetCommonlySoldWithItems(SalesLine: Record "Sales Line") CommonlySoldWith: JsonArray;
    var
        SalesShipmentLines: Record "Sales Shipment Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CommonlySoldWithItem: JsonObject;
    begin
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Sales Shipment");
        ItemLedgerEntry.SetRange("Item No.", SalesLine."No.");

        ItemLedgerEntry.SetLoadFields("Document No.");
        if ItemLedgerEntry.FindSet() then begin
            Clear(CommonlySoldWith);
            repeat
                SalesShipmentLines.SetRange("Document No.", ItemLedgerEntry."Document No.");
                SalesShipmentLines.SetRange(Type, SalesShipmentLines.Type::Item);
                SalesShipmentLines.SetFilter("No.", '<>%1', SalesLine."No.");
                SalesShipmentLines.SetLoadFields("No.", Description, "Description 2");
                if SalesShipmentLines.FindSet() then
                    repeat
                        Clear(CommonlySoldWithItem);
                        CommonlySoldWithItem.Add('No', SalesShipmentLines."No.");
                        CommonlySoldWithItem.Add('Description', SalesShipmentLines.Description + SalesShipmentLines."Description 2");
                        CommonlySoldWithItem.Add('Attributes', GetItemAttributes(SalesShipmentLines."No."));
                        CommonlySoldWith.Add(CommonlySoldWithItem);
                    until SalesShipmentLines.Next() = 0;
            until ItemLedgerEntry.Next() = 0
        end;
    end;

    local procedure GetItemAttributes(ItemNo: Code[20]) JSONItemAttributes: JsonObject
    var
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        ItemAttributeValueMapping.SetRange("Table ID", 27);
        ItemAttributeValueMapping.SetRange("No.", ItemNo);

        ItemAttributeValueMapping.SetLoadFields("Item Attribute ID", "Item Attribute Value ID");
        if ItemAttributeValueMapping.FindSet() then begin
            ItemAttributeValue.SetAutoCalcFields("Attribute Name");
            repeat
                ItemAttributeValue.Get(ItemAttributeValueMapping."Item Attribute ID", ItemAttributeValueMapping."Item Attribute Value ID");
                JSONItemAttributes.Add(ItemAttributeValue."Attribute Name", ItemAttributeValue.Value);
            until ItemAttributeValueMapping.Next() = 0;
        end;
    end;

    local procedure SetItemCount(var SalesLine: record "Sales Line")
    var
        SalesLine2: Record "Sales Line";
        UniqueItems: list of [Code[20]];
    begin
        SalesLine2.copy(SalesLine, false);
        if SalesLine2.FindSet() then
            repeat
                if not UniqueItems.Contains(SalesLine2."No.") then
                    UniqueItems.Add(SalesLine2."No.");
            until SalesLine2.Next() = 0
        else
            Error(NoItemSalesLines_Err);
        UniqueItemCount := UniqueItems.Count;
    end;

    var
        TempSalesQuoteLinesProposal: record "Sales Quote Lines Propoasal" temporary;
        SalesHeader: Record "Sales Header";
        InvalidAnswer_Err: Label 'The answer was not able to be processed.';
        NoItemSalesLines_Err: Label 'There are no sales lines from which we could create Suggestions! Add some lines of type item and try again.';
        UniqueItemCount: Integer;
        AlreadySuggestedLines: List of [Code[20]];
        UserPrompt, SalesLineItemFilter, SystemPrompt : Text;
}
