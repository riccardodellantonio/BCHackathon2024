pageextension 50302 "Sales Quote Lines" extends "Sales Quote Subform"
{

    actions
    {
        addafter("&Line")
        {
            action(GenerateCopilot)
            {
                Caption = 'Suggest additional item/s with Copilot';
                Image = Sparkle;
                ApplicationArea = All;
                ToolTip = 'Lets Copilot suggest additional item that could match the item(s) included in the quote.';

                trigger OnAction()
                var
                    SalesHeader: Record "Sales Header";
                begin
                    IF SalesHeader.get(rec."Document Type", rec."Document No.") then
                        SuggestSubstitutionsWithAI(SalesHeader);
                end;
            }
        }
    }

    local procedure SuggestSubstitutionsWithAI(SalesHeader: Record "Sales Header");
    var
        SalesQuoteLineProposal: Page "Sales Quote Lines Proposal";
    begin
        SalesQuoteLineProposal.SetSourceSalesQuote(SalesHeader);
        SalesQuoteLineProposal.RunModal();
        CurrPage.Update(false);
    end;
}