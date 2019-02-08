
$ErrorActionPreference = "Stop"

# appinsight helpers
$hereFolder = $PSScriptRoot

. "$hereFolder/Uplift.AppInsights.ps1"

function Write-UpliftMessage {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]

    param(
        $message,
        $level = "INFO"
    )

    $stamp = $(get-date -f "MM-dd-yyyy HH:mm:ss.fff")

    $messageColor = "White"

    if($level -eq "INFO")    { $messageColor = "Green" }
    if($level -eq "VERBOSE") { $messageColor = "Blue" }
    if($level -eq "DEBUG")   { $messageColor = "DarkGray" }
    if($level -eq "ERROR")   { $messageColor = "Red" }
    if($level -eq "WARN")    { $messageColor = "Yellow" }

    if($ENV:UPLF_LOG_LEVEL -ne "DEBUG") {
        if($level -eq "DEBUG" -or  $level -eq "VERBOSE") {
            return;
        }
    }

    $level = $level.PadRight(7)

    # use [environment]::UserDomainName / [environment]::UserName
    # $env:USERDOMAIN won't work on non-windows platforms
    $logMessage = "UPLIFT : $stamp : $level : $([environment]::UserDomainName)/$([environment]::UserName) : $message"

    Write-Host $logMessage `
        -ForegroundColor $messageColor
}

function Write-UpliftInfoMessage($message) {
    Write-UpliftMessage "$message" "INFO"
}

function Write-UpliftDebugMessage($message) {
    Write-UpliftMessage "$message" "DEBUG"
}

function Write-UpliftVerboseMessage($message) {
    Write-UpliftMessage "$message" "VERBOSE"
}

function Write-UpliftErrorMessage($message) {
    Write-UpliftMessage "$message" "ERROR"
}

function Write-UpliftWarnMessage($message) {
    Write-UpliftMessage "$message" "WARN"
}

function Confirm-UpliftExitCode {
    Param(
        [Parameter(Mandatory=$True)]
        $code,

        [Parameter(Mandatory=$True)]
        $message,

        [Parameter(Mandatory=$False)]
        $allowedCodes = @( 0 )
    )

    $valid = $false

    Write-UpliftMessage "Checking exit code: $code with allowed values: $allowedCodes"

    foreach ($allowedCode in $allowedCodes) {
        if($code -eq $allowedCode) {
            $valid = $true
            break
        }
    }

    if( $valid -eq $false) {
        $error_message =  "[!] $message - exit code is: $code but allowed values were: $allowedCodes"

        Write-UpliftMessage $error_message
        throw $error_message
    } else {
        Write-UpliftMessage "[+] exit code is: $code within allowed values: $allowedCodes"
    }
}

function New-UpliftFolder {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]

    param(
        $path
    )

    New-Item -ItemType Directory -Force -Path $path | out-null
}

function New-UpliftDSCConfigurationData {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]

    param(

    )

    return @{
        AllNodes = @(
            @{
                NodeName = 'localhost'
                PSDscAllowPlainTextPassword = $true

                RetryCount = 10
                RetryIntervalSec = 30
            }
        )
    }
}

function Get-UpliftDscConfigurationStatus() {
    $status = Get-DscConfigurationStatus


    Write-UpliftInfoMessage "ResourcesInDesiredState"
    foreach($resource in $status.ResourcesInDesiredState) {
        Write-UpliftInfoMessage "[+] $($resource.ResourceId)"
    }

    Write-UpliftInfoMessage ""

    Write-UpliftInfoMessage "ResourcesNotInDesiredState"
    foreach($resource in $status.ResourcesNotInDesiredState) {
        Write-UpliftInfoMessage "[!] $($resource.ResourceId)"
        Write-UpliftInfoMessage $resource.Error
    }
}

function Start-UpliftDSCConfiguration {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]

    Param(
        [Parameter(Mandatory=$True)]
        [System.Management.Automation.ConfigurationInfo]
        $Name,

        [Parameter(Mandatory=$False)]
        $Config = $null,

        [Parameter(Mandatory=$False)]
        $ExpectInDesiredState = $null
    )

    $skipDscCheck = $false

    if($null -eq $Config) {
        $Config = New-UpliftDSCConfigurationData
    }

    # should check?
    if( ( $null -ne $ENV:UPLF_DSC_CHECK ) -and ($null -eq $ExpectInDesiredState) ) {
        $ExpectInDesiredState = $true
    }

    if($null -ne  $ENV:UPLF_DSC_CHECK_SKIP ) {
        $skipDscCheck = $true
    }

    $dscFolder       = Get-UpliftEnvVariable 'UPLF_DSC_CONFIG_PATH' 'default value' 'C:/_uplift_dsc'
    $dscConfigFolder = [System.IO.Path]::Combine($dscFolder, $Name)

    Write-UpliftMessage "[~] ensuring folder: $dscFolder for config: $Name"
    New-UpliftFolder $dscFolder

    if(Test-Path $dscConfigFolder) {
        Write-UpliftMessage "[~] clearing previous configuration: $dscConfigFolder"
        Remove-Item $dscConfigFolder -Recurse -Force
    } else {
        Write-UpliftMessage "[~] previous configuration dose not exist: $dscConfigFolder"
    }

    Write-UpliftMessage "Compiling new configuration: $Name"
    & $Name -ConfigurationData $Config -OutputPath $dscConfigFolder | Out-Null

    Write-UpliftMessage "Starting configuration: $Name"

    $result = $null
    $inDesiredState = $null
    $elapsedMilliseconds = $null

    $dscStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $dscException = $null

    $dscConfigId  = (New-Guid).ToString()

    try {

        if($null -ne $ENV:UPLF_DSC_VERBOSE) {
            Start-DscConfiguration -Path $dscConfigFolder -Force -Wait -Verbose
        } else {
            Start-DscConfiguration -Path $dscConfigFolder -Force -Wait
        }

        $dscStopwatch.Stop()
        $elapsedMilliseconds = $dscStopwatch.ElapsedMilliseconds

        Write-UpliftMessage "Completed in: $elapsedMilliseconds"

        if($skipDscCheck -eq $false) {

            Write-UpliftMessage "Testing configuration: $Name"
            $result = Test-DscConfiguration -Path $dscConfigFolder

            $inDesiredState = $result.InDesiredState

            if($ExpectInDesiredState -eq $true) {
                Write-UpliftMessage "Expecting DSC [$Name] in a desired state"

                if($result.InDesiredState -ne $true) {
                    $message = "[~] DSC: $Name - is NOT in a desired state: $result"
                    Write-UpliftMessage $message

                    if ($null -ne $result.ResourcesNotInDesiredState) {
                        foreach($resource in $result.ResourcesNotInDesiredState) {
                            Write-UpliftMessage $resource
                        }
                    }

                    Get-UpliftDscConfigurationStatus

                    throw $message
                } else {
                    $message = "[+] DSC: $Name is in a desired state"
                    Write-UpliftMessage $message

                    Get-UpliftDscConfigurationStatus
                }
            } else {
                Write-UpliftMessage "[+] No check for DSC [$Name] is done. Skipping."
            }
        } else {
            Write-UpliftMessage "[+] Skipping testing configuration: $Name"
        }
    } catch {
        Write-UpliftErrorMessage $_
        $dscException = $_
    } finally {

        if($dscStopwatch.IsRunning -eq $true) {
            $dscStopwatch.Stop()
            $elapsedMilliseconds = $dscStopwatch.ElapsedMilliseconds
        }

        try {
            Confirm-UpliftUpliftAppInsightClient

            $success = $false

            if($ExpectInDesiredState -eq $True) {
                $success = ($inDesiredState -eq $True)
            } else {
                $success = ($null -eq $dscException)
            }

            $eventProps = New-UpliftAppInsighsProperties @{
                "dsc_name"    = $Name.Name
                "dsc_expect"  = $ExpectInDesiredState
                "dsc_state"   = $inDesiredState
                "dsc_elapsed" = $elapsedMilliseconds
                "dsc_success" = $success
                "dsc_config_id" = $dscConfigId
            }

            if($null -ne $dscException) {
                $eventProps.Add("dsc_error", $dscException.ToString())
            }

            New-UpliftTrackEvent "uplift-core.dsc" $eventProps

            if($null -ne $dscException) {
                New-UpliftTrackException $dscException.Exception $eventProps $null
            }
        } catch {
            Write-UpliftWarnMessage "[!] Cannot use AppInsight, please report this error or use UPLF_NO_APPINSIGHT env variable to disable it."
            Write-UpliftWarnMessage "[!] $_"
        }
    }

    return  $result
}


function Write-UpliftVariableValue($name, $value, $indentation) {
    $isSecterVariable = Test-UpliftSecretVariableName $name

    if([String]::IsNullOrEmpty($indentation) -eq $true) {
        $indentation = ""
    }

    if($isSecterVariable -eq $true) {
        Write-UpliftMessage "$indentation[ENV:$name]: ******"
    } else {
        Write-UpliftMessage "$indentation[ENV:$name]: $value"
    }
}

function Write-UpliftEnv($showAll = $false)
{
    Write-UpliftMessage "Running as: $($env:UserDomain)\$($env:UserName)"
    Write-UpliftMessage "Uplift environmanet variables:"

    $props = $null

    if($showAll -eq $false) {
        $props = Get-ChildItem Env: `
                    | Where-Object {  ( $_.Name.ToUpper().StartsWith("UPLIFT_") -eq $True) -or ( $_.Name.ToUpper().StartsWith("UPLF_") -eq $True) }
    } else {
        $props = Get-ChildItem Env: `
    }

    foreach($prop in $props) {
        $name  = $prop.Name
        $value = $prop.Value

        Write-UpliftVariableValue $name $value "`t"
    }
}

