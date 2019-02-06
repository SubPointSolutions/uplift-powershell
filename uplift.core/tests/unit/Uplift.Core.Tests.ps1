

$dirPath    = $PSScriptRoot
$scriptPath = $MyInvocation.MyCommand.Name

$srcPath    =  Resolve-Path "$dirPath/../../src"

if($skipSourceInclude -ne $True) {
    . "$srcPath/Uplift.Core.ps1"
}

Describe 'uplift.core' {

    Context "Write-UpliftMessage" {
        It 'should exist' {
            Get-Command "Write-UpliftMessage" `
                | Should Not Be $null
        }
    }

    Context "Write-UpliftInfoMessage" {
        It 'should exist' {
            Get-Command "Write-UpliftInfoMessage" `
                | Should Not Be $null
        }
    }

    Context "Write-UpliftVerboseMessage" {
        It 'should exist' {
            Get-Command "Write-UpliftVerboseMessage" `
                | Should Not Be $null
        }
    }

    Context "Confirm-UpliftExitCode" {
        It 'should exist' {
            Get-Command "Confirm-UpliftExitCode" `
                | Should Not Be $null
        }
    }

    Context "New-UpliftFolder" {
        It 'should exist' {
            Get-Command "New-UpliftFolder" `
                | Should Not Be $null
        }
    }

    Context "New-UpliftFolder" {
        It 'should exist' {
            Get-Command "New-UpliftFolder" `
                | Should Not Be $null
        }
    }

    Context "New-UpliftDSCConfigurationData" {
        It 'should exist' {
            Get-Command "New-UpliftDSCConfigurationData" `
                | Should Not Be $null
        }
    }

    Context "Start-UpliftDSCConfiguration" {
        It 'should exist' {
            Get-Command "Start-UpliftDSCConfiguration" `
                | Should Not Be $null
        }
    }

    Context "Write-UpliftVariableValue" {
        It 'should exist' {
            Get-Command "Write-UpliftVariableValue" `
                | Should Not Be $null
        }
    }

    Context "Write-UpliftEnv" {
        It 'should exist' {
            Get-Command "Write-UpliftEnv" `
                | Should Not Be $null
        }
    }

    Context "Test-UpliftSecretVariableName" {
        It 'should exist' {
            Get-Command "Test-UpliftSecretVariableName" `
                | Should Not Be $null
        }
    }

    Context "Get-UpliftEnvVariable" {
        It 'should exist' {
            Get-Command "Get-UpliftEnvVariable" `
                | Should Not Be $null
        }
    }

    Context "Install-UpliftInstallPackage" {
        It 'should exist' {
            Get-Command "Install-UpliftInstallPackage" `
                | Should Not Be $null
        }
    }

    Context "Wait-UpliftProcess" {
        It 'should exist' {
            Get-Command "Wait-UpliftProcess" `
                | Should Not Be $null
        }
    }

    Context "Invoke-UpliftIISReset" {
        It 'should exist' {
            Get-Command "Invoke-UpliftIISReset" `
                | Should Not Be $null
        }
    }

    Context "Invoke-UpliftIISPoolStart" {
        It 'should exist' {
            Get-Command "Invoke-UpliftIISPoolStart" `
                | Should Not Be $null
        }
    }

    Context "Find-UpliftFileInPath" {
        It 'should exist' {
            Get-Command "Find-UpliftFileInPath" `
                | Should Not Be $null
        }
    }

    Context "Install-UpliftPSModules" {
        It 'should exist' {
            Get-Command "Install-UpliftPSModules" `
                | Should Not Be $null
        }
    }

    Context "New-UpliftPSRepository" {
        It 'should exist' {
            Get-Command "New-UpliftPSRepository" `
                | Should Not Be $null
        }
    }

    Context "Set-UpliftDCPromoSettings" {
        It 'should exist' {
            Get-Command "Set-UpliftDCPromoSettings" `
                | Should Not Be $null
        }
    }

    Context "Disable-UpliftIP6Interface" {
        It 'should exist' {
            Get-Command "Disable-UpliftIP6Interface" `
                | Should Not Be $null
        }
    }

    Context "Repair-UpliftIISApplicationHostFile" {
        It 'should exist' {
            Get-Command "Repair-UpliftIISApplicationHostFile" `
                | Should Not Be $null
        }
    }

    Context "Install-UpliftPSModule" {
        It 'should exist' {
            Get-Command "Install-UpliftPSModule" `
                | Should Not Be $null
        }
    }

    Context "Install-UpliftPS6Module" {
        It 'should exist' {
            Get-Command "Install-UpliftPS6Module" `
                | Should Not Be $null
        }
    }

    Context "New-UpliftTrackEvent" {
        It 'should exist' {
            Get-Command "New-UpliftTrackEvent" `
                | Should Not Be $null
        }
    }

    Context "New-UpliftTrackException" {
        It 'should exist' {
            Get-Command "New-UpliftTrackException" `
                | Should Not Be $null
        }
    }

    Context "New-UpliftAppInsighsProperties" {
        It 'should exist' {
            Get-Command "New-UpliftAppInsighsProperties" `
                | Should Not Be $null
        }
    }

}