pageextension 50200 "BOSS Email Editor Ext" extends "Email Editor"
{
    actions
    {
        addlast(Processing)
        {
            action("BOSS SuggestEMailBody")
            {
                Caption = 'Suggest EMail body with Copilot';
                Image = Sparkle;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    SuggestEmailBodyWithCopilot();
                end;

            }
        }
    }

    local procedure SuggestEmailBodyWithCopilot()
    begin
        Message('TODO');
    end;
}