function Test-UpliftSecretVariableName($name) {
    return $name.ToUpper().Contains("_KEY") -or $name.ToUpper().Contains("_PASSWORD") -or $name.ToUpper().Contains("_TOKEN")
}

function Get-UpliftEnvVariable($name, $message, $defaultValue) {

    $x = $name
    $value = $null

    try {
        $value = (get-item env:$x -ErrorAction SilentlyContinue).Value
    } catch {
        $value = $null
    }

    if([String]::IsNullOrEmpty($value) -eq $true) {
        $errorMessage = "[~] cannot find env variable by name: $name - $message, will try default value if provided"
        Write-UpliftMessage $errorMessage

        if($null -ne $defaultValue) {
            Write-UpliftMessage " - using default value"
            Write-UpliftVariableValue $name $defaultValue

            return $defaultValue
        } else {
            throw "Cannot find env variable by name: $name - $message, and no default value wer provided"
        }

        throw $errorMessage
    } else {
        Write-UpliftVariableValue $name $value
    }

    return $value
}


function Install-UpliftInstallPackage {

    Param(
        [Parameter(Mandatory=$True)]
        $filePath,

        [Parameter(Mandatory=$True)]
        $packageName,

        [Parameter(Mandatory=$True)]
        $silentArgs,

        [Parameter(Mandatory=$True)]
        $validExitCodes,

        [Parameter(Mandatory=$False)]
        $fileType,

        [Parameter(Mandatory=$False)]
        $chocolateyInstallerPath
    )

    # this is a wrap up of boxstarter and chocolatey
    # idea is to get KBs installed in "offline" mode out of uplift file resources

    # https://github.com/riezebosch/BoxstarterPackages/blob/master/KB2919355/Tools/ChocolateyInstall.ps1
    # https://github.com/chocolatey/choco/blob/e96fb159e0957d9e2fee1e738d42dcc414957c91/src/chocolatey.resources/helpers/functions/Install-ChocolateyPackage.ps1

    if($null -eq $chocolateyInstallerPath) {
        $chocolateyInstallerPath  = "C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1"
    }

    if($null -eq $fileType) {
        $fileType  = "msu"
    }

    if (Get-HotFix -id $packageName -ea SilentlyContinue)
    {
        Write-UpliftMessage "Skipping installation, package is already installed: $packageName"
        return 0
    }

    Write-UpliftMessage "Importing Chocolatey install helper: $chocolateyInstallerPath"
    Import-Module $chocolateyInstallerPath

    Write-UpliftMessage "Installing package:"
    Write-UpliftMessage "`t - PackageName: $packageName"
    Write-UpliftMessage "`t - SilentArgs: $silentArgs"
    Write-UpliftMessage "`t - File: $filePath"
    Write-UpliftMessage "`t - FileType: $fileType"
    Write-UpliftMessage "`t - ValidExitCodes: $validExitCodes"

    if( [System.IO.File]::Exists($filePath) -eq $false) {
        $errroMessage = "File does not exist: $filePath"

        Write-UpliftMessage $errroMessage
        $fileDirPath = [System.IO.Path]::GetDirectoryName($filePath)

        if((Test-Path -Path $fileDirPath )){
            Write-UpliftMessage "Showing folder content: $fileDirPath"
            Get-ChildItem -Path $fileDirPath
        } else {
            Write-UpliftMessage "Folder does not exist: $fileDirPath"
        }

        throw $errroMessage
    }

    $result = Install-ChocolateyInstallPackage  -PackageName $packageName `
                                                -SilentArgs $silentArgs `
                                                -File $filePath `
                                                -FileType $fileType `
                                                -ValidExitCodes $validExitCodes

    Write-UpliftMessage "Finished installation, result: $result"

    return $result
}

