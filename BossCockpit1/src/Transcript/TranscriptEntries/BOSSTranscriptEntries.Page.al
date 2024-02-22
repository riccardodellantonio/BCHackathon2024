page 50102 "BOSS Transcript Entries"
{
    Caption = 'Transcript Entries';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "BOSS Transcript Entry";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Import DateTime"; Rec."Import DateTime")
                {
                    ApplicationArea = All;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = ALL;
                }
                field("Transcript Content"; Rec."Transcript Content")
                {
                    ApplicationArea = All;
                    DrillDown = true;

                    trigger OnAssistEdit()
                    var
                        InStr: InStream;
                        TranscriptContentText: Text;
                        StringBuffer: TextBuilder;
                    begin
                        Rec.CalcFields("Transcript Content");
                        Rec."Transcript Content".CreateInStream(InStr);
                        while not (InStr.EOS) do begin
                            InStr.ReadText(TranscriptContentText);
                            StringBuffer.AppendLine(TranscriptContentText)
                        end;
                        Message(StringBuffer.ToText());
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UploadTranscript)
            {
                ApplicationArea = All;
                Caption = 'Upload Transcript';
                Image = ImportLog;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction();
                var
                    BOSSTranscriptEntry: Record "BOSS Transcript Entry";
                    FileInStream: InStream;
                    UploadDialogTxt: Label 'Upload Transcript';
                    FilePath: Text;
                    OutStream: OutStream;
                begin
                    FilePath := '';
                    UploadIntoStream(UploadDialogTxt, '', 'All files (*.*)|*.*', FilePath, FileInStream);

                    BOSSTranscriptEntry.Init();
                    BOSSTranscriptEntry.Insert(true);

                    BOSSTranscriptEntry.CalcFields("Transcript Content");
                    BOSSTranscriptEntry."Transcript Content".CreateOutStream(OutStream);
                    CopyStream(OutStream, FileInStream);
                    BOSSTranscriptEntry."Import DateTime" := Format(CurrentDateTime());
                    BOSSTranscriptEntry."User ID" := Format(UserId());
                    BOSSTranscriptEntry.Modify();
                end;
            }
            action(AnalyzeTranscript)
            {
                Caption = 'Analyze Transcript';
                Image = Sparkle;
                ApplicationArea = All;
                ToolTip = 'Search for contact informations inside of the transcript and generate summary for intercation log.';
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    CopilotTranscriptAnalyzer: Codeunit "Copilot Transcript Analyzer";
                    TranscriptEntry: Record "BOSS Transcript Entry";
                    TranscriptEntry2: Record "BOSS Transcript Entry";
                    TranscriptActivitySummary: Page "Transcript Activity Summary";
                begin
                    SetSelectionFilter(TranscriptEntry);
                    if TranscriptEntry.FindFirst() then
                        SuggestContactWithAI(TranscriptEntry);

                    if TranscriptEntry2.Get(TranscriptEntry."Entry No.") then
                        if TranscriptEntry2.Contact <> '' then begin
                            TranscriptActivitySummary.SetSources(TranscriptEntry2.Contact, Rec);
                            TranscriptActivitySummary.RunModal();
                        end;

                end;
            }
        }
    }
    local procedure SuggestContactWithAI(TranscriptEntry: Record "BOSS Transcript Entry");
    var
        ContactSuggestion: Page "BOSS Contact Suggestion";

    begin
        ContactSuggestion.SetSourceTransciptEntry(TranscriptEntry);
        ContactSuggestion.RunModal();
        CurrPage.Update(false);
    end;
}