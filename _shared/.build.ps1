

$moduleFolder           = "$dirPath/build-module"
$moduleRepositoryFolder = "$dirPath/build-repository"

$devRepositoryName = ("uplift-powershell-dev-$moduleName").ToLower()

$srcFolder  = "$dirPath/src"

# MacOS builds might fail with the following issue: 
# Did you mean to run dotnet SDK commands? Please install dotnet SDK from:
# http://go.microsoft.com/fwlink/?LinkID=798306&clcid=0x409

# Solution is to literally install SDK from this url:
# http://go.microsoft.com/fwlink/?LinkID=798306&clcid=0x409

# brew seems to come with an older version or incomple setup
# so that not all dotnet things are seen by the env/shell


function Confirm-PSModule($name, $version) {
    $module = Get-InstalledModule $name -ErrorAction SilentlyContinue

    if ($null -eq  $module) {
        
        Write-Build Green "installing module: $name, version: $version"

        if([string]::IsNullOrEmpty($version) -eq $False) {
            Install-Module -Name $name -Force -RequiredVersion $version
        } else {
            Module -Name $name -Force
        }
    }
    else {
        Write-Build Green "module installed: $name"
    }
} 

Enter-Build {
    Write-Build Green "Preparing env..."
    
    Confirm-PSModule "PSScriptAnalyzer" "1.17.1"
    Confirm-PSModule "Pester" "4.7.1"
}

# Synopsis: Cleans current build directories
task Clean {
    Write-Build Green " [~] Cleaning build folders..."

    remove $moduleFolder 
    remove $moduleRepositoryFolder
}

# Synopsis: Executes unit tests
task UnitTest {
    Write-Build Green " [~] Unit testing..."
    
    exec {
        if($null -ne $script:PS6 ) {
            Write-Build Green " [~] Using PS6"

            pwsh -c Write-Host $PSVersionTable.PSVersion
            pwsh -c 'Invoke-Pester ./tests/unit* -EnableExit'
        } else {
            Write-Build Green " [~] Using PowerShell"

            powershell -c Write-Host $PSVersionTable.PSVersion
            powershell -c 'Invoke-Pester ./tests/unit* -EnableExit'
        }
    }
}

# Synopsis: Executes regression tests with Test Kitchen
task IntegrationTest {
    
    Write-Build Green " [~] Integration testing..."
    
    exec {
        if($null -ne $script:PS6 ) {
            Write-Build Green " [~] Using PS6"
            pwsh -c 'Invoke-Pester ./tests/integration* -EnableExit'
        } else {
            Write-Build Green " [~] Using PowerShell"
            powershell -c 'Invoke-Pester ./tests/integration* -EnableExit'
        }
    }
}

# Synopsis: Prepares module files to be build and packed
task PrepareModule {
    Write-Build Green " [~] Crafting module folder"

    New-Item "$moduleFolder/$moduleName" -ItemType directory -Force | Out-Null
    
    Copy-Item "$srcFolder/$moduleName.ps*" "$moduleFolder/$moduleName/" 
    Copy-Item "$srcFolder/*-*.ps*" "$moduleFolder/$moduleName/" 
    Copy-Item "$srcFolder/*-*-*.ps*" "$moduleFolder/$moduleName/" 
}