function Wait-UpliftProcess() {

    Param(
        [Parameter(Mandatory=$True)]
        $processName
    )

    while( $null -ne ( get-process | Where-Object { $_.ProcessName.ToLower() -eq $processName } ) ) {
        Write-UpliftMessage "$processName is still running... sleeping 5 sec.."
        Start-Sleep -Seconds 5
    }
}

function Invoke-UpliftIISReset {
    Write-UpliftMessage "Restarting IIS..."
    iisreset
    Write-UpliftMessage "Completed restarting IIS!"

    Invoke-UpliftIISPoolStart
}

function Invoke-UpliftIISPoolStart {
    Import-Module WebAdministration

    Write-UpliftMessage "Bringing up IIS pools..."

    $pools = Get-ChildItem -Path 'IIS:\AppPools'

    foreach($pool in $pools) {
        $name = $pool.Name

        Write-UpliftMessage "Bringing up IIS pool: $name"
        Start-WebAppPool -Name $name
    }
}

function Find-UpliftFileInPath {
    Param(
        [Parameter(Mandatory=$True)]
        $path,

        [Parameter(Mandatory=$False)]
        $ext = "exe"
    )

    $folder = $path

    # file or folder?
    if($path.ToUpper().EndsWith($ext.ToUpper()) -eq $true) {
        $folder  = Split-Path $path
    } else {
        $folder = $path
    }

    Write-UpliftMessage "Looking for '$ext' file in folder: $path"
    $exeFile = Get-ChildItem $folder -Filter "*.$ext"  | Select-Object -First 1

    Write-UpliftMessage " - found: $($exeFile.FullName)"

    if( ($null -eq $exeFile) -or ($null -eq $exeFile.Name) ) {
        throw "Cannot find any '$ext' files in folder: $path"
    }

    return $exeFile.FullName
}

