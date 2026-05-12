BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot '..' 'Invoke-TrafficCutover.ps1'
}

Describe 'Invoke-TrafficCutover' {
    Context 'Structure validation' {
        It 'Should declare CmdletBinding with SupportsShouldProcess' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'CmdletBinding\(SupportsShouldProcess'
        }

        It 'Should have mandatory FromGatewayClassName' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'Parameter\(Mandatory'
            $content | Should -Match '\$FromGatewayClassName'
        }

        It 'Should have mandatory Namespace' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match '\$Namespace'
        }

        It 'Should default ToGatewayClassName' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match "ToGatewayClassName.*=.*'azure-application-load-balancer'"
        }

        It 'Should default DryRun to true' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match '\$DryRun\s*=\s*\$true'
        }
    }

    Context 'Read-only enforcement' {
        It 'Should only use kubectl get' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'kubectl.*get'
        }

        It 'Should not contain kubectl apply' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Not -Match 'kubectl.*apply'
        }

        It 'Should not contain kubectl patch' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Not -Match 'kubectl.*patch'
        }

        It 'Should not execute kubectl delete' {
            $content = Get-Content $script:ScriptPath -Raw
            # Filter out references in checklist strings
            $executable = $content -split "`n" | Where-Object { $_ -notmatch '^\s*\$checklist' }
            $executable -join "`n" | Should -Not -Match 'kubectl\s+delete'
        }
    }

    Context 'Functions' {
        It 'Should define Get-IngressRoutes' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'function Get-IngressRoutes'
        }

        It 'Should define Get-HTTPRoutes' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'function Get-HTTPRoutes'
        }

        It 'Should define Compare-Routes' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'function Compare-Routes'
        }

        It 'Should define New-CutoverChecklist' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'function New-CutoverChecklist'
        }
    }

    Context 'Checklist generation' {
        It 'Should generate Traffic Cutover Checklist' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'Traffic Cutover Checklist'
        }

        It 'Should include Summary section' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match '## Summary'
        }

        It 'Should include Cutover Steps' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'Cutover Steps'
        }

        It 'Should include step numbering' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'Step'
        }
    }

    Context 'Human-driven philosophy' {
        It 'Should mention DRY RUN mode' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'DRY RUN'
        }

        It 'Should mention ACTIONABLE mode' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'ACTIONABLE'
        }

        It 'Should include DNS guidance' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'DNS'
        }

        It 'Should include monitoring guidance' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'Monitor'
        }
    }
}
