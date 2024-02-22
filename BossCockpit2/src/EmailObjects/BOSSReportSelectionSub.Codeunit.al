codeunit 50203 "BOSS Report Selection Sub"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document-Print", 'OnBeforeDoPrintSalesHeader', '', false, false)]
    local procedure OnBeforeDoPrintSalesHeader_GenerateEmailBody
    (
        ReportUsage: Integer;
        SendAsEmail: Boolean;
        var IsPrinted: Boolean;
        var SalesHeader: Record "Sales Header"
    )
    var
        BOSSEmailTextProposal: Page "BOSS Email Text Proposal";
        BOSSEmailItemsSuggestions: Page "BOSS Email Items Suggestion";
        ConfirmationTxt: Label 'Do you want Copilot to generate an Email Text for this Quote?';
        ItemSuggestionConfirmationTxt: Label 'Do you want Copilot to suggest additional items for this Quote?';
    begin
        if (SalesHeader."Document Type" = SalesHeader."Document Type"::Quote) then
            if Confirm(ConfirmationTxt) then begin
                BOSSEmailTextProposal.SetSourceSalesHeader(SalesHeader);
                BOSSEmailTextProposal.RunModal();

                // Run a second prompt to retrieve the Suggested Items
                if (Confirm(ItemSuggestionConfirmationTxt)) then begin
                    BOSSEmailItemsSuggestions.SetSourceSalesQuote(SalesHeader);
                    BOSSEmailItemsSuggestions.RunModal();
                end;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mail Management", 'OnSendViaEmailModuleOnAfterCreateMessage', '', false, false)]
    local procedure OnSendViaEmailModuleOnAfterCreateMessage_UpdateEmailBody
    (
        var Message: Codeunit "Email Message";
        var TempEmailItem: Record "Email Item" temporary
    )
    var
        BOSSEmailTextBuffer: Record "BOSS Email Text Buffer";
        StringBuffer: TextBuilder;
        InStr: InStream;
        LineText: Text;
    begin
        if BOSSEmailTextBuffer.Get(Format(UserId())) then begin
            BOSSEmailTextBuffer.CalcFields(EmailBody);
            BOSSEmailTextBuffer.EmailBody.CreateInStream(InStr);
            while not InStr.Eos do begin
                InStr.ReadText(LineText);
                StringBuffer.Append(LineText);
            end;

            Message.SetBody(StringBuffer.ToText());
            BOSSEmailTextBuffer.Delete();
        end;
    end;

    /*
        [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnBeforeGetEmailBodyCustomer', '', false, false)]
        local procedure OnBeforeGetEmailBodyCustomer_UpdateEmailBody(
            CustNo: Code[20];
            RecordVariant: Variant;
            ReportUsage: Integer;
            var CustEmailAddress: Text[250];
            var EmailBodyText: Text;
            var IsHandled: Boolean;
            var Result: Boolean;
            var TempBodyReportSelections: Record "Report Selections" temporary
        )
        var
            SalesHeader: Record "Sales Header";
            BOSSEmailTextBuffer: Record "BOSS Email Text Buffer";
            DataTypeManagement: Codeunit "Data Type Management";
            RecRef: RecordRef;
            InStr: InStream;
            SalesHeaderFound: Boolean;
        begin
            SalesHeaderFound := false;
            case true of
                RecordVariant.IsRecordRef:
                    begin
                        RecRef := RecordVariant;
                        if RecRef.Number = Database::"Sales Header" then begin
                            RecRef.SetTable(SalesHeader);
                            SalesHeaderFound := true;
                        end;
                    end;
                RecordVariant.IsRecord:
                    if DataTypeManagement.GetRecordRef(RecordVariant, RecRef) then
                        if RecRef.Number = Database::"Sales Header" then begin
                            SalesHeader := RecordVariant;
                            SalesHeaderFound := true;
                        end;
                else
                    exit;
            end;

            if SalesHeaderFound then
                if (SalesHeader."Document Type" = SalesHeader."Document Type"::Quote) then begin
                    BOSSEmailTextBuffer.Reset();
                    BOSSEmailTextBuffer.SetRange(RecordId, RecRef.RecordId());
                    if (BOSSEmailTextBuffer.FindFirst()) then begin
                        BOSSEmailTextBuffer.CalcFields(EmailBody);
                        BOSSEmailTextBuffer.EmailBody.CreateInStream(InStr);
                        InStr.ReadText(EmailBodyText);
                        BOSSEmailTextBuffer.Delete();
                    end;
                end;
        end;
        */
}