function Install-UpliftPSModule {

    Param(
        $name,
        $version
    )

    $maxAttempt = 5
    $attempt = 1
    $success = $false

    while ( ($attempt -le $maxAttempt) -and (-not $success) ) {

        $oldProgressPreference = $progressPreference

        try {
            $progressPreference = 'silentlyContinue'

            Write-UpliftMessage "`t[$attempt/$maxAttempt] ensuring package: $name $version"
            $existinModule = $null

            if( [String]::IsNullOrEmpty($version) -eq $True) {
                Write-UpliftMessage "`tchecking if package exists: $name $version"
                $existinModule = Get-Module -ListAvailable | Where-Object { $_.Name -eq $name }
            } else {
                Write-UpliftMessage "`tchecking if package exists: $name $version"
                $existinModule = Get-Module -ListAvailable | Where-Object { $_.Name -eq $name -and $_.Version -eq $version}
            }

            if( $null -ne $existinModule) {
                Write-UpliftMessage "`t`tpackage exists, nothing to do: $name $version"
            }
            else {
                Write-UpliftMessage "`t`tpackage does not exist, installing: $name $version"

                if ([System.String]::IsNullOrEmpty($version) -eq $true) {
                    Install-Module -Name $name -Force -SkipPublisherCheck
                } else {
                    Install-Module -Name $name -RequiredVersion $version -Force -SkipPublisherCheck
                }
            }

            Write-UpliftMessage "`t[$attempt/$maxAttempt] finished ensuring package: $name $version"
            $success = $true
        } catch {
            $exception = $_.Exception

            Write-UpliftMessage "`t[$attempt/$maxAttempt] coudn't install package: $name $version"
            Write-UpliftMessage "`t[$attempt/$maxAttempt] error was: $exception"

            $attempt = $attempt + 1
        } finally {
            $progressPreference = $oldProgressPreference
        }
    }

    if($success -eq $false) {
        $errorMessage = "`t[$attempt/$maxAttempt] coudn't install package: $name $version"

        Write-UpliftMessage $errorMessage
        throw $errorMessage
    }
}

