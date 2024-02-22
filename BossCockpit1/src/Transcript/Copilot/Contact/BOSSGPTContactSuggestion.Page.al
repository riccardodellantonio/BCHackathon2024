page 50103 "BOSS GPT Contact Suggestion"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "BOSS Contact Suggestion";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                ShowCaption = false;
                field(Select; Rec.Select)
                {
                    ApplicationArea = All;
                }
                field("Contact No"; Rec."Contact No.")
                {
                    ApplicationArea = All;

                }
                field("Contact Name"; Rec."Contact Name")
                {
                    ApplicationArea = All;
                }
                field(Reasoning; Rec.Reasoning)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    procedure Load(var ContactSuggestions: Record "BOSS Contact Suggestion" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();

        ContactSuggestions.Reset();
        if ContactSuggestions.FindSet() then
            repeat
                Rec.Copy(ContactSuggestions, false);
                Rec.Insert();
            until ContactSuggestions.Next() = 0;
        CurrPage.Update(false);
    end;

    procedure GenerateSummariesForContact(TranscriptEntry: record "BOSS Transcript Entry")
    var
        TempContactSuggest: Record "BOSS Contact Suggestion" temporary;
    begin
        TempContactSuggest.Copy(Rec, true);
        TempContactSuggest.SetRange(Select, true);
        if TempContactSuggest.FindFirst() then begin
            TranscriptEntry.Contact := TempContactSuggest."Contact No.";
            TranscriptEntry.Modify();
        end;
    end;

}