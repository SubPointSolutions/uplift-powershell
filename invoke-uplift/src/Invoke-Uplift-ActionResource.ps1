

# resource file helpers
function Get-ResourceFileFolders()  {
    return @(
        # current directory where the script lives
        ( Split-Path -Parent $PSCommandPath)
    )
}

function Get-ResourceFiles() {
    $filter = "*.resource.json"
    $depth  = 2

    # -ErrorAction SilentlyContinue makes PS supress nested read permissions errrors if any

    Write-DebugMessage "Scanning current directory with filter $filter depth: $depth"
    $result =  (Get-ChildItem -Filter $filter `
        -Recurse `
        -Depth $depth `
        -ErrorAction SilentlyContinue
    )

    if($result.Count -eq 1) {
        $result = @($result)
    }

    Write-DebugMessage " - found files: $($result.Count)"

    $otherFolders = Get-ResourceFileFolders

    foreach($otherFolder in $otherFolders) {
        Write-DebugMessage "Scanning directory with filter $filter depth: $depth - $otherFolder"

        $otherResult =  (Get-ChildItem -Path $otherFolder `
            -Filter $filter -Recurse `
            -Depth $depth `
            -ErrorAction SilentlyContinue
        )

        if($otherResult.Count -eq 1) {
            $otherResult = @($otherResult)
        }

        Write-DebugMessage " - found files: $($otherResult.Count)"

        if($otherResult.Count -gt 0) {
            $result += $otherResult
        }
    }

    Write-DebugMessage " - found files: $($result.Count)"
    $result = $result | Select-Object -uniq

    Write-DebugMessage " - uniq files: $($result.Count)"

    return $result
}

function Get-AllResources() {

    $result = @()
    $files  = Get-ResourceFiles

    Write-DebugMessage "Loading resource files"

    foreach($filePath in $files) {
        Write-DebugMessage " - loading file: $filePath"

        $json = Get-Content -Raw -Path $filePath | ConvertFrom-Json
        Write-DebugMessage "    - loaded json: $json"

        foreach($resource in $json.resources) {
            $result += $resource
        }
    }

    Write-DebugMessage "Loaded $($result.Count) resources"

    return $result
}

function Get-AllResourcesMatch($matchValue) {

    Write-DebugMessage "Get-AllResourcesMatch, loading for match: $matchValue"
    $resources   = Get-AllResources

    Write-DebugMessage " - filtering resource ids by match: $matchValue"

    $result = @()

    if([String]::IsNullOrEmpty( $matchValue ) -eq $False) {
        Write-DebugMessage " - filtering resource ids by match: $matchValue"
        $result = $resources `
            | Where-Object { $_.id -match $matchValue }
    } else {
        Write-DebugMessage " - returning all resources, match is empty"
        $result = $resources
    }

    if($null -eq $result) {
        $result = @()
    }

    return $result
}

function Get-ResourceFileName($resource) {

    $result = $resource.file_name

    if([string]::IsNullOrEmpty($result) -eq $true) {
        $result = Split-Path $resource.uri -Leaf
    }

    return $result
}

function Get-ResourceType($resource) {

    $result = $resource.type

    if([string]::IsNullOrEmpty($result) -eq $true) {
        $result = "uplift/http-file"
    }

    return $result
}

# resource validate-uri
. "$PSScriptRoot/Invoke-Uplift-ActionResourceValidateUri.ps1"

# resource list


# main action
function Invoke-ActionResource {
    [System.ComponentModel.CategoryAttribute("Action")]
    [System.ComponentModel.DescriptionAttribute("Downloads file resources to local repository")]
    param(
        $commandOptions
    )

    $result = Invoke-ActionVersion

    . "$PSScriptRoot/Invoke-Uplift-ActionResourceDownload.ps1"
    . "$PSScriptRoot/Invoke-Uplift-ActionResourceDownloadLocal.ps1"
    . "$PSScriptRoot/Invoke-Uplift-ActionResourceList.ps1"

    switch($commandOptions.Second)
    {
        "download"       {
            return (Invoke-ActionResourceDownload      $commandOptions)
        }

        "download-local" {
            return (Invoke-ActionResourceDownload-Local $commandOptions)
        }
        "list"           {
            return (Invoke-ActionResourceList          $commandOptions)
        }

        "validate-uri"   {
            return (Invoke-ActionResourceValidate-Uri   $commandOptions)
        }

        default          {
            $commands = Get-AvailableActionCommands "Invoke-ActionResource"
            Write-CommandHelp $commands "resource"

            return 0
        }
    }

    $result = 0

    return $result
}