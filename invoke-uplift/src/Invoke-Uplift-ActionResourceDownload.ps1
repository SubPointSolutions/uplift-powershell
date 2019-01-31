

# helpers

. "$PSScriptRoot/Invoke-Uplift-ActionResourceDownloadVS17.ps1"

function Get-LatestStatus($resourceContainer, $customFileName = $null) {

    Write-DebugMessage "[~] checking /latest status"
    Write-DebugMessage " - customFileName: $customFileName"

    $filePath     = $resourceContainer.LatestFilePath
    $checksumPath = $resourceContainer.LatestChecksumFilePath
    $metadataPath = $resourceContainer.LatestMetadataFilePath

    if($null -ne $customFileName) {
        $filePath     = Join-Path -Path $resourceContainer.LatestDirPath -ChildPath $customFileName
        $checksumPath = "$filePath.sha256"
    }

    $fileOk     = Test-Path  $filePath
    $checksumOk = Test-Path  $checksumPath
    $metadataOk = Test-Path  $metadataPath

    Write-DebugMessage "- fileOk    : $fileOk $($filePath)"
    Write-DebugMessage "- checksumOk: $checksumOk $($checksumPath)"
    Write-DebugMessage "- metadataOk: $metadataOk $($metadataPath)"

    return ( $fileOk -and $checksumOk -and $metadataOk)
}

function Write-LatestMetadata($resourceContainer, $customFileName) {

    Write-DebugMessage "[+] saving metadata file"

    $fileName =  $resourceContainer.ResourceFileName
    if($null -ne $customFileName) {
        $fileName = $customFileName
    }

    $metadata     = New-Object PSObject -Property @{}
    $metadataPath =  $resourceContainer.LatestMetadataFilePath

    $metadata | Add-Member -Name 'file_name' `
        -Type NoteProperty -Force -Value  $fileName

    # checksum file always follows name convention:
    #   "file-name.extention" + ".sha256"
    # we should not even expose it here

    # $metadata | Add-Member -Name 'checksum_file_name' `
    #     -Type NoteProperty -Force -Value   ($resourceContainer.ResourceFileName + ".sha256")

    $metadataJSON = $metadata | ConvertTo-Json -Depth 10

    Write-DebugMessage "metadata path: $metadataPath"
    Write-DebugMessage "metadata json: $metadataJSON"

    $metadataJSON | Out-File $metadataPath -Force
}

function New-ChecksumFile {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    param(
        $originalFilePath,
        $checksumType = "SHA256"
    )

    $originalFileName     = (Split-Path $originalFilePath -Leaf)

    $originalFileChecksum = Get-FileHash -Algorithm $checksumType $originalFilePath
    $checksumFilePath     = ("$originalFilePath.$checksumType").ToLower()

    $checksumFileValue    = $originalFileChecksum.Hash.ToUpper() + "  " + $originalFileName

    Write-DebugMessage "[+] saving checksum file"
    Write-DebugMessage " - path : $checksumFilePath"
    Write-DebugMessage " - value: $originalFileChecksum"
    Write-DebugMessage " - checksumFileValue: $checksumFileValue"

    $checksumFileValue | Out-File $checksumFilePath -Force | Out-Null
}

function Get-ResourceContainer($resource, $dstDir, $force = $false) {

    Write-DebugMessage "[~] creating resource container:"
    Write-DebugMessage " - resource: $resource"
    Write-DebugMessage " - dstDir  : $dstDir"
    Write-DebugMessage " - force   : $force"

    # always to lower
    # that simplifies further static web site hosting
    # and potential transfers to Amazon/Azure and other clouds
    $id  = $resource.id.ToLower()

    $resourceDir       = Join-Path -Path $dstDir -ChildPath $id
    $resourceFileName = (Get-ResourceFileName $resource)

    $container =  New-Object PsObject -Property @{
        Resource   = $resource

        ResourceId   = $id
        ResourceType = Get-ResourceType $resource

        Force = $force

        LatestDirPath   = (Join-Path -Path $resourceDir -ChildPath "latest")
        LatestFilePath  = (Join-Path -Path $resourceDir -ChildPath "latest" -AdditionalChildPath $resourceFileName)
        LatestChecksumFilePath  = (Join-Path -Path $resourceDir -ChildPath "latest" -AdditionalChildPath ($resourceFileName + ".sha256")  )

        LatestMetadataFilePath  = (Join-Path -Path $resourceDir -ChildPath "latest" -AdditionalChildPath "__metadata.uplift.json")

        StagingDirPath  = (Join-Path -Path $resourceDir -ChildPath "download-staging")
        StagingFilePath = (Join-Path -Path $resourceDir -ChildPath "download-staging" -AdditionalChildPath $resourceFileName)

        CacheDirPath    = (Join-Path -Path $resourceDir -ChildPath "download-cache")
        CacheFilePath   = (Join-Path -Path $resourceDir -ChildPath "download-cache" -AdditionalChildPath $resourceFileName)

        ResourceDirPath = $resourceDir
        DestinationPath = $dstDir

        ResourceFileName = (Get-ResourceFileName $resource)
    }

    Write-DebugMessage "[~] container"
    Write-DebugMessage " - data: $container"

    Write-DebugMessage "[~] ensuring all dir paths"
    New-Folder  $container.StagingDirPath

    New-Folder  $container.LatestDirPath
    New-Folder  $container.CacheDirPath

    New-Folder  $container.ResourceDirPath
    New-Folder  $container.DestinationPath

    return $container
}

