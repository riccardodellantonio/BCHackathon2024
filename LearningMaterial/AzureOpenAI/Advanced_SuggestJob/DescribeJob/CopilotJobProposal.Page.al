namespace CopilotToolkitDemo.DescribeJob;

using Microsoft.Sales.Customer;

page 54320 "Copilot Job Proposal"
{
    PageType = PromptDialog;
    Extensible = false;
    Caption = 'Draft new job with Copilot';
    DataCaptionExpression = InputProjectDescription;
    IsPreview = true;

    layout
    {
        area(Prompt) // <--- this is the input section
        {
            field(ProjectDescriptionField; InputProjectDescription)
            {
                ApplicationArea = All;
                ShowCaption = false;
                MultiLine = true;
            }
        }
        area(Content) // <--- this is the output section
        {
            field("Job Short Description"; JobDescription)
            {
                ApplicationArea = All;
                Caption = 'Job Short Description';
            }
            field("Job Full Details"; JobFullDescription)
            {
                ApplicationArea = All;
                MultiLine = true;
                Caption = 'Details';
            }
            field(CustomerNameField; CustomerName)
            {
                ApplicationArea = All;
                Caption = 'Customer Name';
                ShowMandatory = true;

                trigger OnAssistEdit()
                var
                    Customer: Record Customer;
                begin
                    if not Customer.SelectCustomer(Customer) then
                        Clear(Customer);

                    CustomerName := Customer.Name;
                    CustomerNo := Customer."No.";
                end;

                trigger OnValidate()
                begin
                    FindCustomerNameAndNumber(CustomerName, false);
                end;
            }
            part(ProposalDetails; "Copilot Job Proposal Subpart")
            {
                Caption = 'Job structure';
                ShowFilter = false;
                ApplicationArea = All;
                Editable = true;
                Enabled = true;
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
                ToolTip = 'Generate job structure with Dynamics 365 Copilot.';

                trigger OnAction()
                begin
                    RunGeneration();
                end;
            }
            systemaction(OK)
            {
                Caption = 'Keep it';
                ToolTip = 'Save the Job proposed by Dynamics 365 Copilot.';
            }
            systemaction(Cancel)
            {
                Caption = 'Discard it';
                ToolTip = 'Discard the Job proposed by Dynamics 365 Copilot.';
            }
            systemaction(Regenerate)
            {
                Caption = 'Regenerate';
                ToolTip = 'Regenerate the Job proposed by Dynamics 365 Copilot.';

                trigger OnAction()
                begin
                    RunGeneration();
                end;
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        SaveCopilotJobProposal: Codeunit "Save Copilot Job Proposal";
    begin
        if CloseAction = CloseAction::OK then
            SaveCopilotJobProposal.Save(CustomerNo, CopilotJobProposal);
    end;

    local procedure RunGeneration()
    var
        GenJobProposal: Codeunit "Generate Job Proposal";
        InStr: InStream;
        ProgressDialog: Dialog;
        Attempts: Integer;
    begin
        ProgressDialog.Open(GeneratingTextDialogTxt);
        GenJobProposal.SetUserPrompt(InputProjectDescription);

        CopilotJobProposal.Reset();
        CopilotJobProposal.DeleteAll();

        for Attempts := 0 to 3 do
            if GenJobProposal.Run() then begin
                GenJobProposal.GetResult(CopilotJobProposal);

                if not CopilotJobProposal.IsEmpty() then begin
                    CopilotJobProposal.FindFirst();

                    JobDescription := CopilotJobProposal."Job Short Description";
                    CopilotJobProposal.CalcFields("Job Full Description");
                    CopilotJobProposal."Job Full Description".CreateInStream(InStr);
                    InStr.ReadText(JobFullDescription);

                    FindCustomerNameAndNumber(CopilotJobProposal."Job Customer Name", true);

                    CurrPage.ProposalDetails.Page.Load(CopilotJobProposal);
                    exit;
                end;
            end;

        if GetLastErrorText() = '' then
            Error(SomethingWentWrongErr)
        else
            Error(SomethingWentWrongWithLatestErr, GetLastErrorText());
    end;

    local procedure FindCustomerNameAndNumber(InputCustomerName: Text; Silent: Boolean)
    var
        Customer: Record Customer;
    begin
        if InputCustomerName <> '' then begin
            Customer.SetFilter("Search Name", '%1', '*' + UpperCase(InputCustomerName) + '*');

            if not Customer.FindFirst() then
                if not Silent then
                    Error(CustomerDoesNotExistErr);
        end;

        CustomerName := Customer.Name;
        CustomerNo := Customer."No.";
    end;

    var
        GeneratingTextDialogTxt: Label 'Generating with Copilot...';
        SomethingWentWrongErr: Label 'Something went wrong. Please try again.';
        SomethingWentWrongWithLatestErr: Label 'Something went wrong. Please try again. The latest error is: %1';
        CustomerDoesNotExistErr: Label 'Customer does not exist';
        CustomerNo: Code[20];
        CopilotJobProposal: Record "Copilot Job Proposal" temporary;
        JobFullDescription: Text;
        InputProjectDescription: Text;
        JobDescription: Text[100];
        CustomerName: Text[100];
}