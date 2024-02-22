table 50103 "Transcript Activity Summary"
{
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Entry No.';
        }
        field(2; "Transcript Content"; Blob)
        {
            DataClassification = ToBeClassified;
            Caption = 'Content';
        }
        field(3; Select; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Select';

            trigger OnValidate()
            var
                Rec2: Record "Transcript Activity Summary" temporary;
            begin
                if Select then begin
                    Rec2.Copy(Rec, true);
                    Rec2.SetRange(Select, true);
                    Rec2.SetFilter("Entry No.", '<>%1', Rec."Entry No.");
                    Rec2.ModifyAll("Select", false);
                end;
            end;
        }
        field(4; Description; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Description';
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