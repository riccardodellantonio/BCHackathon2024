page 50303 "Sales Quote Lines Proposal GPT"
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "Sales Quote Lines Propoasal";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(Copilot)
            {
                ShowCaption = false;
                field(Select; Rec.Select)
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        if rec.Select then
                            StyleExprTxt := 'favorable'
                        else
                            StyleExprTxt := 'standard';
                    end;

                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleExprTxt;
                }
                field(Desription; Rec.Desription)
                {
                    ApplicationArea = All;
                    StyleExpr = StyleExprTxt;
                }
                field(Explanation; Rec.Reasoning)
                {
                    ApplicationArea = All;
                    StyleExpr = StyleExprTxt;
                }
            }
        }

    }

    var
        StyleExprTxt: Text;

    procedure Load(var TempSalesQuoteLinesProposal: Record "Sales Quote Lines Propoasal" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();

        TempSalesQuoteLinesProposal.Reset();
        if TempSalesQuoteLinesProposal.FindSet() then
            repeat
                Rec.Copy(TempSalesQuoteLinesProposal, false);
                Rec.Insert();
            until TempSalesQuoteLinesProposal.Next() = 0;
        CurrPage.Update(false);
    end;

    procedure CreateItemLines(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        TempSalesQuoteLinesProposal: Record "Sales Quote Lines Propoasal" temporary;
        LineNo: Integer;
    begin
        TempSalesQuoteLinesProposal.Copy(Rec, true);
        TempSalesQuoteLinesProposal.SetRange(Select, true);



        if TempSalesQuoteLinesProposal.FindSet(true) then begin

            SalesLine.SetRange("Document No.", SalesHeader."No.");
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");

            SalesLine.SetLoadFields("Line No.", Type, "No.");
            if SalesLine.FindLast() then
                LineNo := SalesLine."Line No.";

            repeat
                LineNo += 10000;
                SalesLine.Init();
                SalesLine."Line No." := LineNo;
                SalesLine."Document Type" := SalesHeader."Document Type";
                SalesLine."Document No." := SalesHeader."No.";
                SalesLine.Validate(Type, SalesLine.Type::Item);
                SalesLine.Validate("No.", TempSalesQuoteLinesProposal."No.");
                SalesLine.Insert(true);
            until TempSalesQuoteLinesProposal.Next() = 0;
        end;
    end;

    procedure RetrieveSelectedLines(var SalesQuoteLinesProposal: record "Sales Quote Lines Propoasal" temporary)
    begin
        SalesQuoteLinesProposal.Copy(Rec, true);
        SalesQuoteLinesProposal.SetRange(Select, true);
    end;
}