function Install-UpliftPSModules {

    Param(
        [Parameter(Mandatory=$True)]
        $packages
    )

    foreach($package in $packages ) {

        $name = $package["Id"]
        $version = $package["Version"]

        if($version -is [System.Object[]]) {

            foreach($versionId in $version) {
                Install-UpliftPSModule $name $versionId
            }

        } else {
            Install-UpliftPSModule $name $version
        }
    }
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

    $repo = Get-PSRepository `
        -Name $name `
        -ErrorAction SilentlyContinue

    if($null -eq $repo) {
        Write-UpliftInfoMessage " [~] Regestering repo: $name"
        Write-UpliftInfoMessage " - path: $source"
        Write-UpliftInfoMessage " - installPolicy: $installPolicy"

        if($null -eq $publish) {
            Write-UpliftInfoMessage " - path: $source"

            Register-PSRepository -Name $name `
                -SourceLocation $source `
                -PublishLocation $source `
                -InstallationPolicy $installPolicy
        } else {
            Write-UpliftInfoMessage " - path: $publish"

            Register-PSRepository -Name $name `
                -SourceLocation $source `
                -PublishLocation $publish `
                -InstallationPolicy $installPolicy
        }

    } else {
        Write-UpliftInfoMessage "Repo exists: $name"
    }
}

function Set-UpliftDCPromoSettings {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]

    param(
        $domainAdminPass
    )

    # https://aryannava.com/2012/01/05/administrator-password-required-error-in-dcpromo-exe/

    $message =  "Executing 'net user Administrator /passwordreq:yes' to bypass dcpromo errors"
    Write-UpliftMessage $message

    net user Administrator $domainAdminPass /passwordreq:yes
    Confirm-UpliftExitCode $LASTEXITCODE "Failed to execute: $message"
}

function Disable-UpliftIP6Interface {

    Disable-NetAdapterBinding -InterfaceAlias "Ethernet" `
        -ComponentID ms_tcpip6 `
        -ErrorAction SilentlyContinue

    Disable-NetAdapterBinding -InterfaceAlias "Ethernet 2" `
        -ComponentID ms_tcpip6 `
        -ErrorAction SilentlyContinue
}

function Install-UpliftPS6Module() {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope = "Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope = "Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope = "Function")]

    param(
        $moduleName,
        $version,
        $repository
    )

    Install-UpliftPSModule $moduleName $version $repository $True
}

