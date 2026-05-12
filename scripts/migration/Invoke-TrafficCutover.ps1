<#
.SYNOPSIS
    Validates traffic cutover readiness and generates a human-driven checklist.

.DESCRIPTION
    Compares existing Ingress resources with HTTPRoute resources to validate
    migration readiness. Produces a numbered checklist for manual execution.
    
    This script never mutates cluster resources. Traffic cutover is human-driven.

.PARAMETER FromGatewayClassName
    Current Gateway or IngressClass name (e.g., webapprouting.kubernetes.azure.com).

.PARAMETER ToGatewayClassName
    Target Gateway class. Default is 'azure-application-load-balancer'.

.PARAMETER Namespace
    Kubernetes namespace to analyze. Mandatory.

.PARAMETER DryRun
    Preview mode. Default is $true. Even with -DryRun:$false, this script only
    generates a checklist and never mutates resources.

.EXAMPLE
    Invoke-TrafficCutover -FromGatewayClassName nginx -Namespace myapp
    Generate a cutover checklist.

.LINK
    https://learn.microsoft.com/azure/application-gateway/for-containers/
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$FromGatewayClassName,

    [string]$ToGatewayClassName = 'azure-application-load-balancer',

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Namespace,

    [bool]$DryRun = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-KubectlGet {
    param(
        [string]$Resource,
        [string]$Namespace
    )
    
    $args = @('get', $Resource, '-n', $Namespace, '-o', 'json')
    
    try {
        $output = & kubectl $args 2>&1
        if ($LASTEXITCODE -ne 0) {
            if ($output -match 'NotFound|not found') { return $null }
            throw "kubectl failed: $output"
        }
        return $output | ConvertFrom-Json
    }
    catch { throw }
}

function Get-IngressRoutes {
    param([string]$Namespace, [string]$IngressClassName)
    
    $ingressData = Invoke-KubectlGet -Resource 'ingress' -Namespace $Namespace
    if (-not $ingressData -or -not $ingressData.items) { return @() }
    
    $routes = @()
    foreach ($ingress in $ingressData.items) {
        $matchesClass = $false
        if ($ingress.spec.ingressClassName -eq $IngressClassName) { $matchesClass = $true }
        elseif (-not $ingress.spec.ingressClassName -and $IngressClassName -eq '(default)') { $matchesClass = $true }
        
        if (-not $matchesClass) { continue }
        
        foreach ($rule in $ingress.spec.rules) {
            $hostname = if ($rule.host) { $rule.host } else { '*' }
            if ($rule.http -and $rule.http.paths) {
                foreach ($path in $rule.http.paths) {
                    $routes += @{
                        IngressName = $ingress.metadata.name
                        Hostname = $hostname
                        Path = if ($path.path) { $path.path } else { '/' }
                        ServiceName = $path.backend.service.name
                        ServicePort = $path.backend.service.port.number
                    }
                }
            }
        }
    }
    return $routes
}

function Get-HTTPRoutes {
    param([string]$Namespace)
    
    $httpRouteData = Invoke-KubectlGet -Resource 'httproute' -Namespace $Namespace
    if (-not $httpRouteData -or -not $httpRouteData.items) { return @() }
    
    $routes = @()
    foreach ($httpRoute in $httpRouteData.items) {
        foreach ($rule in $httpRoute.spec.rules) {
            $hostnames = if ($httpRoute.spec.hostnames) { $httpRoute.spec.hostnames } else { @('*') }
            foreach ($hostname in $hostnames) {
                $path = '/'
                if ($rule.matches) {
                    foreach ($match in $rule.matches) {
                        if ($match.path -and $match.path.value) { $path = $match.path.value }
                    }
                }
                if ($rule.backendRefs) {
                    foreach ($backend in $rule.backendRefs) {
                        $routes += @{
                            HTTPRouteName = $httpRoute.metadata.name
                            Hostname = $hostname
                            Path = $path
                            ServiceName = $backend.name
                            ServicePort = $backend.port
                        }
                    }
                }
            }
        }
    }
    return $routes
}

