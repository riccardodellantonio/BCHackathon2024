pageextension 50107 "BOSS Cont Int. Entries Sub Ext" extends "Contact Int. Entries Subform"
{
    layout
    {
        addafter(Comment)
        {
            field("BOSS DispayComment"; DisplayCommentTxt)
            {
                ApplicationArea = All;
                ShowCaption = false;
                Enabled = false;
                DrillDown = true;

                trigger OnAssistEdit()
                begin
                    ShowCommentLines();
                end;
            }
        }
    }

    var
        DisplayCommentTxt: Label 'Show Comment';

    local procedure ShowCommentLines()
    var
        InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line";
        TextBuilder: TextBuilder;
    begin
        Clear(TextBuilder);
        InterLogEntryCommentLine.Reset();
        InterLogEntryCommentLine.SetRange("Entry No.", Rec."Entry No.");
        if InterLogEntryCommentLine.FindSet() then
            repeat
                TextBuilder.Append(InterLogEntryCommentLine.Comment);
            until InterLogEntryCommentLine.Next() = 0;

        if TextBuilder.Length > 0 then
            Message(TextBuilder.ToText());
    end;
}