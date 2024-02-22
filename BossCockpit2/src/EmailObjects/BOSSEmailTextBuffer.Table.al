table 50201 "BOSS Email Text Buffer"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'User ID';
        }
        field(2; EmailBody; Blob)
        {
            DataClassification = ToBeClassified;
            Caption = 'Email Body';
        }
    }

    keys
    {
        key(Key1; "User ID")
        {
            Clustered = true;
        }
    }
}