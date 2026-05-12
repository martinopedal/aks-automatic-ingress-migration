<#
.SYNOPSIS
    Generates a read-only inventory of ingress resources in a Kubernetes cluster.

.DESCRIPTION
    Collects information about existing Ingress resources, App Routing addon,
    and Gateway API resources. Produces a summary report in JSON or Markdown format.
    
    This script is read-only and never modifies cluster resources.

.PARAMETER KubeContext
    Kubernetes context to use. If omitted, uses the current context.

.PARAMETER OutputFormat
    Output format: json or markdown. Default is markdown.

.EXAMPLE
    Get-MigrationAssessment
    Generate a Markdown assessment report.

.EXAMPLE
    Get-MigrationAssessment -OutputFormat json | Out-File assessment.json
    Generate JSON output and save to file.

.LINK
    https://kubernetes.io/docs/concepts/services-networking/ingress/
#>
[CmdletBinding()]
param(
    [string]$KubeContext,

    [ValidateSet('json', 'markdown')]
    [string]$OutputFormat = 'markdown'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-KubectlGet {
    param(
        [string]$Resource,
        [string]$Namespace = '',
        [string]$Context = '',
        [switch]$AllNamespaces,
        [switch]$IgnoreNotFound
    )
    
    $args = @('get', $Resource, '-o', 'json')
    
    if ($AllNamespaces) { $args += '-A' }
    elseif ($Namespace) { $args += @('-n', $Namespace) }
    if ($Context) { $args += @('--context', $Context) }
    
    try {
        $output = & kubectl $args 2>&1
        if ($LASTEXITCODE -ne 0) {
            if ($IgnoreNotFound -and ($output -match 'NotFound|not found')) {
                return $null
            }
            throw "kubectl failed: $output"
        }
        return $output | ConvertFrom-Json
    }
    catch {
        if ($IgnoreNotFound) { return $null }
        throw
    }
}

function Get-IngressInventory {
    param([string]$Context)
    
    $ingressData = Invoke-KubectlGet -Resource 'ingress' -AllNamespaces -Context $Context
    
    if (-not $ingressData -or -not $ingressData.items) {
        return @{
            TotalCount = 0
            ByNamespace = @{}
            ByIngressClass = @{}
            Annotations = @{}
        }
    }
    
    $byNamespace = @{}
    $byIngressClass = @{}
    $annotations = @{}
    
    foreach ($ingress in $ingressData.items) {
        $ns = $ingress.metadata.namespace
        $ingressClass = if ($ingress.spec.ingressClassName) { $ingress.spec.ingressClassName } else { '(default)' }
        
        if (-not $byNamespace.ContainsKey($ns)) { $byNamespace[$ns] = 0 }
        $byNamespace[$ns]++
        
        if (-not $byIngressClass.ContainsKey($ingressClass)) { $byIngressClass[$ingressClass] = 0 }
        $byIngressClass[$ingressClass]++
        
        if ($ingress.metadata.annotations) {
            foreach ($annotation in $ingress.metadata.annotations.PSObject.Properties) {
                if (-not $annotations.ContainsKey($annotation.Name)) { $annotations[$annotation.Name] = 0 }
                $annotations[$annotation.Name]++
            }
        }
    }
    
    return @{
        TotalCount = $ingressData.items.Count
        ByNamespace = $byNamespace
        ByIngressClass = $byIngressClass
        Annotations = $annotations
    }
}

function Get-AppRoutingStatus {
    param([string]$Context)
    
    $data = Invoke-KubectlGet -Resource 'all' -Namespace 'app-routing-system' -Context $Context -IgnoreNotFound
    
    return @{
        Detected = ($null -ne $data -and $data.items.Count -gt 0)
        ResourceCount = if ($data) { $data.items.Count } else { 0 }
    }
}

function Get-GatewayApiStatus {
    param([string]$Context)
    
    $gatewayData = Invoke-KubectlGet -Resource 'gateway' -AllNamespaces -Context $Context -IgnoreNotFound
    $httpRouteData = Invoke-KubectlGet -Resource 'httproute' -AllNamespaces -Context $Context -IgnoreNotFound
    
    $gatewayCount = if ($gatewayData -and $gatewayData.items) { $gatewayData.items.Count } else { 0 }
    $httpRouteCount = if ($httpRouteData -and $httpRouteData.items) { $httpRouteData.items.Count } else { 0 }
    
    $crdsInstalled = $gatewayCount -gt 0 -or $httpRouteCount -gt 0
    
    return @{
        CRDsInstalled = $crdsInstalled
        GatewayCount = $gatewayCount
        HTTPRouteCount = $httpRouteCount
    }
}

function Format-AssessmentAsMarkdown {
    param([hashtable]$Assessment)
    
    $markdown = "# AKS Ingress Migration Assessment`n`n"
    $markdown += "**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
    $markdown += "**Context:** $($Assessment.Context)`n`n"
    $markdown += "## Summary`n`n"
    $markdown += "- **Total Ingress:** $($Assessment.Ingress.TotalCount)`n"
    $markdown += "- **App Routing:** $(if ($Assessment.AppRouting.Detected) { "Detected" } else { "Not detected" })`n"
    $markdown += "- **Gateway API CRDs:** $(if ($Assessment.GatewayAPI.CRDsInstalled) { "Installed" } else { "Not installed" })`n"
    $markdown += "- **Gateways:** $($Assessment.GatewayAPI.GatewayCount)`n"
    $markdown += "- **HTTPRoutes:** $($Assessment.GatewayAPI.HTTPRouteCount)`n`n"
    
    $markdown += "## Ingress by Namespace`n`n"
    if ($Assessment.Ingress.ByNamespace.Count -gt 0) {
        foreach ($ns in $Assessment.Ingress.ByNamespace.Keys | Sort-Object) {
            $count = $Assessment.Ingress.ByNamespace[$ns]
            $markdown += "- **${ns}:** $count`n"
        }
    }
    else { $markdown += "None found.`n" }
    
    $markdown += "`n## Ingress by Class`n`n"
    if ($Assessment.Ingress.ByIngressClass.Count -gt 0) {
        foreach ($class in $Assessment.Ingress.ByIngressClass.Keys | Sort-Object) {
            $count = $Assessment.Ingress.ByIngressClass[$class]
            $markdown += "- **${class}:** $count`n"
        }
    }
    else { $markdown += "None found.`n" }
    
    $markdown += "`n## Annotations in Use`n`n"
    if ($Assessment.Ingress.Annotations.Count -gt 0) {
        foreach ($annotation in $Assessment.Ingress.Annotations.Keys | Sort-Object) {
            $count = $Assessment.Ingress.Annotations[$annotation]
            $markdown += "- **${annotation}:** $count`n"
        }
    }
    else { $markdown += "None found.`n" }
    
    return $markdown
}

if ($KubeContext) {
    Write-Verbose "Using context: $KubeContext"
}
else {
    $currentContext = & kubectl config current-context 2>&1
    $KubeContext = if ($LASTEXITCODE -eq 0) { $currentContext } else { '(unknown)' }
}

Write-Information "Assessing cluster: $KubeContext" -InformationAction Continue

$assessment = @{
    Context = $KubeContext
    Timestamp = Get-Date -Format 'o'
    Ingress = Get-IngressInventory -Context $KubeContext
    AppRouting = Get-AppRoutingStatus -Context $KubeContext
    GatewayAPI = Get-GatewayApiStatus -Context $KubeContext
}

switch ($OutputFormat) {
    'json' { $assessment | ConvertTo-Json -Depth 10 }
    'markdown' { Format-AssessmentAsMarkdown -Assessment $assessment }
}
