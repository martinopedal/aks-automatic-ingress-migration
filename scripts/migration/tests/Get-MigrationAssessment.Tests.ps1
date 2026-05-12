BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot '..' 'Get-MigrationAssessment.ps1'
}

Describe 'Get-MigrationAssessment' {
    Context 'Structure validation' {
        It 'Should have CmdletBinding' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match '\[CmdletBinding\(\)\]'
        }

        It 'Should have KubeContext parameter' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match '\$KubeContext'
        }

        It 'Should have OutputFormat parameter with ValidateSet' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'ValidateSet.*json.*markdown'
        }

        It 'Should default OutputFormat to markdown' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match "OutputFormat.*=.*'markdown'"
        }

        It 'Should not have SupportsShouldProcess' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Not -Match 'SupportsShouldProcess'
        }
    }

    Context 'Read-only operations' {
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

        It 'Should not contain kubectl delete' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Not -Match 'kubectl.*delete'
        }
    }

    Context 'Functions' {
        It 'Should define Get-IngressInventory' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'function Get-IngressInventory'
        }

        It 'Should define Get-AppRoutingStatus' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'function Get-AppRoutingStatus'
        }

        It 'Should define Get-GatewayApiStatus' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'function Get-GatewayApiStatus'
        }

        It 'Should define Format-AssessmentAsMarkdown' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'function Format-AssessmentAsMarkdown'
        }
    }

    Context 'Error handling' {
        It 'Should use IgnoreNotFound for optional resources' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'IgnoreNotFound'
        }

        It 'Should set ErrorActionPreference to Stop' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match "ErrorActionPreference.*=.*'Stop'"
        }
    }

    Context 'Output formats' {
        It 'Should handle JSON output' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'ConvertTo-Json'
        }

        It 'Should handle Markdown output' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'Format-AssessmentAsMarkdown'
        }
    }
}
