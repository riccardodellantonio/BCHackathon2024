page 50104 "BOSS Contact Suggestion"
{
    PageType = PromptDialog;
    Extensible = false;
    IsPreview = true;
    Caption = '';

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
            part(SubsProposalSub; "BOSS GPT Contact Suggestion")
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
                Caption = 'Assign Contact & Generate Sumaries';
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

    trigger OnOpenPage()
    begin
        CurrPage.PromptMode := PromptMode::Generate;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = CloseAction::OK then
            CurrPage.SubsProposalSub.Page.GenerateSummariesForContact(TranscriptEntry);
    end;

    local procedure RunGeneration()
    var
        Attempts: Integer;
    begin
        CopilotTransciptAnalyzer.SetTranscriptEntry(TranscriptEntry);

        TempContactSuggestion.Reset();
        TempContactSuggestion.DeleteAll();

        Attempts := 0;
        while TempContactSuggestion.IsEmpty and (Attempts < 5) do begin
            if CopilotTransciptAnalyzer.Run() then
                CopilotTransciptAnalyzer.GetResult(TempContactSuggestion);
            Attempts += 1;
        end;

        if (Attempts < 5) then
            Load(TempContactSuggestion)
        else
            Error('Something went wrong. Please try again. ' + GetLastErrorText());
    end;

    procedure SetSourceTransciptEntry(TransciptEntry2: Record "BOSS Transcript Entry")
    begin
        TranscriptEntry := TransciptEntry2;
    end;

    procedure Load(var TempContactSuggestionSubsAIProposal: Record "BOSS Contact Suggestion" temporary)
    begin
        CurrPage.SubsProposalSub.Page.Load(TempContactSuggestionSubsAIProposal);
        CurrPage.Update(false);
    end;

    var
        TempContactSuggestion: Record "BOSS Contact Suggestion" temporary;
        TranscriptEntry: Record "BOSS Transcript Entry";
        CopilotTransciptAnalyzer: Codeunit "Copilot Transcript Analyzer";
        ChatRequest: Text;
}