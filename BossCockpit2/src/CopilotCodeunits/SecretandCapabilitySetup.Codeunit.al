codeunit 50201 "Secret and Capability Setup"
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
        IsolatedStorageWrapper: Codeunit "BOSSIsolated Storage Wrapper";
        LearnMoreUrlTxt: Label 'https://example.com/CopilotToolkit', Locked = true;
    begin
        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Generate Email Text") then
            CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Generate Email Text", Enum::"Copilot Availability"::Preview, LearnMoreUrlTxt);

        Error('Please set the secret key, deployment, and endpoint in the Isolated Storage Wrapper codeunit.');
        IsolatedStorageWrapper.SetSecretKey('');
        IsolatedStorageWrapper.SetDeployment('gpt-35-turbo');
        IsolatedStorageWrapper.SetEndpoint('');
    end;
}