function Compare-Routes {
    param([array]$IngressRoutes, [array]$HTTPRoutes)
    
    $matched = @()
    $unmatched = @()
    
    foreach ($ingressRoute in $IngressRoutes) {
        $found = $false
        foreach ($httpRoute in $HTTPRoutes) {
            if ($ingressRoute.Hostname -eq $httpRoute.Hostname -and
                $ingressRoute.Path -eq $httpRoute.Path -and
                $ingressRoute.ServiceName -eq $httpRoute.ServiceName) {
                $matched += $ingressRoute
                $found = $true
                break
            }
        }
        if (-not $found) { $unmatched += $ingressRoute }
    }
    
    return @{ Matched = $matched; Unmatched = $unmatched }
}

function New-CutoverChecklist {
    param([hashtable]$Comparison, [string]$FromClass, [string]$ToClass, [string]$Namespace, [bool]$IsDryRun)
    
    $checklist = "# Traffic Cutover Checklist`n`n"
    $checklist += "**Namespace:** $Namespace`n"
    $checklist += "**From:** $FromClass`n"
    $checklist += "**To:** $ToClass`n"
    $checklist += "**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
    $checklist += "**Mode:** $(if ($IsDryRun) { 'DRY RUN' } else { 'ACTIONABLE' })`n`n"
    
    $checklist += "## Summary`n`n"
    $checklist += "- **Matched routes:** $($Comparison.Matched.Count)`n"
    $checklist += "- **Unmatched routes:** $($Comparison.Unmatched.Count)`n`n"
    
    if ($Comparison.Unmatched.Count -gt 0) {
        $checklist += "## Unmatched Routes`n`n"
        foreach ($route in $Comparison.Unmatched) {
            $checklist += "- **$($route.IngressName):** $($route.Hostname)$($route.Path) -> $($route.ServiceName):$($route.ServicePort)`n"
        }
        $checklist += "`n**Action:** Translate these using Convert-IngressToGateway.`n`n"
    }
    
    if ($Comparison.Matched.Count -gt 0) {
        $checklist += "## Cutover Steps`n`n"
        $step = 1
        
        $checklist += "### Step ${step}: Verify HTTPRoute Resources`n`n"
        $checklist += "``````shell`n"
        $checklist += "kubectl get httproute -n $Namespace`n"
        $checklist += "```````n`n"
        $step++
        
        $checklist += "### Step ${step}: Verify Gateway is Ready`n`n"
        $checklist += "``````shell`n"
        $checklist += "kubectl get gateway -n $Namespace`n"
        $checklist += "kubectl describe gateway -n $Namespace`n"
        $checklist += "```````n`n"
        $step++
        
        $checklist += "### Step ${step}: Test New Routes`n`n"
        $uniqueHosts = $Comparison.Matched | Select-Object -ExpandProperty Hostname -Unique
        foreach ($hostname in $uniqueHosts) {
            $checklist += "``````shell`n"
            $checklist += "curl -H 'Host: $hostname' http://<GATEWAY_IP>/`n"
            $checklist += "```````n`n"
        }
        $step++
        
        $checklist += "### Step ${step}: Update DNS Records`n`n"
        foreach ($hostname in $uniqueHosts) {
            if ($hostname -ne '*') {
                $checklist += "- **$hostname** -> <GATEWAY_IP>`n"
            }
        }
        $checklist += "`n"
        $step++
        
        $checklist += "### Step ${step}: Monitor Traffic`n`n"
        $checklist += "Monitor for 15-30 minutes after DNS cutover.`n`n"
        $step++
        
        $checklist += "### Step ${step}: Decommission Old Ingress`n`n"
        $checklist += "Only after confirming traffic is stable.`n`n"
    }
    
    return $checklist
}

Write-Information "Analyzing namespace: $Namespace" -InformationAction Continue

$ingressRoutes = Get-IngressRoutes -Namespace $Namespace -IngressClassName $FromGatewayClassName
$httpRoutes = Get-HTTPRoutes -Namespace $Namespace
$comparison = Compare-Routes -IngressRoutes $ingressRoutes -HTTPRoutes $httpRoutes

$checklist = New-CutoverChecklist -Comparison $comparison -FromClass $FromGatewayClassName -ToClass $ToGatewayClassName -Namespace $Namespace -IsDryRun $DryRun

Write-Output $checklist
