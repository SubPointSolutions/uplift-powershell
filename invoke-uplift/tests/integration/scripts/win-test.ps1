$ErrorActionPreference = "Continue"

try {
    Write-Host "Testing windows"

    function Exec-PwshCmd($cmd) {
        Write-Host "running cmd: $cmd"

        pwsh -c $cmd
        Confirm-ExitCode $LASTEXITCODE "Non-zero exit code: $cmd"
    }

    function Invoke-BaseTests()
    {
        Exec-PwshCmd "invoke-uplift"
        Exec-PwshCmd "invoke-uplift version"
        
        Exec-PwshCmd "invoke-uplift resource"
        Exec-PwshCmd "invoke-uplift resource list"
        
        Exec-PwshCmd "invoke-uplift resource validate-uri"
        
        Exec-PwshCmd "invoke-uplift resource download 7z-1805-x64"
        Exec-PwshCmd "invoke-uplift resource download 7z-1805-x64"
        
        Exec-PwshCmd "invoke-uplift resource download 7z-1805- -f -d"
        
        Exec-PwshCmd "invoke-uplift resource download 7z-1805- -f -d -lf short"
        Exec-PwshCmd "invoke-uplift resource download 7z-1805- -f -d -lf time"
        Exec-PwshCmd "invoke-uplift resource download 7z-1805- -f -d -lf full"
    }

    function New-UpliftPSRepository {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]

        param(
            $name,
            $source, 
            $publish = $null, 
            $installPolicy = "Trusted"
        )

        Write-Host "Fetching repo..."
        $repo = Get-PSRepository `
            -Name $name `
            -ErrorAction SilentlyContinue

        if($null -eq $repo) {
            Write-Host " [~] Regestering repo: $name"
            Write-Host " - path: $source"

            if($null -eq $publish) {
                Register-PSRepository -Name $name `
                    -SourceLocation $source `
                    -InstallationPolicy $installPolicy 
            } else {
                Register-PSRepository -Name $name `
                    -SourceLocation $source `
                    -PublishLocation $publish `
                    -InstallationPolicy $installPolicy 
            }
        } else {
            Write-Host "Repo exists: $name"
        }
    }

    function Confirm-ExitCode($code, $message)
    {
        if ($code -eq 0) {
            Write-Host "Exit code is 0, continue..."
        } else {
            $errorMessage = "Exiting with non-zero code [$code] - $message" 

            Write-Host  $errorMessage 
            throw  $errorMessage 
        }
    }

    Write-Host "Installing choco"
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

    Write-Host "Installing pwsh"
    choco install -y pwsh --limit-output --acceptlicense --no-progress

    Write-Host "Refreshing chico env"
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1" -Force; 
    Update-SessionEnvironment -Full

    try {
        Write-Host "Registering repo..."
        
        New-UpliftPSRepository 'subpointsolutions-staging'  `
            'https://www.myget.org/F/subpointsolutions-staging/api/v2' `
            'https://www.myget.org/F/subpointsolutions-staging/api/v2/package'

    } catch {
        Write-Host "ERR!"
        Write-Host $_

        exit 1
    } 

    Write-Host "Showing pwsh version"
    pwsh --version

    Write-Host "Installing module..."
    pwsh -c "Install-Package InvokeUplift -Source subpointsolutions-staging -Force"
    Confirm-ExitCode $LASTEXITCODE "Cannot install InvokeUplift"

    Write-Host "Running base tests..."
    Invoke-BaseTests

    Write-Host "Installing curl"
    choco install -y curl --limit-output --acceptlicense --no-progress
    
    Write-Host "Running base tests..."
    Invoke-BaseTests

    Write-Host "Installing wget"
    choco install -y wget --limit-output --acceptlicense --no-progress

    Write-Host "Running base tests..."
    Invoke-BaseTests
}
catch {
    Write-Host "ERR!"
    Write-Host $_

    exit 1
}

exit 0