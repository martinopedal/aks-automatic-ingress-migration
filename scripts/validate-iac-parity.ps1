#!/usr/bin/env pwsh
# Script to validate IaC output parity between Terraform and Bicep modules
# Per ADR-002, both stacks must expose outputs matching the schema contract

param(
    [Parameter(Mandatory=$true)]
    [string]$SchemaPath,

    [Parameter(Mandatory=$true)]
    [string]$TerraformModulePath,

    [Parameter(Mandatory=$true)]
    [string]$BicepModulePath
)

$ErrorActionPreference = 'Stop'

Write-Host "=== IaC Parity Validation ===" -ForegroundColor Cyan
Write-Host "Schema: $SchemaPath"
Write-Host "Terraform: $TerraformModulePath"
Write-Host "Bicep: $BicepModulePath"
Write-Host ""

# Load the schema
if (-not (Test-Path $SchemaPath)) {
    Write-Error "Schema file not found: $SchemaPath"
    exit 1
}

$schema = Get-Content $SchemaPath -Raw | ConvertFrom-Json
$requiredOutputs = $schema.required
$outputProperties = $schema.properties

Write-Host "Required outputs per schema: $($requiredOutputs -join ', ')" -ForegroundColor Yellow
Write-Host ""

# Parse Terraform outputs.tf
Write-Host "Validating Terraform module..." -ForegroundColor Green
$tfOutputsPath = Join-Path $TerraformModulePath "outputs.tf"
if (-not (Test-Path $tfOutputsPath)) {
    Write-Error "Terraform outputs.tf not found at $tfOutputsPath"
    exit 1
}

$tfContent = Get-Content $tfOutputsPath -Raw
$tfOutputNames = @()
foreach ($match in [regex]::Matches($tfContent, 'output\s+"([^"]+)"')) {
    $tfOutputNames += $match.Groups[1].Value
}

Write-Host "Terraform outputs declared: $($tfOutputNames -join ', ')"

# Check Terraform completeness
$missingInTf = $requiredOutputs | Where-Object { $_ -notin $tfOutputNames }
if ($missingInTf) {
    Write-Error "Terraform module missing required outputs: $($missingInTf -join ', ')"
    exit 1
}

$extraInTf = $tfOutputNames | Where-Object { $_ -notin $requiredOutputs }
if ($extraInTf) {
    Write-Error "Terraform module has undeclared outputs (not in schema): $($extraInTf -join ', ')"
    exit 1
}

Write-Host "✓ Terraform outputs match schema" -ForegroundColor Green
Write-Host ""

# Parse Bicep outputs
Write-Host "Validating Bicep module..." -ForegroundColor Green
$bicepMainPath = Join-Path $BicepModulePath "main.bicep"
if (-not (Test-Path $bicepMainPath)) {
    Write-Error "Bicep main.bicep not found at $bicepMainPath"
    exit 1
}

$bicepContent = Get-Content $bicepMainPath -Raw
$bicepOutputNames = @()
foreach ($match in [regex]::Matches($bicepContent, 'output\s+([a-zA-Z_][a-zA-Z0-9_]*)\s+')) {
    $bicepOutputNames += $match.Groups[1].Value
}

Write-Host "Bicep outputs declared: $($bicepOutputNames -join ', ')"

# Check Bicep completeness
$missingInBicep = $requiredOutputs | Where-Object { $_ -notin $bicepOutputNames }
if ($missingInBicep) {
    Write-Error "Bicep module missing required outputs: $($missingInBicep -join ', ')"
    exit 1
}

$extraInBicep = $bicepOutputNames | Where-Object { $_ -notin $requiredOutputs }
if ($extraInBicep) {
    Write-Error "Bicep module has undeclared outputs (not in schema): $($extraInBicep -join ', ')"
    exit 1
}

Write-Host "✓ Bicep outputs match schema" -ForegroundColor Green
Write-Host ""

# Final check: Terraform and Bicep have identical output sets
$tfSorted = $tfOutputNames | Sort-Object
$bicepSorted = $bicepOutputNames | Sort-Object

if (Compare-Object $tfSorted $bicepSorted) {
    Write-Error "Terraform and Bicep output sets do not match. This should not happen if both passed schema checks."
    exit 1
}

Write-Host "=== ✓ Parity Validation Passed ===" -ForegroundColor Cyan
Write-Host "Terraform and Bicep modules both satisfy $SchemaPath" -ForegroundColor Cyan
exit 0
