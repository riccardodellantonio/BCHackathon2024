page 50201 "BOSS Email Text Proposal Sub"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "BOSS Email Text Proposal";

    layout
    {
        area(Content)
        {
            repeater(EmailTextProposals)
            {
                Caption = ' ';
                ShowCaption = false;

                field(Select; Rec.Select)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        DisplayMessage(false);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Explanation; ExplanationTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Details';
                    Editable = false;
                    Style = StrongAccent;
                }
                field(HTMLFormattedMsg; ShowHTMLMessageTxt)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        DisplayMessage(true);
                    end;
                }
            }
        }
    }

    var
        ExplanationTxt: Label 'Click on the "Select" field to view the email content.';
        ShowHTMLMessageTxt: label 'Show HTML Message';

    procedure Load(var TempBOSSEmailTextProposal: Record "BOSS Email Text Proposal" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();

        TempBOSSEmailTextProposal.Reset();
        if TempBOSSEmailTextProposal.FindSet() then
            repeat
                TempBOSSEmailTextProposal.CalcFields(EmailContent);
                Rec.Copy(TempBOSSEmailTextProposal, false);
                Rec.EmailContent := TempBOSSEmailTextProposal.EmailContent;
                Rec.Insert();
            until TempBOSSEmailTextProposal.Next() = 0;

        CurrPage.Update(false);
    end;

    procedure StoreEmailBodyText()
    var
        TempBOSSEmailTextProposal2: Record "BOSS Email Text Proposal" temporary;
        BOSSEmailTextBuffer: Record "BOSS Email Text Buffer";
    begin
        TempBOSSEmailTextProposal2.Copy(Rec, true);
        TempBOSSEmailTextProposal2.SetRange(Select, true);

        if TempBOSSEmailTextProposal2.FindFirst() then begin
            TempBOSSEmailTextProposal2.CalcFields(EmailContent);

            // Clean the Email Buffer first
            if (BOSSEmailTextBuffer.Get(Format(UserId()))) then
                BOSSEmailTextBuffer.Delete();

            BOSSEmailTextBuffer.Init();
            BOSSEmailTextBuffer."User ID" := Format(UserId());
            BOSSEmailTextBuffer.EmailBody := TempBOSSEmailTextProposal2.EmailContent;
            BOSSEmailTextBuffer.Insert();
        end;
    end;

    local procedure RemoveHTMLFormatting(InputText: Text): Text
    var
        OpenTagPos: Integer;
        ClosingTagPos: Integer;
        OrgText: Text;
        EvaluatedTag: text;
        AddCarriageReturn: Boolean;
    begin
        OrgText := InputText;
        while (StrPos(OrgText, '<') > 0) do begin
            AddCarriageReturn := false;
            OpenTagPos := StrPos(OrgText, '<');
            ClosingTagPos := StrPos(OrgText, '>');
            if (ClosingTagPos > OpenTagPos) then begin
                EvaluatedTag := CopyStr(OrgText, OpenTagPos, (ClosingTagPos - OpenTagPos + 1));
                if (EvaluatedTag = '</p>') or (EvaluatedTag = '<br>') then
                    AddCarriageReturn := true;
                OrgText := DelStr(OrgText, OpenTagPos, (ClosingTagPos - OpenTagPos + 1));
                if (AddCarriageReturn) then
                    OrgText := InsStr(OrgText, '\\', OpenTagPos);
            end;
        end;

        exit(OrgText);
    end;

    local procedure DisplayMessage(HTMLFormatted: Boolean)
    var
        InStr: InStream;
        EmailBody: Text;
        StringBuffer: TextBuilder;
    begin
        Rec.CalcFields(EmailContent);
        Rec.EmailContent.CreateInStream(InStr);
        while not (InStr.EOS) do begin
            InStr.ReadText(EmailBody);
            if (HTMLFormatted) then
                StringBuffer.AppendLine(EmailBody)
            else
                StringBuffer.AppendLine(RemoveHTMLFormatting(EmailBody));
        end;
        Message(StringBuffer.ToText());
        CurrPage.Update(false);
    end;
}