function Invoke-StagingDownload($resourceContainer) {

    Invoke-ResourceFolderDownload $resourceContainer  `
        $resourceContainer.Resource.uri `
        $resourceContainer.StagingFilePath
}

function Invoke-CacheDownload($resourceContainer) {

    Invoke-ResourceFolderDownload $resourceContainer  `
        $resourceContainer.Resource.uri `
        $resourceContainer.CacheFilePath
}

function Invoke-ResourceFolderDownload($resourceContainer, $src, $dst) {
    Write-InfoMessage "[~] checking if file was already downloaded"

    if( (Confirm-FileValidity $resourceContainer $dst) -eq $True) {

        if($resourceContainer.Force -eq $True) {
            Write-InfoMessage "[~] -force, existing file is ok but will download again"
        } else {
            Write-InfoMessage "[~] using existing file: checksum is ok"
            New-ChecksumFile $dst

            return
        }
    }

    Write-InfoMessage  "[~] downloading file"
    Write-DebugMessage " -dst: $dst"

    # download
    $preferredTool = Get-CommandOptionValue @("-t", "-tool") $null "wget"
    Invoke-DownloadFile `
        $src `
        $dst `
        $preferredTool

    # validate download
    Write-InfoMessage "[~] validating file checksum"
    if( (Confirm-FileValidity $resourceContainer $dst) -eq $True) {
        Write-DebugMessage "[+] checksum is ok"
    } else {
        throw "[!] checksum validation failed for file: $dst"
    }

    # create checksum file
    New-ChecksumFile $dst
}

function Invoke-LatestDownload($resourceContainer) {
    # move all from staging to /latest
    # make metadata json file so that client can lookup information about files

    $stagingDirPath = $resourceContainer.StagingDirPath
    $latestDirPath  = $resourceContainer.LatestDirPath

    # clean up latest
    Write-DebugMessage "[~] cleaning latest dir: $latestDirPath"
    Invoke-CleanFolder $latestDirPath

    Write-InfoMessage  "[~] moving /download-staging to /latest"
    Write-DebugMessage " - src: $stagingDirPath/*"
    Write-DebugMessage " - dsr: $latestDirPath"

    Move-Item "$stagingDirPath/*"  `
              $latestDirPath `
              -Force

    Write-InfoMessage  "[~] writing metadata"
    Write-LatestMetadata $resourceContainer
}

function Invoke-DownloadResource($resource, $dstDir, $force = $False) {

    $jsonString = $resource | ConvertTo-Json -depth 5
    Write-DebugMessage "Downloading JSON data:`n$jsonString"

    $resourceContainer = Get-ResourceContainer $resource $dstDir $force
    Write-DebugMessage "container: $($resourceContainer | ConvertTo-JSON -depth 5 )"

    switch($resourceContainer.ResourceType) {
        "uplift/http-file"                 {  return Invoke-DownloadResourceHttpFile $resourceContainer  }
        "uplift/ms-visualstudio-2017-dist" {  return Invoke-DownloadResourceVS17Dist $resourceContainer  }
        default { throw "Unknown resource type: $($resource.ResourceType)"}
    }

    return 0
}

function Invoke-DownloadResourceHttpFile($resourceContainer) {

    Write-DebugMessage "Downloading http resource"

    $shouldDownload = $true

    # latest exists?
    $latestStatus = Get-LatestStatus $resourceContainer

    if($latestStatus -eq $True) {
        if($resourceContainer.Force -eq $True) {
            Write-WarnMessage "[~] -force is set, /latest is OK but will download again"
            $shouldDownload = $True
        } else {
            Write-InfoMessage "[+] /latest is OK, won't download"
            $shouldDownload = $False
        }
    } else {
        Write-DebugMessage "[~] /latest is NOT OK, will download it"
    }

    if($shouldDownload) {
        # download to staging
        # check if anything in cache?
        # check and create checksums
        Invoke-StagingDownload $resourceContainer

        # move staging to latest
        # fill cache, store needed files in cache
        Invoke-LatestDownload $resourceContainer
    }

    Write-InfoMessage "[+] completed!"
}

function Invoke-ActionResourceDownload () {

    [System.ComponentModel.CategoryAttribute("ActionCommand")]
    [System.ComponentModel.DescriptionAttribute("Downloads resource file into local repository")]

    param(
        $commandOptions
    )

    $thirdOption = $commandOptions.Third

    if( [String]::IsNullOrEmpty($thirdOption) -eq $True ) {
        throw "A resource name is required. Try 7z-1805-x64 or 7z-1805-"
    }

    Write-DebugMessage "cmd option: $thirdOption"
    $resources   = Get-AllResourcesMatch $thirdOption

    $resourceCount = $resources.Count
    $resourceIndex = 0

    if($resourceCount -eq 0) {
        throw "Cannot find any resource matching name: $thirdOption"
    } else {
        Write-InfoMessage "Found $resourceCount resource(s) matching id: $thirdOption"
    }

    $repoFolderPath = Get-LocalRepositoryPath $commandOptions
    $errors = @{}

    foreach($resource in $resources) {
        $resourceIndex = $resourceIndex  + 1
        $resourceId    = $resource.id

        try {
            Write-InfoMessage "[$resourceIndex/$resourceCount] resource: $resourceId"

            $result = Invoke-DownloadResource $resource $repoFolderPath (Get-ForceStatus)
            Write-DebugMessage " - result: $result"
        } catch {
            Write-ErrorMessage "Error while downloading resource: $resourceId"
            Write-ErrorMessage $_

            $errors[$resourceId] = $_
        }
    }

    return $errors.Count

    return 0
}