function Install-UpliftPSModule() {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope = "Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope = "Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope = "Function")]

    param(
        $moduleName,
        $version,
        $repository,
        $usePS6 = $false
    )

    if( [String]::IsNullOrEmpty($version) -eq $True) {
        $version = $null
    }

    Write-UpliftMessage "Installing module: $moduleName version: $version, repository: $repository"

    Write-UpliftMessage "Looking for the latest module $moduleName"
    $moduleDefinition = Find-Module -Name $moduleName `
        | Select-Object Version, Repository `
        | Sort-Object Version -Descending `
        | Select-Object -First 1

    Write-UpliftMessage "Found latest module"
    Write-UpliftMessage $moduleDefinition
    Write-UpliftMessage " - version   : $($moduleDefinition.Version)"
    Write-UpliftMessage " - repository: $($moduleDefinition.Repository)"

    if([String]::IsNullOrEmpty($version) -eq $True) {

        if($null -eq $moduleDefinition) {
            throw "Failed to install module $moduleName - repo/version were not provided, and cannot find latest in any repo"
        }

        $version = $moduleDefinition.Version

        if([String]::IsNullOrEmpty($repository) -eq $True) {
            $repository = $moduleDefinition.Repository
        }

        Write-UpliftMessage "Installing latest ($version) $moduleName version: $version, repository: $repository"

        if($usePS6 -eq $True) {
            pwsh -c "Install-Package $moduleName -Source $repository -RequiredVersion $version -Force -SkipPublisherCheck"
            Confirm-UpliftExitCode $LASTEXITCODE "Cannot install PS6 module: $moduleName, version: $version repository: $repository"
        } else {
            Install-Package $moduleName -Source $repository -RequiredVersion $version -Force -SkipPublisherCheck
        }
    }
    else {
        if([String]::IsNullOrEmpty($repository) -eq $True) {
            $repository = $moduleDefinition.Repository
        }

        Write-UpliftMessage "Installing specified version $moduleName version: $version, repository: $repository"

        if($usePS6 -eq $True) {
            pwsh -c "Install-Package $moduleName -Source $repository -Force  -RequiredVersion $version -SkipPublisherCheck"
            Confirm-UpliftExitCode $LASTEXITCODE "Cannot install PS6 module: $moduleName, version: $version repository: $repository"
        } else {
            Install-Package $moduleName -Source $repository -Force  -RequiredVersion $version -SkipPublisherCheck
        }
    }

    Write-UpliftMessage "Checking installed module: $moduleName"

    if($usePS6 -eq $True) {
        pwsh -c "Get-InstalledModule $moduleName"
        Confirm-UpliftExitCode $LASTEXITCODE "Cannot find installed PS6 module: $moduleName"
    } else {
        # TODO
    }
}

function Repair-UpliftIISApplicationHostFile {
    # https://forums.iis.net/t/1160389.aspx

    # You may be able to get into a working state by deleting
    # the existing keys inside the configProtectedData section in applicationhost.config
    # and then running "%windir%\system32\inetsrv\iissetup.exe /install SharedLibraries"
    # - note that any existing encrypted properties in the cofig file is lost at this point,
    # this should however setup up the encryption keys correctly to be able
    # to write new encrypted properties.

    $filePath           = "C:\Windows\System32\inetsrv\config\applicationHost.config"
    $filePathFlagFile   = "C:\Windows\System32\inetsrv\config\applicationHost.config.metabox-patch-flag"

    $shouldUpdate = ((Test-Path $filePathFlagFile) -eq $false)

    if($shouldUpdate) {

        Write-UpliftMessage "Fixing web server feature install..."
        Write-UpliftMessage "Running: Install-WindowsFeature web-server -IncludeAllSubFeature"

        Install-WindowsFeature Web-Server -IncludeAllSubFeature | Out-Null

        Write-UpliftMessage "Fixing up machine keys..."
        # fix machine keys for IIS after sysprep
        # http://rcampi.blogspot.com.au/2012/02/iis-75-cloning-machine-keys.html
        Repair-UpliftMachineKeys

        Write-UpliftMessage "Cleaning up old machine keys..."
        Remove-UpliftOldMachineKeys

        Write-UpliftMessage "Patching IISApplicationHostFile: $filePath"

        $xml = [xml](Get-Content $filePath)

        $configProtectedDataNode = $xml.configuration.configProtectedData

        Write-UpliftMessage " - configProtectedData nodes count: $($configProtectedDataNode.providers.ChildNodes.Count)"

        if ($configProtectedDataNode.ChildNodes.Count -gt 0) {
            Write-UpliftMessage " - cleaning up section: configuration.configProtectedData.providers"
            $configProtectedDataNode.RemoveChild($configProtectedDataNode.ChildNodes[0])

            Write-UpliftMessage " - saving file: $filePath"
            $xml.Save($filePath)
        } else {
            Write-UpliftMessage " - can't find sections in configuration.configProtectedData"
        }

        Write-UpliftMessage "Running c:\windows\system32\inetsrv\iissetup.exe /install SharedLibraries, expecting '0' or 'Failed = 0x80070005'"
        c:\windows\system32\inetsrv\iissetup.exe /install SharedLibraries

        Write-UpliftMessage " - adding flag file: $filePathFlagFile"
        "yes" > $filePathFlagFile
    } else {
        Write-UpliftMessage "IISApplicationHostFile has already been patched..."
    }
}

function Remove-UpliftOldMachineKeys {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope = "Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope = "Function")]

    param(

    )

    $path = "C:\ProgramData\Microsoft\Crypto\RSA\S-1-5-18"

    if(Test-Path $path) {
        Write-UpliftMessage "Deleting path: $path"
        Remove-Item $path -Recurse -Force
    } else {
        Write-UpliftMessage "Path was already deleted: $path"
    }
}

function Repair-UpliftMachineKeys {

    # http://rcampi.blogspot.com.au/2012/02/iis-75-cloning-machine-keys.html

    #Variables
    $regGUIDPath = "HKLM:\SOFTWARE\Microsoft\Cryptography"
    $regGuidName = "MachineGuid"
    $machineKeyFolder = "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys"
    $key1 = "c2319c42033a5ca7f44e731bfd3fa2b5_"
    #$key2 = "7a436fe806e483969f48a894af2fe9a1_"
    $key2 = "76944fb33636aeddb9590521c2e8815a_"


    #Get CurRename-Itemt GUID
    $machGUID =  (Get-ItemProperty -Path $regGUIDPath -Name $regGuidName).MachineGuid


    #Rename-Itemame new one if it was created.  If IIS starts and there is no key, it will create a new one with new GUID
    if(test-path $machineKeyFolder\$key1$machGUID){
        Rename-Item "$machineKeyFolder\$key1$machGUID" "$key1$machGUID.OLD"
    }


    if(test-path $machineKeyFolder\$key2$machGUID){
        Rename-Item "$machineKeyFolder\$key2$machGUID" "$key2$machGUID.OLD"
    }
    #Now find the oldest key and Rename-Itemame it using the new machine GUID
    $files = Get-ChildItem ("$machineKeyFolder\*.*") -include ("$key1*") | sort-object -property ($_.CreationTime)


    foreach ($file in $files)
    {
        $fileName = $file.Name
        if (!$fileName.EndsWith($machGUID))
            {
                Copy-Item "$machineKeyFolder\$fileName" "$machineKeyFolder\$fileName.OLD"
                Rename-Item "$machineKeyFolder\$fileName" "$key1$machGUID"
                break
            }
    }


    $files = Get-ChildItem ("$machineKeyFolder\*.*") -include ("$key2*") | sort-object -property ($_.CreationTime)


    foreach ($file in $files)
    {
        $fileName = $file.Name
        if (!$fileName.EndsWith($machGUID))
            {
                Copy-Item "$machineKeyFolder\$fileName" "$machineKeyFolder\$fileName.OLD"
                Rename-Item "$machineKeyFolder\$fileName" "$key2$machGUID"
                break


            }
    }

}