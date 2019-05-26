

function Invoke-CommandOptionsParse($options) {
    $result = New-Object PSObject -Property @{}

    # handling null array, potential call without any parameters
    if($null -eq $options) {
        $options = @()
    }

    $first  = [String]$options[0]
    $second = [String]$options[1]
    $third  = [String]$options[2]

    # neither if these can ever start with '-'
    # all '-' are system options, so first/second/third are empty then

    if($first.StartsWith('-')  -eq $True) { $first  = "" }
    if($second.StartsWith('-') -eq $True) { $second = "" }
    if($third.StartsWith('-')  -eq $True) { $third  = "" }

    # constructing PSObject that way makes JSON serialization follow property ordering
    # indexing won't fail with [Stirng] casting
    $result | Add-Member -Name 'First'   -Type NoteProperty -Value $first  -Force
    $result | Add-Member -Name 'Second'  -Type NoteProperty -Value $second -Force
    $result | Add-Member -Name 'Third'   -Type NoteProperty -Value $third  -Force

    $result | Add-Member -Name 'Options' -Type NoteProperty -Value @{} -Force

    # handling option pairs: [-name value] or [-name] only
    for($i = 0; $i -lt $options.Count; $i++) {
        $option = [string]$options[$i]

        if($option.StartsWith("-") -eq $True) {
            $result.Options[$option] = $True

            if( ($i + 1) -lt $options.Count -and ( ([string]$options[$i + 1]).StartsWith("-")) -eq $False) {
                $result.Options[$option] = [string]$options[$i + 1]
            }
        }
    }

    # system flags, these are use by other core scripts

    # - which don't have access to -Core.ps1
    # - which should not have dependency on -Core.ps1
    if( Get-DebugStatus($result) -eq $True ) {
        $ENV:UPLF_LOG_LEVEL = "DEBUG"
    }

    # log format flag
    $ENV:UPLF_LOG_FORMAT   =  Get-CommandOptionValue @("-lf", "-log-format") $result $null

    # no color flag?
    $ENV:UPLF_LOG_NO_COLOR =  Get-CommandOptionValue @("-nc", "-no-color") $result $null

    return $result
}

function Get-CommandOptionValue($names, $commandOptions, $default) {
    if($names -is [String]) {
        $names = @($names)
    }

    $options = $commandOptions

    if($null -ne $script:CommandOptions) {
        $options = $script:CommandOptions
    }

    if($null -eq $options) {
        return $default
    }

    foreach($name in $names) {
        if( (Confirm-CommandOptionValue $name $options) -eq $True) {
            return ($options.Options[$name])
        }
    }

    return $default
}

function Confirm-CommandOptionValue($names, $commandOptions) {
    if($names -is [String]) {
        $names = @($names)
    }

    $options = $commandOptions

    if($null -ne $script:CommandOptions) {
        $options = $script:CommandOptions
    }

    if($null -eq $options) {
        return $false
    }

    foreach($name in $names) {
        if($options.Options.ContainsKey($name) -eq $True) {
            return $True
        }
    }

    return $false
}

function Get-DebugStatus($commandOptions) {
    return (
        Get-CommandOptionValue @("-d", "-debug") $commandOptions
    )
}

function Get-ForceStatus($commandOptions) {
    return (
        Get-CommandOptionValue @("-f", "-force") $commandOptions
    )
}

function Get-LocalRepositoryPath($commandOptions) {

    $defaultValue = "uplift-local-repository"

    Write-DebugMessage "[~] resolving local repository path..."
    $repoFolderPath = Get-CommandOptionValue @("-r", "-repository") $commandOptions $defaultValue

    Write-DebugMessage "[+] using path: $repoFolderPath"
    New-Folder $repoFolderPath

    Write-DebugMessage "[~] calling resolve-path: $repoFolderPath"
    $repoFolderPath = (Resolve-Path $repoFolderPath).Path

    Write-DebugMessage "[+] final value: $repoFolderPath"

    return $repoFolderPath
}

function Confirm-ExitCode($code, $message){
    if ($code -eq 0) {
        Write-DebugMessage "Exit code is 0, continue..."
    } else {
        Write-DebugMessage "Exiting with non-zero code [$code] - $message"

        throw "Exiting with non-zero code [$code] - $message"
    }
}

function Invoke-ProcessErrors($errors) {
    if($errors.Count -gt 0) {
        Write-ErrorMessage "Error while downloading files: $($errors.Count)"

        foreach($err in $errors.Values) {
            Write-ErrorMessage $err.ToString()
        }
    } else {
        Write-DebugMessage "No errors found: $($errors.Count)"
    }
}

function Get-AvailableActions($prefix = "Invoke-Action") {

    $functions = Get-Command `
        | Where-Object { $_.Name.StartsWith($prefix) -eq $True } `
        | Sort-Object -Property Name

    # filter only with
    # [System.ComponentModel.CategoryAttribute("Action")]

    $result = @()

    foreach($function in $functions) {
        $action = Get-Command $function.Name

        $actionCategory    = ([string]$action.ScriptBlock.Attributes[0].Category).ToLower()
        # $actionDescription = ([string]$action.ScriptBlock.Attributes[1].Description).ToLower()

        if( $actionCategory -ne "Action") {
            continue;
        }

        $result += $function
    }


    return $result
}

function Get-AvailableActionCommands($prefix = "Invoke-Action") {

    $functions = Get-Command `
        | Where-Object { $_.Name.StartsWith($prefix) -eq $True } `
        | Sort-Object -Property Name

    # filter only with
    # [System.ComponentModel.CategoryAttribute("Action")]

    $result = @()

    foreach($function in $functions) {
        $action = Get-Command $function.Name

        $actionCategory    = ([string]$action.ScriptBlock.Attributes[0].Category).ToLower()
        # $actionDescription = ([string]$action.ScriptBlock.Attributes[1].Description).ToLower()

        if( $actionCategory -ne "ActionCommand") {
            continue;
        }

        $result += $function
    }


    return $result
}

function Write-CommandHelp {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]
    param(
        $actionFunctions,
        $action
    )

    if($null -eq $action) {
        $action = "[version] [help] <command>"
    }

    Write-Host "Usage: uplift $action [<args>]"
    Write-Host ''
    Write-Host "Available commands are:"

    $commands = @()

    foreach($actionFunction in $actionFunctions) {

        $actionDescription = ([string]$actionFunction.ScriptBlock.Attributes[1].Description).ToLower()

        $name = $actionFunction.Name.Replace("Invoke-Action", "").ToLower()
        $name = $name.Replace($action, "")

        $metadata  =  New-Object PsCustomObject  @{
            cmd = $name
            cmd_name = $actionDescription
        }

        $commands += $metadata
    }

    Write-Host ""

    $value = $commands  | ForEach-Object{
        [pscustomobject]@{
            ID   = "  " + $_["cmd"]
            ProcessName  = $_["cmd_name"]
        }
    } | Format-Table -AutoSize -HideTableHeaders `
      | Out-String

    Write-Host ("  " + $value.Trim())
    Write-Host ""

}