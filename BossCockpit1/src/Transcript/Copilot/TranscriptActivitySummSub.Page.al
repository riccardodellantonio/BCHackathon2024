page 50106 "Transcript Activity Summ. Sub"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Transcript Activity Summary";

    layout
    {
        area(Content)
        {
            repeater(TranscriptActivitySummary)
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
            }
        }
    }

    var
        ExplanationTxt: Label 'Click on the "Select" field to view the transcript content.';

    procedure Load(var TempTranscriptActivitySummary: Record "Transcript Activity Summary" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();

        TempTranscriptActivitySummary.Reset();
        if TempTranscriptActivitySummary.FindSet() then
            repeat
                TempTranscriptActivitySummary.CalcFields("Transcript Content");
                Rec.Copy(TempTranscriptActivitySummary, false);
                Rec."Transcript Content" := TempTranscriptActivitySummary."Transcript Content";
                Rec.Insert();
            until TempTranscriptActivitySummary.Next() = 0;

        CurrPage.Update(false);
    end;

    procedure SaveContactActivity(ContactNo: Code[20]; BOSSTranscriptEntry: Record "BOSS Transcript Entry")
    var
        TempTranscriptActivitySummary2: Record "Transcript Activity Summary" temporary;
        InteractionLogEntry: Record "Interaction Log Entry";
        Contact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
        StandardDescriptionTxt: Label 'Meeting AI-Transcript';
        LineNo: Integer;
        InStr: InStream;
        LineText: Text;
        EntryCorrectlyInsertedTxt: Label 'The interaction log entry was correctly inserted.';
    begin
        Contact.Get(ContactNo);
        TempTranscriptActivitySummary2.Copy(Rec, true);
        TempTranscriptActivitySummary2.SetRange(Select, true);

        if TempTranscriptActivitySummary2.FindFirst() then begin

            InteractionLogEntry.Init();

            InteractionLogEntry."Contact No." := ContactNo;
            InteractionLogEntry."Contact Company No." := Contact."Company No.";
            InteractionLogEntry.Date := Today();
            InteractionLogEntry.Description := StandardDescriptionTxt;
            InteractionLogEntry."Initiated By" := InteractionLogEntry."Initiated By"::" ";
            InteractionLogEntry."User ID" := BOSSTranscriptEntry."User ID";
            InteractionLogEntry.Subject := TempTranscriptActivitySummary2.Description;
            InteractionLogEntry."Salesperson Code" := Contact."Salesperson Code";
            InteractionLogEntry."Correspondence Type" := InteractionLogEntry."Correspondence Type"::" ";
            InteractionLogEntry."Document Type" := InteractionLogEntry."Document Type"::" ";
            InteractionLogEntry."Document No." := '';

            InteractionTemplate.Reset();
            InteractionTemplate.SetRange("BOSS Transcript Summary Default", true);
            if InteractionTemplate.FindFirst() then
                InteractionLogEntry."Interaction Template Code" := InteractionTemplate.Code;

            InteractionLogEntry.InsertRecord();

            TempTranscriptActivitySummary2.CalcFields("Transcript Content");
            TempTranscriptActivitySummary2."Transcript Content".CreateInStream(InStr);

            LineNo := 0;
            while not (InStr.EOS) do begin
                InStr.ReadText(LineText);
                SplitTextIntoCommentLines(LineText, InteractionLogEntry."Entry No.", LineNo);
            end;

            Message(EntryCorrectlyInsertedTxt);
        end;
    end;

    local procedure SplitTextIntoCommentLines(InputText: Text; EntryNo: Integer; var LineNo: Integer)
    var
        InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line";
        CuttedText: Text;
        ReprocessSplit: Boolean;
    begin
        ReprocessSplit := false;
        CuttedText := InputText;
        if (StrLen(CuttedText) > MaxStrLen(InterLogEntryCommentLine.Comment)) then begin
            CuttedText := CopyStr(CuttedText, 1, MaxStrLen(InterLogEntryCommentLine.Comment));
            ReprocessSplit := true;
        end;

        // Insert Comment Line
        LineNo += 10000;
        InterLogEntryCommentLine.Init();
        InterLogEntryCommentLine."Entry No." := EntryNo;
        InterLogEntryCommentLine."Line No." := LineNo;
        InterLogEntryCommentLine.Comment := CuttedText;
        InterLogEntryCommentLine.Insert();

        if ReprocessSplit then begin
            InputText := CopyStr(InputText, (MaxStrLen(InterLogEntryCommentLine.Comment) + 1));
            SplitTextIntoCommentLines(InputText, EntryNo, LineNo);
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
        TranscriptContentText: Text;
        StringBuffer: TextBuilder;
    begin
        Rec.CalcFields("Transcript Content");
        Rec."Transcript Content".CreateInStream(InStr);
        while not (InStr.EOS) do begin
            InStr.ReadText(TranscriptContentText);
            if (HTMLFormatted) then
                StringBuffer.AppendLine(TranscriptContentText)
            else
                StringBuffer.AppendLine(RemoveHTMLFormatting(TranscriptContentText));
        end;
        Message(StringBuffer.ToText());
        CurrPage.Update(false);
    end;
}