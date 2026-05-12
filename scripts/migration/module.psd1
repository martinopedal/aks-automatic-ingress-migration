@{
    RootModule = 'module.psm1'
    ModuleVersion = '0.1.0'
    GUID = '00000000-0000-0000-0000-000000000000'
    Author = 'AKS Automatic Migration Team'
    CompanyName = 'Microsoft'
    Copyright = '(c) Microsoft. All rights reserved.'
    Description = 'PowerShell module for migrating AKS Automatic clusters from ingress-nginx to Gateway API with Application Gateway for Containers'
    PowerShellVersion = '7.0'
    RequiredModules = @()
    FunctionsToExport = @(
        'Get-MigrationAssessment',
        'Convert-IngressToGateway',
        'Invoke-TrafficCutover'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('AKS','Kubernetes','Migration','GatewayAPI','AGC')
            ProjectUri = 'https://github.com/martinopedal/aks-automatic-ingress-migration'
        }
    }
}
