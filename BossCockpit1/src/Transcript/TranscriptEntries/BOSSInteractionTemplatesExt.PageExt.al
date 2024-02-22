pageextension 50101 "BOSS Interaction Templates Ext" extends "Interaction Templates"
{
    layout
    {
        addlast(Control1)
        {
            field("BOSS Transcript Summary Default"; Rec."BOSS Transcript Summary Default")
            {
                ApplicationArea = All;
            }
        }
    }
}