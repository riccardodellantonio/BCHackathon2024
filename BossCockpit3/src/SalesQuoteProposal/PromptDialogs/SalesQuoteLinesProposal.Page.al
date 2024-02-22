page 50304 "Sales Quote Lines Proposal"
{
    PageType = PromptDialog;
    Extensible = false;
    IsPreview = true;
    Caption = 'Add additional description (optional)';


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
            part(SubsProposalSub; "Sales Quote Lines Proposal GPT")
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
                Caption = 'Add Selected Items';
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

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = CloseAction::OK then
            CurrPage.SubsProposalSub.Page.CreateItemLines(SalesHeader);
    end;

    local procedure RunGeneration()
    var
        Attempts: Integer;
    begin
        CurrPage.Caption := ChatRequest;
        GenSalesQuoteLines.SetUserPrompt(ChatRequest);
        GenSalesQuoteLines.SetSalesQuote(SalesHeader);

        TempSalesQuoteLinesProposal.Reset();
        TempSalesQuoteLinesProposal.DeleteAll();

        Attempts := 0;
        while TempSalesQuoteLinesProposal.IsEmpty and (Attempts < 5) do begin
            if GenSalesQuoteLines.Run() then
                GenSalesQuoteLines.GetResult(TempSalesQuoteLinesProposal);
            Attempts += 1;
        end;

        if (Attempts < 5) then
            Load(TempSalesQuoteLinesProposal)
        else
            Error('Something went wrong. Please try again. ' + GetLastErrorText());
    end;

    procedure SetSourceSalesQuote(SalesHeader2: Record "Sales Header")
    begin
        SalesHeader := SalesHeader2;
    end;

    procedure Load(var TempCustomerSubstAIProposal: Record "Sales Quote Lines Propoasal" temporary)
    begin
        CurrPage.SubsProposalSub.Page.Load(TempCustomerSubstAIProposal);
        CurrPage.Update(false);
    end;

    var
        TempSalesQuoteLinesProposal: Record "Sales Quote Lines Propoasal" temporary;
        SalesHeader: Record "Sales Header";
        GenSalesQuoteLines: Codeunit "Gen. Sales Quote Lines";
        ChatRequest: Text;
}