codeunit 50302 "Secrets And Capabilities Setup"
{
    Subtype = Install;
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    trigger OnInstallAppPerDatabase()
    begin
        RegisterCapability();
    end;

    local procedure RegisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        IsolatedStorageWrapper: Codeunit "BOSS Isolated Storage Wrapper";
        LearnMoreUrlTxt: Label 'https://example.com/CopilotToolkit', Locked = true;
    begin
        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Customer Report") then
            CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Customer Report", Enum::"Copilot Availability"::Preview, LearnMoreUrlTxt);


        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Create Sales Quote Lines") then
            CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Create Sales Quote Lines", Enum::"Copilot Availability"::Preview, LearnMoreUrlTxt);

        Error('Please set the secret key, deployment, and endpoint in the Isolated Storage Wrapper codeunit.');
        IsolatedStorageWrapper.SetSecretKey('');
        IsolatedStorageWrapper.SetDeployment('gpt-35-turbo');
        IsolatedStorageWrapper.SetEndpoint('');
    end;
}