<#
.SYNOPSIS
    Converts Kubernetes Ingress resources to Gateway API HTTPRoute resources.

.DESCRIPTION
    Wraps the ingress2gateway tool from kubernetes-sigs to translate Ingress YAML
    to Gateway API HTTPRoute YAML. Supports dry-run mode via -WhatIf for safety.
    
    Requires ingress2gateway binary on PATH. Install via:
      go install sigs.k8s.io/ingress2gateway@v1.0.0
    Or download from: https://github.com/kubernetes-sigs/ingress2gateway/releases

.PARAMETER InputPath
    Path to Ingress YAML file or directory. Mandatory.

.PARAMETER OutputPath
    Directory where translated Gateway API YAML will be written. Mandatory.

.PARAMETER Provider
    Ingress controller provider. Default is 'ingress-nginx'.
    Supported values: ingress-nginx, gce, kong, openshift.

.PARAMETER Force
    Bypass confirmation prompts.

.EXAMPLE
    Convert-IngressToGateway -InputPath ./ingress.yaml -OutputPath ./gateway -WhatIf
    Preview translation of a single Ingress file.

.EXAMPLE
    Convert-IngressToGateway -InputPath ./manifests -OutputPath ./gateway -Force
    Translate all Ingress resources in a directory without confirmation.

.LINK
    https://github.com/kubernetes-sigs/ingress2gateway
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$InputPath,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath,

    [ValidateSet('ingress-nginx', 'gce', 'kong', 'openshift')]
    [string]$Provider = 'ingress-nginx',

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Force -and -not $Confirm) {
    $ConfirmPreference = 'None'
}

function Test-Ingress2GatewayInstalled {
    try {
        $null = Get-Command ingress2gateway -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Get-IngressYamlFiles {
    param([string]$Path)
    
    if (Test-Path -Path $Path -PathType Leaf) {
        return @(Get-Item $Path)
    }
    elseif (Test-Path -Path $Path -PathType Container) {
        return Get-ChildItem -Path $Path -Filter *.yaml -Recurse -File
    }
    else {
        throw "Path not found: $Path"
    }
}

function Invoke-Ingress2Gateway {
    param(
        [string]$InputFile,
        [string]$ProviderName
    )
    
    $output = & ingress2gateway print --providers $ProviderName --input-file $InputFile 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        throw "ingress2gateway failed with exit code $LASTEXITCODE"
    }
    
    return $output
}

function Get-TranslationSummary {
    param([string]$YamlContent)
    
    $lines = $YamlContent -split "`n"
    $ingressCount = ($lines | Where-Object { $_ -match '^\s*kind:\s*Ingress\s*$' }).Count
    $gatewayCount = ($lines | Where-Object { $_ -match '^\s*kind:\s*Gateway\s*$' }).Count
    $httpRouteCount = ($lines | Where-Object { $_ -match '^\s*kind:\s*HTTPRoute\s*$' }).Count
    
    $droppedAnnotations = @{}
    foreach ($line in $lines) {
        if ($line -match '^\s*#.*annotation.*dropped.*:\s*(.+)$') {
            $annotation = $Matches[1].Trim()
            if (-not $droppedAnnotations.ContainsKey($annotation)) {
                $droppedAnnotations[$annotation] = 0
            }
            $droppedAnnotations[$annotation]++
        }
    }
    
    return @{
        IngressCount = $ingressCount
        GatewayCount = $gatewayCount
        HTTPRouteCount = $httpRouteCount
        DroppedAnnotations = $droppedAnnotations
    }
}

Write-Verbose "Starting Ingress to Gateway API translation"

if (-not (Test-Ingress2GatewayInstalled)) {
    Write-Error @"
ingress2gateway binary not found on PATH.

Install via Go:
  go install sigs.k8s.io/ingress2gateway@v1.0.0

Or download from:
  https://github.com/kubernetes-sigs/ingress2gateway/releases
"@
    exit 1
}

$InputPath = Resolve-Path $InputPath -ErrorAction Stop
$inputFiles = Get-IngressYamlFiles -Path $InputPath

Write-Information "Found $($inputFiles.Count) YAML file(s) to process" -InformationAction Continue

$totalSummary = @{
    IngressCount = 0
    GatewayCount = 0
    HTTPRouteCount = 0
    DroppedAnnotations = @{}
}

foreach ($file in $inputFiles) {
    Write-Verbose "Processing: $($file.FullName)"
    
    $translatedYaml = Invoke-Ingress2Gateway -InputFile $file.FullName -ProviderName $Provider
    
    $summary = Get-TranslationSummary -YamlContent $translatedYaml
    $totalSummary.IngressCount += $summary.IngressCount
    $totalSummary.GatewayCount += $summary.GatewayCount
    $totalSummary.HTTPRouteCount += $summary.HTTPRouteCount
    
    foreach ($annotation in $summary.DroppedAnnotations.Keys) {
        if (-not $totalSummary.DroppedAnnotations.ContainsKey($annotation)) {
            $totalSummary.DroppedAnnotations[$annotation] = 0
        }
        $totalSummary.DroppedAnnotations[$annotation] += $summary.DroppedAnnotations[$annotation]
    }
    
    $outputFileName = "$($file.BaseName)-gateway.yaml"
    $outputFilePath = Join-Path $OutputPath $outputFileName
    
    if ($PSCmdlet.ShouldProcess($outputFilePath, "Write translated YAML")) {
        New-Item -ItemType Directory -Force -Path $OutputPath -ErrorAction SilentlyContinue | Out-Null
        $translatedYaml | Out-File -FilePath $outputFilePath -Encoding utf8
        Write-Information "Written: $outputFilePath" -InformationAction Continue
    }
}

Write-Information "`n=== Translation Summary ===" -InformationAction Continue
Write-Information "Ingress resources: $($totalSummary.IngressCount)" -InformationAction Continue
Write-Information "Gateway resources: $($totalSummary.GatewayCount)" -InformationAction Continue
Write-Information "HTTPRoute resources: $($totalSummary.HTTPRouteCount)" -InformationAction Continue

if ($totalSummary.DroppedAnnotations.Count -gt 0) {
    Write-Information "`nDropped annotations:" -InformationAction Continue
    foreach ($annotation in $totalSummary.DroppedAnnotations.Keys | Sort-Object) {
        Write-Information "  $annotation (x$($totalSummary.DroppedAnnotations[$annotation]))" -InformationAction Continue
    }
}