# Synopsis: Versions package with giving or timestamped value
task VersionModule {
    $dateStamp = [System.DateTime]::UtcNow.ToString("yyyyMMdd")
    $timeStamp = [System.DateTime]::UtcNow.ToString("HHmmss")

    $stamp = "$dateStamp.$timeStamp"

    # repace 0 for 24 hours
    # v0.1.20190107.092517 will be v0.1.20190107.92517 in Version object 
    # (.092517) -> .92517
    # that prevents further testing and comparation
    $stamp = $stamp.Replace(".000", ".")
    $stamp = $stamp.Replace(".00", ".")
    $stamp = $stamp.Replace(".0", ".")

    # PowerShell does not allow string value in the Version
    # It seems to map to .NET Version object, so no -alpha/-beta tags
    # $script:Version = "0.1.0-alpha$stamp" 
    
    $script:Version = "0.1.$stamp"

    if($null -ne $env:APPVEYOR_REPO_BRANCH) {
        Write-Build Green " [~] Running under APPVEYOR branch: $($env:APPVEYOR_REPO_BRANCH)"

        if($env:APPVEYOR_REPO_BRANCH -ine "master") {
            Write-Build Green " skipping APPVEYOR versioning for branch: $($env:APPVEYOR_REPO_BRANCH)"
        } else {
            Write-Build Green " using APPVEYOR versioning for branch: $($env:APPVEYOR_REPO_BRANCH)"

            ## 1902.build-no
            $stamp = [System.DateTime]::UtcNow.ToString("yyMM")
            $buildNumber = $env:APPVEYOR_BUILD_NUMBER;

            $script:Version = "0.2.$stamp.$buildNumber"
        }
    } 

    if($null -ne $buildVersion ) {
        Write-Build Yello " [+] Using version from params: $buildVersion"
        $script:Version = $buildVersion
    }

    $specFile = "$moduleFolder/$moduleName/$moduleName.psd1" 
    $psFile    = "$moduleFolder/$moduleName/$moduleName.ps1" 

    Write-Build Green " [~] Patching version: $($script:Version)"
    
    Write-Build Green " - file: $specFile"
    Edit-ValueInFile $specFile '0.1.0' $script:Version

    Write-Build Green " - file: $specFile"
    Edit-ValueInFile $psFile '0.1.0' $script:Version
}

# Synopsis: Builds a PowerShell module
task BuildModule {

    Write-Build Green "[~] ensuring repository folder: $moduleRepositoryFolder"
    New-Item $moduleRepositoryFolder -ItemType directory -Force | Out-Null
    
    Write-Build Green "[~] ensuring repository: $devRepositoryName"
    New-UpliftPSRepository $devRepositoryName `
        $moduleRepositoryFolder `
        $moduleRepositoryFolder 
    
    Write-Build Green "[~] publishing module: $moduleName"
    Write-Build Green " - path: $moduleFolder/$moduleName"

    Publish-Module -Path "$moduleFolder/$moduleName" `
        -Repository $devRepositoryName 
    
    Write-Build Green "[~] Find-Module: $moduleName in repo: $devRepositoryName"   
    $module = Find-Module -Name $moduleName `
                -Repository $devRepositoryName

    if($null -eq $module) {
        throw "Cannot Find-Module: $moduleName in repo: $devRepositoryName" 
    }
}

# Synopsis: Installes a PowerShell module
task InstallModule {
   
    Write-Build Green "[~] ensuring repository: $devRepositoryName"
    New-UpliftPSRepository $devRepositoryName `
        $moduleRepositoryFolder `
        $moduleRepositoryFolder 

    Write-Build Green " [+] Fetching repo: $devRepositoryName"
    Get-PSRepository $devRepositoryName

    Write-Build Green " [~] Find-Module -Name $moduleName"
    Find-Module  -Name $moduleName -Repository $devRepositoryName 

    Write-Build Green " [~] Install-Module -Name $moduleName -Repository $devRepositoryName -Force"
    Install-Module -Name $moduleName -Repository $devRepositoryName -Force

    Write-Build Green " [~] Get-InstalledModule -Name $moduleName"
    $installeModule = Get-InstalledModule $moduleName

    if($null -eq $installeModule) {
        throw "Cannot find installed module: $moduleName"
    } else {
        Write-Build Green "[+] found installed module" 
        $installeModule
    }
}

# Synopsis: Validates installed module
task ValidateInstalledModule {

    $installeModule  = Get-InstalledModule $moduleName
    $expectedVersion = $script:Version
   
    $hasCorrectversionInstalled = $installeModule.Version.ToString().Contains($expectedVersion)
   
    if( $hasCorrectversionInstalled  -eq $True)  {
        Write-Build Green " [+] found expected version: $expectedVersion"
    } else {
        Write-Build Red    " [!] Cannot find expected version: $expectedVersion"
        Write-Build Yellow "  - installed: $($installeModule.Version)"
        Write-Build Yellow "  - expected : $expectedVersion"

        throw "Version mismatch while installing new module"
    }
}

