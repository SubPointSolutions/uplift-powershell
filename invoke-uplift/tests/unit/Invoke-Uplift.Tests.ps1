

$dirPath    = $PSScriptRoot
$scriptPath = $MyInvocation.MyCommand.Name

$srcPath    =  Resolve-Path "$dirPath/../../src"

$localServerPort = 3005
$localServerPath = "$srcPath/resource-files-test"
    
$upliftPath = Resolve-Path "$srcPath/InvokeUplift.ps1"
. $upliftPath

function Get-TestRepositoryPath() {
    "build-uplift-local-repository"
}

function Get-Debug() {
    if($null -ne $ENV:debug) {
        return "-d"
    }

    return ""
}

function Start-LocalWebServer($port, $path) {
    $localServerPort = 3005
    $localServerPath = "$srcPath/resource-files-test"

    $localBuildRepositoryPath = "build-uplift-local-repository"

    Write-Host "Starting local http-server"
    Write-Host " -  path: $localServerPath"
    Write-Host " -  port: $localServerPort"

    $job = http-server $localServerPath `
        -p $localServerPort `
        &

    if($null -eq $job) {
        throw "Cannot start http-server locally"
    } else {
        Write-Host "Started http-server, job: $job"
    }

     # pause to start up the http-server
    Write-Host "Pause 5 sec allowing http-server to start..."
    Start-Sleep 5

    $url = "http://localhost:$port"
    Write-Host "Checking url: $url"
    
    $result = Invoke-WebRequest "$url" `
        -UseBasicParsing `
        -DisableKeepAlive `
        -Method HEAD 

    if($result.StatusCode -eq 200) {
        Write-Host  "[+] StatusCode: $($result.StatusCode) for url: $url"
    } else {
        throw "[!] StatusCode: $($result.StatusCode), expected 200!"
    }
}

Start-LocalWebServer $localServerPort $localServerPath 


Describe 'invoke-uplift' {

    Context "default" {
        It 'Can execute' {
            Invoke-TheUplifter42 `
                | Should Be 0
        }
    }

    Context "version" {
        It 'Can execute: version' {
            Invoke-TheUplifter42 @(
                "version"
            ) | Should Be 0
        } 
    }

    Context "help" {
        It 'Can execute: help' {
            Invoke-TheUplifter42 @(
                "help"
            ) | Should Be 0
        }
    }

    Context "resource" { 
        It 'no arg: returns 0, shows help' {
            Invoke-TheUplifter42 @(
                "resource"
            ) | Should Be 0
        }

        It 'help: returns 0, shows help' {
            Invoke-TheUplifter42 @(
                "resource",
                "help"
            ) | Should Be 0
        }
    }
    
    Context "resource list" { 
    
        It 'can list' {
            Invoke-TheUplifter42 @(
                "resource",
                "list"
            ) | Should Be 0
        }

        It 'can list details' {
            Invoke-TheUplifter42 @(
                "resource",
                "list",
                "details"
            ) | Should Be 0
        }
    }

    Context "resource download" { 
        It 'fails on non-existing resource' {
            Invoke-TheUplifter42 @(
                "resource",
                "download",
                "non-existing-stuff",
                (Get-Debug),
                "-repository",
                (Get-TestRepositoryPath)
            ) | Should Not Be 0
        }

        It 'downloads uplf-local-file1' {
            Invoke-TheUplifter42 @(
                "resource",
                "download",
                "uplf-local-file1",
                (Get-Debug),
                "-repository",
                (Get-TestRepositoryPath)
            ) | Should Be 0
        }

        It 'downloads force uplf-local-file1' {
            Invoke-TheUplifter42 @(
                "resource",
                "download",
                "uplf-local-file1",
                (Get-Debug),
                "-force",
                "-repository",
                (Get-TestRepositoryPath)
            ) | Should Be 0
        }

        It 'downloads uplf-local-*' {
            Invoke-TheUplifter42 @(
                "resource",
                "download",
                "uplf-local-*",
                (Get-Debug),
                "-repository",
                (Get-TestRepositoryPath)
            ) | Should Be 0
        }

        It 'downloads force uplf-local-*' {
            Invoke-TheUplifter42 @(
                "resource",
                "download",
                "uplf-local-*",
                (Get-Debug),
                "-f",
                "-repository",
                (Get-TestRepositoryPath)
            ) | Should Be 0
        }
    }

    Context "resource validate-uri" {  
        It 'validates local uri' {
            Invoke-TheUplifter42 @(
                "resource",
                "validate-uri",
                "uplf-local-*"
                (Get-Debug)
            ) | Should Be 0
        }

        It 'validates all uri' {
            Invoke-TheUplifter42 @(
                "resource",
                "validate-uri",
                (Get-Debug)
            ) | Should Be 0
        }
    }

}