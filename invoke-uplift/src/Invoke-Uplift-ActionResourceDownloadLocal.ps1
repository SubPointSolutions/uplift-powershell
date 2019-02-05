

# resource file helpers
function Get-LocalResourceContainer($resourceId, $dstDir, $force = $false) {

    Write-DebugMessage "[~] creatng local resource container:"
    Write-DebugMessage " - resource: $resourceId"
    Write-DebugMessage " - dstDir  : $dstDir"
    Write-DebugMessage " - force   : $force"

    $id          = $resourceId.ToLower()
    $resourceDir = Join-Path -Path $dstDir -ChildPath $id

    $container =  New-Object PsObject -Property @{
        ResourceId   = $id

        ResourceUrl         = $null

        ResourceLatestUrl   = $null
        ResourceLatestMetadataUrl = $null

        ResourceLatestFileUrl = $null
        ResourceLatestChecksumFileUrl = $null

        Force = $force

        LatestDirPath   = (Join-Path -Path $resourceDir -ChildPath "latest")
        LatestFilePath  = $null

        StagingDirPath   = (Join-Path -Path $resourceDir -ChildPath "download-staging")
        StagingFilePath  = $null

        StagingChecksumFilePath = $null
        StagingMetadataFilePath = $null

        Metadata = $null

        CacheDirPath    = (Join-Path -Path $resourceDir -ChildPath "cache")

        LocalRepositoryPath = $dstDir
        ResourceDirPath     = $resourceDir

        ResourceFileName          = $null
        ResourceChecksumFileName  = $null
        ResourceFileExtension     = $null

        IsUnpackable = $false
        IsISO        = $false
        IsZIP        = $false
    }

    Write-DebugMessage "[~] container"
    Write-DebugMessage " - data: $container"

    Write-DebugMessage "[~] ensuring all dir paths"

    New-Folder  $container.StagingDirPath
    New-Folder  $container.LatestDirPath
    New-Folder  $container.CacheDirPath

    New-Folder  $container.ResourceDirPath

    return $container
}

function Get-LocalResourceStampFileName() {
    return "__metadata.uplift.json"
}

function Get-LocalResourceLatestStatus($localContainerPath) {
    $flagFile = Join-Path -Path $localContainerPath -ChildPath (Get-LocalResourceStampFileName)

    return Test-Path $flagFile
}

function Confirm-HttpUrl($value) {
    if( ($value.StartsWith("http://") -eq $False) -and ($value.StartsWith("https://") -eq $False) ) {
        throw "Value must be http/https URL: $value"
    }
}

function Confirm-LatestUrlsAvailability($resourceContainer) {
    Confirm-UrlAvailability $resourceContainer.ResourceLatestFileUrl
    Confirm-UrlAvailability $resourceContainer.ResourceLatestChecksumFileUrl
}