# Synopsis: Publishes module to the giving repository
task PublishModule {
    
    if($null -ne $env:APPVEYOR_REPO_BRANCH) {
        Write-Build Green " [~] Running under APPVEYOR branch: $($env:APPVEYOR_REPO_BRANCH)"

        if($env:APPVEYOR_REPO_BRANCH -ine "dev" -and $env:APPVEYOR_REPO_BRANCH -ine "beta" -and $env:APPVEYOR_REPO_BRANCH -ine "master") {
            Write-Build Green " skipping publishing for branch: $($env:APPVEYOR_REPO_BRANCH)"
            return;
        }

        $repoNameEnvName = ("SPS_REPO_NAME_" + $env:APPVEYOR_REPO_BRANCH)
        $repoSrcEnvName  = ("SPS_REPO_SRC_"  + $env:APPVEYOR_REPO_BRANCH)
        $repoPushEnvName = ("SPS_REPO_PUSH_" + $env:APPVEYOR_REPO_BRANCH)
        $repoKeyEnvName  = ("SPS_REPO_KEY_"  + $env:APPVEYOR_REPO_BRANCH)

        $publishRepoName             = (get-item env:$repoNameEnvName).Value;

        $publishRepoSourceLocation   = (get-item env:$repoSrcEnvName).Value;
        $publishRepoPublishLocation  = (get-item env:$repoPushEnvName).Value;

        $publishRepoNuGetApiKey      = (get-item env:$repoKeyEnvName).Value;
    }

    Confirm-Variable "publishRepoName" $publishRepoName "publishRepoName" 
    
    Confirm-Variable "publishRepoSourceLocation" $publishRepoSourceLocation  "publishRepoSourceLocation"
    Confirm-Variable "publishRepoPublishLocation" $publishRepoPublishLocation "publishRepoPublishLocation"
    
    Confirm-Variable "publishRepoNuGetApiKey" $publishRepoNuGetApiKey "publishRepoNuGetApiKey" 
    
    Write-Build Green "[~] ensuring repository: $publishRepoName"
    New-UpliftPSRepository $publishRepoName `
        $publishRepoSourceLocation `
        $publishRepoPublishLocation 

    Write-Build Green " [~] Fetching latest module..."

    $installedModules = Get-InstalledModule $moduleName
    $latestModule     = $installedModules `
                        | Sort-Object -Property Version `
                        | Select-Object -First 1

    Write-Build Green "Latest module: $($latestModule.Version)"
    
    Write-Build Green "Publishing module: $($latestModule.Version)"
    
    $result = Publish-Module -Name $moduleName `
        -RequiredVersion $latestModule.Version `
        -Repository  $publishRepoName `
        -NuGetApiKey $publishRepoNuGetApiKey

    Write-Build Green "Result: $result"
    Write-Build Green "Completed!"
}

# Synopsis: Executes Appveyor specific setup
task AppveyorPrepare {
    # avoid npm warning whic fails Appveyor build
    # npm WARN deprecated ecstatic@3.3.1: https://github.com/jfhbrook/node-ecstatic/issues/259
    npm install http-server -g --loglevel=error
}

# Synopsis: Runs PSScriptAnalyzer 
task AnalyzeModule {
    exec {
        # https://github.com/PowerShell/PSScriptAnalyzer
        
        if($null -eq $QA_FIX) {
            pwsh -c Invoke-ScriptAnalyzer -Path $srcFolder -EnableExit -ReportSummary
            Confirm-ExitCode $LASTEXITCODE "[~] failed!"
        } else {
            pwsh -c Invoke-ScriptAnalyzer -Path $srcFolder -EnableExit -ReportSummary -Fix
        }
    }
}

# Synopsis: Default module build
task DefaultBuild UnitTest, 
        Clean, 
        PrepareModule, 
        VersionModule,
        BuildModule, 
        InstallModule,
        ValidateInstalledModule

# Synopsis: Default module build task with no parameters
task . DefaultBuild

# Synopsis: Default module build + QA
task QA AnalyzeModule, DefaultBuild, IntegrationTest

# Synopsis: Default module publishing task
task ReleaseModule AnalyzeModule, DefaultBuild, IntegrationTest, PublishModule

task Appveyor AppveyorPrepare, 
    ReleaseModule