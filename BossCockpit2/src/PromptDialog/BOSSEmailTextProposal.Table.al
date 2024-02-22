table 50200 "BOSS Email Text Proposal"
{
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Entry No.';
        }
        field(2; EmailContent; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Content';
        }
        field(3; Description; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }
        field(10; Select; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Select';

            trigger OnValidate()
            var
                Rec2: Record "BOSS Email Text Proposal" temporary;
            begin
                if Select then begin
                    Rec2.Copy(Rec, true);
                    Rec2.SetRange(Select, true);
                    Rec2.SetFilter("Entry No.", '<>%1', Rec."Entry No.");
                    Rec2.ModifyAll("Select", false);
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }
}