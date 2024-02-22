table 50301 "Sales Quote Lines Propoasal"
{

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        field(2; Desription; Text[100])
        {
            Caption = 'No.';
            Editable = false;
        }
        field(10; Reasoning; Text[2048])
        {
            Caption = 'Reasoning';
            Editable = false;
        }
        field(20; Select; Boolean)
        {
            DataClassification = CustomerContent;
        }

    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }

}