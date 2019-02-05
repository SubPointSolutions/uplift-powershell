

$dirPath    = $PSScriptRoot
$scriptPath = $MyInvocation.MyCommand.Name

$srcPath    =  Resolve-Path "$dirPath/../../src"
    
$skipSourceInclude = $True

Write-Host "PSHome: $PSHome"
Write-Host "Is64BitProcess: $([Environment]::Is64BitProcess)"

Write-Host "Listing installed modules:"
Get-InstalledModule

Write-Host "Importing module: Uplift.Core"
Import-Module Uplift.Core 

. $srcPath/../tests/unit/Uplift.Core.Tests.ps1