function Join-Uri ($a, $b)
{
    # extremely stupid uri join
    $result = $a.Trim("/").Trim("\") + "/" + $b.Trim("/").Trim("\")

    return $result
}

function Confirm-UrlAvailability($url) {

    Write-DebugMessage "Checking url: $url"

    $result = Invoke-WebRequest "$url" `
        -UseBasicParsing `
        -DisableKeepAlive `
        -Method HEAD

    if($result.StatusCode -eq 200) {
        Write-DebugMessage "[+] StatusCode: $($result.StatusCode) for url: $url"
    } else {
        throw "[!] StatusCode: $($result.StatusCode), expected 200!"
    }
}

function Confirm-HttpUrl($value) {

    $value = $value.ToLower()

    if( ($value.StartsWith("http://") -eq $False) -and ($value.StartsWith("https://") -eq $False) ) {
        throw "Value must be http/https URL: $value"
    }
}

function Write-LocalResourceMetadata($resourceContainer, $metadata) {

    $path = Join-Path -Path $resourceContainer.LatestDirPath -ChildPath (Get-LocalResourceStampFileName)

    $metadata | `
        ConvertTo-Json -Depth 10 | `
        Out-File $path -Force
}

function Invoke-LocalStagingDownload($resourceContainer) {

    # is staging ok already?
    Write-InfoMessage "[~] checking if /download-staging is OK"
    $result =  Confirm-LocalFileValidity $resourceContainer.StagingFilePath

    $preferredTool = Get-CommandOptionValue @("-t", "-tool") $null $null

    if($result -eq $False) {
        Write-InfoMessage "[~] downloading files..."

        Write-InfoMessage "[1/2] downloading: $($resourceContainer.ResourceChecksumFileName)"
        Invoke-DownloadFile `
            $resourceContainer.ResourceLatestChecksumFileUrl `
            $resourceContainer.StagingChecksumFilePath `
            $preferredTool

        Write-InfoMessage "[2/2] downloading: $($resourceContainer.ResourceFileName)"
        Invoke-DownloadFile `
            $resourceContainer.ResourceLatestFileUrl `
            $resourceContainer.StagingFilePath `
            $preferredTool

        Write-InfoMessage "[~] checksum validation: $($resourceContainer.StagingFilePath)"
        $result =  Confirm-LocalFileValidity $resourceContainer.StagingFilePath

        if($result  -eq $False) {
            throw "Incorrect checksum: $(resourceContainer.StagingFilePath)"
        } else {
            Write-InfoMessage "[+] checksum validation ok!"
        }
    } else {
        Write-InfoMessage "[+] /download-staging is OK"
    }
}

function Invoke-UnpackStagingToLatest($localFilePath, $localLatestFolder, $extension) {

    # cleaning up latest folder
    Invoke-CleanFolder $localLatestFolder

    $isISO = ($extension -ieq '.iso') -or ($extension -ieq '.img')
    $isZIP = $extension -ieq '.zip'

    Write-InfoMessage "[~] detected unpackable file, will unpack it to /latest..."

    Write-InfoMessage " - isISO: $isISO"
    Write-InfoMessage " - isZIP: $isZIP"

    if($isISO -eq $True) {
        if($IsWindows -eq $True) {
            # windows case only
            if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) {throw "$env:ProgramFiles\7-Zip\7z.exe needed"}
            set-alias sz "$env:ProgramFiles\7-Zip\7z.exe"

            Write-DebugMessage " - cmd:  sz x -y $localFilePath -o$localLatestFolder"

            sz x -y "$localFilePath" "-o$localLatestFolder"
            Confirm-ExitCode $LASTEXITCODE "Failed to unpack: $localFilePath"

        } elseif($IsMacOS -eq $True) {

            Write-DebugMessage " - cmd: 7z x -y $localFilePath -o$localLatestFolder"

            7z x -y "$localFilePath" "-o$localLatestFolder"
            Confirm-ExitCode $LASTEXITCODE "Failed to unpack: $localFilePath"
        }
    } elseif($isZIP -eq $True) {
        if($IsWindows -eq $True) {
            # windows case only
            if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) {throw "$env:ProgramFiles\7-Zip\7z.exe needed"}
            set-alias sz "$env:ProgramFiles\7-Zip\7z.exe"

            Write-DebugMessage " - cmd: sz e $localFilePath -o$localLatestFolder"

            sz e -y "$localFilePath" "-o$localLatestFolder"
            Confirm-ExitCode $LASTEXITCODE "Failed to unpack: $localFilePath"

        } elseif($IsMacOS -eq $True) {

            Write-DebugMessage " - cmd: 7z e $localFilePath -o$localLatestFolder"
            7z e -y "$localFilePath" "-o$localLatestFolder"

            Confirm-ExitCode $LASTEXITCODE "Failed to unpack: $localFilePath"
        }
    } else {
        throw "Unsupported extention to unpack: $extension"
    }

    Write-InfoMessage "[+] completed unpacking!"
}

function Invoke-LocalLatestDownload($resourceContainer, $skipUnpack) {

    Write-InfoMessage "[~] preparing /latest"

    $localFilePath     = $resourceContainer.StagingFilePath

    $localStagingPath  = $resourceContainer.StagingDirPath
    $localLatestFolder = $resourceContainer.LatestDirPath

    Write-DebugMessage "[~] cleaning up /latest path"
    Invoke-CleanFolder $localLatestFolder

    $fileExtension = [System.IO.Path]::GetExtension($localFilePath).ToLower()
    Write-DebugMessage " - ext: $fileExtension"

    if($skipUnpack -eq $True) {
        Write-InfoMessage " - moving non-unpackable file to /latest (skipUnpack = $skipUnpack)"

        Write-DebugMessage " - src: $localStagingPath/*"
        Write-DebugMessage " - dst: $localLatestFolder"

        Move-Item "$localStagingPath/*" $localLatestFolder
    } else {
        Write-InfoMessage " - testing type of file before moving to /latest (skipUnpack = $skipUnpack)"

        switch($fileExtension) {
            '.iso' { Invoke-UnpackStagingToLatest $localFilePath $localLatestFolder $fileExtension }
            '.img' { Invoke-UnpackStagingToLatest $localFilePath $localLatestFolder $fileExtension }
            '.zip' { Invoke-UnpackStagingToLatest $localFilePath $localLatestFolder $fileExtension }

            default {
                Write-InfoMessage " - moving non-unpackable file to /latest"

                Write-DebugMessage " - src: $localStagingPath/*"
                Write-DebugMessage " - dst: $localLatestFolder"

                Move-Item "$localStagingPath/*" $localLatestFolder
            }
        }
    }
}

function Invoke-ActionResourceDownload-Local () {
    [System.ComponentModel.CategoryAttribute("ActionCommand")]
    [System.ComponentModel.DescriptionAttribute("Downloads resource from http server into local folder")]

    param(
        $commandOptions
    )

    $resourceId  = $commandOptions.Third

    Write-DebugMessage "cmd option: $resourceId"

    if( [String]::IsNullOrEmpty($resourceId) -eq $True ) {
        throw "A resource name is required. Try 7z-1805-x64 or 7z-1805-"
    }

    $serverUrl            = Get-CommandOptionValue @("-s", "-server")  $commandOptions "http://localhost:8080"
    $localRepositoryPath  = Get-CommandOptionValue @("-r", "-repository") $commandOptions "uplift-local-resources"
    $isForce              = Get-ForceStatus $commandOptions

    $skipUnpack           = Get-CommandOptionValue @("-skip-unpack", "-no-unpack") $commandOptions

    $resourceContainer = Get-LocalResourceContainer $resourceId $localRepositoryPath $isForce

    Write-InfoMessage "Downloading local resource: $resourceId"

    Confirm-HttpUrl $serverUrl

    $resourceContainer.ResourceUrl         = Join-Uri $serverUrl $resourceId
    $resourceContainer.ResourceLatestUrl   = Join-Uri $resourceContainer.ResourceUrl  "latest"
    $resourceContainer.ResourceLatestMetadataUrl  = Join-Uri $resourceContainer.ResourceUrl  "/latest/__metadata.uplift.json"

    Write-InfoMessage "[+] Remote resource:"
    Write-InfoMessage "   - server : $serverUrl"
    Write-InfoMessage "   - url    : $($resourceContainer.ResourceUrl)"
    Write-InfoMessage "   - meta   : $($resourceContainer.ResourceLatestMetadataUrl )"

    Write-InfoMessage ""

    Write-InfoMessage "[+] Local resource:"
    Write-InfoMessage "   - repo     : $($resourceContainer.LocalRepositoryPath)"
    Write-InfoMessage "   - resource : $($resourceContainer.ResourceDirPath)"
    Write-InfoMessage "   - latestt  : $($resourceContainer.LatestDirPath)"

    Write-InfoMessage ""

    Write-InfoMessage "[+] Download options:"
    Write-InfoMessage "   - force       : $isForce"
    Write-InfoMessage "   - skip unpack : $skipUnpack"

    $isLatestOk = Get-LocalResourceLatestStatus $resourceContainer.LatestDirPath

    if($isLatestOk -eq $True) {
        if($isForce -eq $True) {
            Write-WarnMessage "[~] -force flag, latest is OK but will download again"
        } else {
            Write-InfoMessage "[+] latest is OK, won't download"
            return 0
        }
    } else {
        Write-WarnMessage "[~] latest is NOT OK, will download it"
    }

    $resourceMetadataUrl = $resourceContainer.ResourceLatestMetadataUrl
    $resourceLatestUrl   = $resourceContainer.ResourceLatestUrl

    # pinging metadata files, fetching file name
    Confirm-UrlAvailability $resourceMetadataUrl

    Write-InfoMessage "[~] fetching metadata: $resourceMetadataUrl"
    $metadataResult = Invoke-WebRequest $resourceMetadataUrl `
                        -UseBasicParsing

    Write-DebugMessage "[~] result: $metadataResult"

    $metadata =  $metadataResult | ConvertFrom-Json
    $resourceContainer.Metadata = $metadata

    $resourceFileName         = $metadata.file_name
    $resourceChecksumFileName =  ($resourceFileName + ".sha256")

    $resourceContainer.ResourceFileName         = $resourceFileName
    $resourceContainer.ResourceChecksumFileName = $resourceChecksumFileName

    $resourceContainer.ResourceLatestFileUrl         = Join-Uri $resourceLatestUrl $resourceFileName
    $resourceContainer.ResourceLatestChecksumFileUrl = Join-Uri $resourceLatestUrl $resourceChecksumFileName

    $resourceContainer.ResourceLatestFileUrl         = Join-Uri $resourceLatestUrl $resourceFileName

    $resourceContainer.StagingFilePath         = Join-Path -Path $resourceContainer.StagingDirPath -ChildPath $resourceFileName
    $resourceContainer.StagingChecksumFilePath = Join-Path -Path $resourceContainer.StagingDirPath -ChildPath $resourceChecksumFileName

    # alive?
    Confirm-LatestUrlsAvailability $resourceContainer

    # download to staging
    # check if anything in cache?
    # check and create checksums
    Invoke-LocalStagingDownload $resourceContainer

    # move staging to latest
    # fill cache, store needed files in cache
    Invoke-LocalLatestDownload $resourceContainer $skipUnpack

    Write-InfoMessage "[~] cleaning up /download-staging"
    Invoke-CleanFolder $resourceContainer.StagingDirPath

    # write local stamp
    # same-same as /"__metadata.uplift.json under latest URL
    Write-LocalResourceMetadata $resourceContainer $metadata

    Write-InfoMessage "[+] local resource path: $($resourceContainer.LatestDirPath)"
    Write-InfoMessage "[+] completed transfer for local resource: $resourceId"

    return 0
}

