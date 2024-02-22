table 50101 "BOSS Transcript Entry"
{
    DataClassification = ToBeClassified;

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
        field(3; "Import DateTime"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Timestamp';
        }
        field(4; "User ID"; Code[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'User ID';
        }
        field(5; Contact; code[20])
        {
            Caption = 'Contact';
            Tablerelation = Contact;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        Rec2: Record "BOSS Transcript Entry";
    begin
        if ("Entry No." = 0) then begin
            Rec2.Reset();
            if Rec2.FindLast() then
                "Entry No." := Rec2."Entry No." + 1
            else
                "Entry No." := 1;
        end;
    end;
}