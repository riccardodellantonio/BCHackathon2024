permissionset 50100 BossCockpit1
{
    Assignable = true;
    Permissions = tabledata "BOSS Contact Suggestion"=RIMD,
        tabledata "BOSS Transcript Entry"=RIMD,
        tabledata "Transcript Activity Summary"=RIMD,
        table "BOSS Contact Suggestion"=X,
        table "BOSS Transcript Entry"=X,
        table "Transcript Activity Summary"=X,
        codeunit "BOSS Copilot Functions"=X,
        codeunit "BOSS Isolated Storage Wrapper"=X,
        codeunit "Copilot Transcript Activities"=X,
        codeunit "Copilot Transcript Analyzer"=X,
        codeunit "Secrets And Capabilities Setup"=X,
        page "BOSS Contact Suggestion"=X,
        page "BOSS GPT Contact Suggestion"=X,
        page "BOSS Transcript Entries"=X,
        page "Transcript Activity Summ. Sub"=X,
        page "Transcript Activity Summary"=X;
}