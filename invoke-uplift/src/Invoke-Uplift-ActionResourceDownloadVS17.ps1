

function Invoke-DownloadResourceVS17Layout ($resourceContainer, $vsClientPath, $layoutFolderPath) {

    Write-DebugMessage "[~] preparing vs layout folder"
    Write-DebugMessage " - vs client   : $vsClientPath"
    Write-DebugMessage " - layout folder: $layoutFolderPath"

    New-Folder $layoutFolderPath

    # checksum Layout.json in VS layout folder
    # it seems to be quite feasible solution,

    $layoutFileath = Join-Path -Path $layoutFolderPath -ChildPath "layout.json"

    if( (Confirm-LocalFileValidity $layoutFileath) -eq $True) {

        if($resourceContainer.Force -eq $True) {
            Write-InfoMessage "[~] -force, existing file is ok but will rebuild layout again"
        } else {
            Write-InfoMessage "[~] using existing layout folder: checksum is ok"
            return
        }
    }

    $optionsLayout     = @("--layout $layoutFolderPath")
    $additionalOptions = @()

    if($null -ne $resourceContainer.Resource.vs17_options) {
        $additionalOptions = $resourceContainer.Resource.vs17_options
    }

    # composing options
    $vs17Args = $optionsLayout + $additionalOptions
    $vs17ArgsString = [String]::Join([Environment]::NewLine, $vs17Args)

    # run vs client with giving options
    Write-DebugMessage "vs_client path: $vsClientPath"
    Write-InfoMessage ([String]::Join(
        [Environment]::NewLine, @(
            "[~] running vs_client with the following options",
            $vs17ArgsString
        )
    ))

    Write-InfoMessage "Started process..."
    $process = Start-Process `
        -FilePath $vsClientPath `
        -ArgumentList $vs17Args `
        -Wait -PassThru;

    $exitCode = $process.ExitCode;
    Write-DebugMessage "Finished with exit code: $exitCode"

    if($exitCode -ne 0) {
        Write-ErrorMessage "Finished with exit code: $exitCode"

        if($exitCode -eq 5007) {
            Write-ErrorMessage "Path to the installer is too long, more than 80 chars? - https://developercommunity.visualstudio.com/content/problem/292951/error-5007-when-trying-to-install-visual-studio-20.html"
        }

        throw "Non-zero exit code: $exitCode"
    }

    New-ChecksumFile $layoutFileath
}

function Invoke-DownloadResourceVS17LayoutZip($resourceContainer, $layoutFolderPath) {

    $stagingZipPath = Join-Path `
        -Path $resourceContainer.StagingDirPath `
        -ChildPath $resourceContainer.Resource.vs17_file_name

    Write-DebugMessage "[~] packaigng VS17 layout into zip archive"
    Write-DebugMessage " - layout path: $layoutFolderPath"
    Write-DebugMessage " - zip path   : $stagingZipPath"

    # always remove, 7z is not that smart
    if( (Test-Path $stagingZipPath) -eq $True) {
        Remove-Item $stagingZipPath -Force
    }

    # windows case only
    if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) {throw "$env:ProgramFiles\7-Zip\7z.exe needed"}
    set-alias sz "$env:ProgramFiles\7-Zip\7z.exe"

    # pack and validate, always
    Write-DebugMessage " - cmd: sz a $stagingZipPath $layoutFolderPath/*"
    sz a $stagingZipPath "$layoutFolderPath/*"
    Confirm-ExitCode $LASTEXITCODE "Failed to pack zip for resource: $layoutFolderPath"

    New-ChecksumFile $stagingZipPath
}

function Invoke-DownloadResourceVS17LayoutLatest($resourceContainer) {
    $stagingDirPath = $resourceContainer.StagingDirPath
    $latestDirPath  = $resourceContainer.LatestDirPath

    Move-Item "$stagingDirPath/*"  `
        $latestDirPath `
        -Force

    Write-InfoMessage  "[~] writing metadata"
    Write-LatestMetadata $resourceContainer $resourceContainer.Resource.vs17_file_name
}

function Invoke-DownloadResourceVS17Dist ($resourceContainer, $vsClientPath) {
    Write-DebugMessage "Downloading VisualStudio 2017 resource"

    $shouldDownload = $true

    # latest exists?
    $latestStatus = Get-LatestStatus $resourceContainer $resourceContainer.Resource.vs17_file_name

    if($latestStatus -eq $True) {
        if($resourceContainer.Force -eq $True) {
            Write-WarnMessage "[~] -force is set, /latest is OK but will download again"
            $shouldDownload = $True
        } else {
            Write-InfoMessage "[+] /latest is OK, won't download"
            $shouldDownload = $False
        }
    } else {
        Write-InfoMessage "[~] /latest is NOT OK, will download it"
    }

    if($shouldDownload -eq $True) {
        # download vs client to /cache folder
        Write-InfoMessage "[~] ensuring vs client"
        Invoke-CacheDownload $resourceContainer

        Write-InfoMessage "[~] ensuring vs layour folder"
        $vsClientPath     = $resourceContainer.CacheFilePath
        $layoutFolderPath = Join-Path -Path $resourceContainer.CacheDirPath -ChildPath "vs17-layout"

        New-Folder $layoutFolderPath

        Invoke-DownloadResourceVS17Layout $resourceContainer `
            $vsClientPath `
            $layoutFolderPath

        Write-InfoMessage "[~] packaging VS17 layout folder"
        Invoke-DownloadResourceVS17LayoutZip $resourceContainer $layoutFolderPath

        Write-InfoMessage "[~] moving to /latest"
        Invoke-DownloadResourceVS17LayoutLatest $resourceContainer
    }

    Write-InfoMessage "[+] completed!"
}