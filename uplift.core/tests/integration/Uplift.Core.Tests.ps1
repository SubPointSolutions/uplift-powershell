

$dirPath    = $PSScriptRoot
$scriptPath = $MyInvocation.MyCommand.Name

$srcPath    =  Resolve-Path "$dirPath/../../src"
    
$skipSourceInclude = $True

Describe 'uplift.core.integration' {
    Context "Cdefault" {
        It 'can import module' {
            Import-Module Uplift.Core
        }
    }
}

. $srcPath/../tests/unit/Uplift.Core.Tests.ps1