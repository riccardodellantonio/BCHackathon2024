codeunit 50101 "Copilot Transcript Analyzer"
{
    trigger OnRun()
    begin
        SearchForcontact();
    end;


    procedure GetResult(var InputTempContactSuggestions: Record "BOSS Contact Suggestion" temporary)
    begin
        InputTempContactSuggestions.Copy(TempContactSuggestions, true);
    end;

    procedure SetTranscriptEntry(TrnascriptEntry2: Record "BOSS Transcript Entry")
    begin
        TranscriptEntry := TrnascriptEntry2;
    end;

    procedure SearchForcontact()
    var
        CopilotFunctions: Codeunit "BOSS Copilot Functions";
        GPTTokenCount: Codeunit "GPT Tokens Count Impl.";
        InStream: InStream;
        TranscriptContent: Text;
        CopitlotTranscriptionInput: Text;
        CopilotOutput: Text;
    begin
        TranscriptEntry.CalcFields("Transcript Content");
        TranscriptEntry."Transcript Content".CreateInStream(InStream);
        while not (InStream.EOS) do begin
            InStream.ReadText(TranscriptContent);
            if GPTTokenCount.PreciseTokenCount(TranscriptContent + CopitlotTranscriptionInput + GetSearchForContactSystemPrompt()) >= 8000 then begin
                CopilotOutput := CopilotFunctions.Chat(GetSearchForContactSystemPrompt(), CopitlotTranscriptionInput, 0.1);
                CopilotOutput := CopyStr(CopilotOutput, CopilotOutput.IndexOf('{'), CopilotOutput.LastIndexOf('}') - CopilotOutput.IndexOf('{') + 1);
                Clear(CopitlotTranscriptionInput);
                InsertContactInformationToTable(CopilotOutput);
            end;
            CopitlotTranscriptionInput += TranscriptContent
        end;
        CopilotOutput := CopilotFunctions.Chat(GetSearchForContactSystemPrompt(), CopitlotTranscriptionInput, 0.1);
        CopilotOutput := CopyStr(CopilotOutput, CopilotOutput.IndexOf('{'), CopilotOutput.LastIndexOf('}') - CopilotOutput.IndexOf('{') + 1);
        InsertContactInformationToTable(CopilotOutput);
    end;

    local procedure GetSearchForContactSystemPrompt() FinalSystemPrompt: Text
    begin
        FinalSystemPrompt :=
            'The user will provide u with a part of transcript form a call with contact' +
            'He will give you only part because of token limits.' +
            'U will be provided with information which part of conversation it is.' +
            'I wan u to analyze this part of conversation and look for informations about the contact' +
            'You should look for informations like: name of contact, phone number of contact, location of contact, company' +
            'Write aswell reasoning why u have choosen those informations.' +
            'If you find those informations send those back in a JSON-Format build as follows:' +
            '"CompanyInformations": [ {"Name": VALUE, "phone number": VALUE, "location": VALUE, "company" VALUE, "reasoning": VALUE}, ]';
    end;

    local procedure InsertContactInformationToTable(CopilotOutput: Text)
    var
        Contact: record contact;
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JsonObjects: List of [JsonObject];
        ContactName: Text;
        ContactPhone: Text;
        CompanyName: Text;
        Reasoning: text;
    begin
        JsonObject.ReadFrom(CopilotOutput);
        JsonObject.Get('CompanyInformations', JsonToken);
        if JsonToken.IsArray then
            JsonArray := JsonToken.AsArray()
        else
            if JsonToken.IsObject then
                JsonObjects.Add(JsonToken.AsObject())
            else
                Error('Invalid JSON');

        foreach JsonToken in JsonArray do
            if JsonToken.IsObject then
                JsonObjects.Add(JsonToken.AsObject());


        foreach JsonObject in JsonObjects do begin
            if JsonObject.Get('Name', JsonToken) then
                if not (JsonToken.AsValue().IsNull or JsonToken.AsValue().IsUndefined) then
                    ContactName := JsonToken.AsValue().AsText();
            if JsonObject.Get('phone number', JsonToken) then
                if not (JsonToken.AsValue().IsNull or JsonToken.AsValue().IsUndefined) then
                    ContactPhone := JsonToken.AsValue().AsText();
            if JsonObject.Get('company', JsonToken) then
                if not (JsonToken.AsValue().IsNull or JsonToken.AsValue().IsUndefined) then
                    CompanyName := JsonToken.AsValue().AsText();
            if JsonObject.Get('reasoning', JsonToken) then
                if not (JsonToken.AsValue().IsNull or JsonToken.AsValue().IsUndefined) then
                    Reasoning := JsonToken.AsValue().AsText();

            Contact.FilterGroup(-1);
            if ContactName <> '' then
                Contact.SetFilter(Name, '%1', '*' + ContactName + '*');
            if ContactPhone <> '' then begin
                Contact.SetFilter("Phone No.", '%1', '*' + ContactPhone + '*');
                Contact.SetFilter("Mobile Phone No.", '%1', '*' + ContactPhone + '*');
            end;
            if CompanyName <> '' then
                Contact.SetFilter("Company Name", '%1', '*' + CompanyName + '*');

            if Contact.GetFilters() <> '' then
                if Contact.FindSet() then
                    repeat
                        TempContactSuggestions.Init();
                        TempContactSuggestions."Contact No." := Contact."No.";
                        TempContactSuggestions."Contact Name" := Contact.Name;
                        TempContactSuggestions.Reasoning := CopyStr(Reasoning, 1, MaxStrLen(TempContactSuggestions.Reasoning));
                        if TempContactSuggestions.Insert() then;
                    until contact.Next() = 0;
        end;



    end;

    var
        TranscriptEntry: Record "BOSS Transcript Entry";
        TempContactSuggestions: Record "BOSS Contact Suggestion" temporary;
}