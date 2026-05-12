BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot '..' 'Convert-IngressToGateway.ps1'
}

Describe 'Convert-IngressToGateway' {
    Context 'Structure validation' {
        It 'Should declare CmdletBinding with SupportsShouldProcess' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'CmdletBinding\(SupportsShouldProcess'
        }

        It 'Should have mandatory InputPath parameter' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'Parameter\(Mandatory'
            $content | Should -Match '\$InputPath'
        }

        It 'Should have mandatory OutputPath parameter' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match '\$OutputPath'
        }

        It 'Should default Provider to ingress-nginx' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match "Provider.*=.*'ingress-nginx'"
        }

        It 'Should have Force parameter' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match '\$Force'
        }
    }

    Context 'Binary detection' {
        It 'Should check for ingress2gateway' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'ingress2gateway'
        }

        It 'Should provide install instructions' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'go install'
        }
    }

    Context 'Translation workflow' -Tag 'integration' {
        BeforeAll {
            $script:HasBinary = $null -ne (Get-Command ingress2gateway -ErrorAction SilentlyContinue)
        }

        It 'Should translate sample Ingress' -Skip:(-not $script:HasBinary) {
            . $script:ScriptPath
            
            $inputPath = Join-Path $PSScriptRoot 'fixtures' 'sample-ingress.yaml'
            $outputPath = Join-Path $TestDrive 'output'
            
            Convert-IngressToGateway -InputPath $inputPath -OutputPath $outputPath -Force -InformationAction SilentlyContinue
            
            $outputFiles = Get-ChildItem $outputPath -Filter *.yaml
            $outputFiles.Count | Should -BeGreaterThan 0
            
            $content = Get-Content $outputFiles[0].FullName -Raw
            $content | Should -Match 'HTTPRoute'
        }
    }

    Context 'Comment-based help' {
        It 'Should have SYNOPSIS' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match '\.SYNOPSIS'
        }

        It 'Should have DESCRIPTION' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match '\.DESCRIPTION'
        }

        It 'Should have EXAMPLE' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match '\.EXAMPLE'
        }
    }
}
