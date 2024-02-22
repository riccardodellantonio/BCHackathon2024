codeunit 50105 "Copilot Transcript Activities"
{
    trigger OnRun()
    begin
        SummarizeContent();
    end;

    procedure SetSourceTable(BOSSTranscriptEntry2: Record "BOSS Transcript Entry")
    begin
        BOSSTranscriptEntry := BOSSTranscriptEntry2;
    end;

    procedure SetUserPrompt(InputUserPrompt: Text)
    begin
        UserPrompt := InputUserPrompt;
    end;

    procedure GetResult(var TempTranscriptActivitySummary2: Record "Transcript Activity Summary" temporary)
    begin
        TempTranscriptActivitySummary2.Copy(TempTranscriptActivitySummary, true);
    end;

    local procedure SummarizeContent()
    var
        CopilotFunctions: Codeunit "BOSS Copilot Functions";
        GPTTokenCount: Codeunit "GPT Tokens Count Impl.";
        InStream: InStream;
        TranscriptContent: Text;
        CopitlotTranscriptionInput: Text;
        CopilotOutput: Text;
        TokenCount: Integer;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonValue: JsonValue;

    begin
        BOSSTranscriptEntry.CalcFields("Transcript Content");
        BOSSTranscriptEntry."Transcript Content".CreateInStream(InStream);
        while not (InStream.EOS) do begin
            InStream.ReadText(TranscriptContent);
            if GPTTokenCount.PreciseTokenCount(TranscriptContent + CopitlotTranscriptionInput) >= 8000 then begin
                CopilotOutput := CopilotFunctions.Chat(GetSearchForContactSystemPrompt(), CopitlotTranscriptionInput, 0.9);
                CopilotOutput := CopyStr(CopilotOutput, CopilotOutput.IndexOf('{'), CopilotOutput.LastIndexOf('}') - CopilotOutput.IndexOf('{') + 1);
                Clear(CopitlotTranscriptionInput);

                AnalyzeSummaryAndGetResults(CopilotOutput)
            end;
            CopitlotTranscriptionInput += TranscriptContent
        end;
        CopilotOutput := CopilotFunctions.Chat(GetSearchForContactSystemPrompt(), CopitlotTranscriptionInput, 0.9);
        CopilotOutput := CopyStr(CopilotOutput, CopilotOutput.IndexOf('{'), CopilotOutput.LastIndexOf('}') - CopilotOutput.IndexOf('{') + 1);
        AnalyzeSummaryAndGetResults(CopilotOutput);
    end;

    local procedure AnalyzeSummaryAndGetResults(CopilotOutput: Text)
    var
        Counter: Integer;
        JsonManagement: Codeunit "JSON Management";
        JsonArrayText: Text;
        ArrayJSONManagement: Codeunit "JSON Management";
        EmailJsonObject: Text;
        ObjectJSONManagement: Codeunit "JSON Management";
        i: Integer;
        ObjectText: Text;
        OutStr: OutStream;
    begin
        JSONManagement.InitializeObject(CopilotOutput);
        if JSONManagement.GetArrayPropertyValueAsStringByName('summaries', JsonArrayText) then begin
            Counter := 1;
            ArrayJSONManagement.InitializeCollection(JsonArrayText);
            for i := 0 to ArrayJSONManagement.GetCollectionCount() - 1 do begin
                ArrayJSONManagement.GetObjectFromCollectionByIndex(EmailJsonObject, i);
                ObjectJSONManagement.InitializeObject(EmailJsonObject);
                TempTranscriptActivitySummary.Init();
                TempTranscriptActivitySummary."Entry No." := Counter;
                ObjectJSONManagement.GetStringPropertyValueByName('description', ObjectText);
                TempTranscriptActivitySummary.Description := CopyStr(ObjectText, 1, MaxStrLen(TempTranscriptActivitySummary.Description));
                ObjectJSONManagement.GetStringPropertyValueByName('content', ObjectText);
                TempTranscriptActivitySummary."Transcript Content".CreateOutStream(OutStr);
                OutStr.WriteText(ObjectText);
                if (TempTranscriptActivitySummary.Insert()) then
                    Counter += 1;
            end;
        end;
    end;

    local procedure GetSearchForContactSystemPrompt() FinalSystemPrompt: Text
    begin
        FinalSystemPrompt :=
            'The user will provide the transcript of a meeting with a customer' +
            'He will give you only part because of token limits.' +
            'Summarize the text below as a bullet point list of the most important points.' +
            'Generate JSON output without additional tags.' +
            'The JSON result should follow this schema: { "summaries": [ { "description": VALUE, "content": VALUE }, ... ] }' +
            'Propose 3 different summaries in the summaries array.' +
            'only one summaries array is allowed.';
    end;

    var
        BOSSTranscriptEntry: Record "BOSS Transcript Entry";
        TempTranscriptActivitySummary: Record "Transcript Activity Summary" temporary;
        UserPrompt, SalesLineItemFilter, SystemPrompt : Text;
}