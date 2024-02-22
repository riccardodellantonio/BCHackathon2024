table 50102 "BOSS Contact Suggestion"
{

    fields
    {
        field(10; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = Contact;
        }
        field(20; "Contact Name"; Text[100])
        {
            Caption = 'Contact Name';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(30; Reasoning; text[2048])
        {
            Caption = 'Reasoning';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(40; Select; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Select';
            trigger OnValidate()
            var
                Rec2: Record "BOSS Contact Suggestion" temporary;
            begin
                if Select then begin
                    Rec2.Copy(Rec, true);
                    Rec2.SetRange(Select, true);
                    Rec2.SetFilter("Contact No.", '<>%1', Rec."Contact No.");
                    Rec2.ModifyAll("Select", false);
                end;
            end;
        }
    }

    keys
    {
        key(PK; "Contact No.")
        {
            Clustered = true;
        }
    }
}