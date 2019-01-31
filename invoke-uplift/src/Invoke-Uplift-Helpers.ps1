

function Confirm-LocalFileValidity($filePath) {

    Write-DebugMessage "Checking local file validity: $filePath"

    if( (Test-Path $filePath) -eq $False) {
        Write-DebugMessage " - false, local path does not exist: $filePath"
        return $False
    }

    # lookup first .sha256 file in folder
    if( (Get-Item $filePath) -is [System.IO.DirectoryInfo] ) {

        Write-DebugMessage " - ~, checking folder: $filePath"

        # two files and one of them .sha256?
        $filesCount = @(Get-ChildItem $localStagingFolder).Count;

        if($filesCount -eq 2) {
            Write-DebugMessage " - ~, found two files, looing for *.sha256 file"

            $filePath  = (Resolve-Path "$filePath/*.sha256").Path
            Write-DebugMessage " - ~, found: $filePath"

            $filePath = $filePath.Replace(".sha256", "")
            $fileName    = Split-Path $filePath -Leaf
        } else {
            # folder has more files, this mush be a bunch of files packaged into a zip folder
            Write-DebugMessage " - true, skipping, found folder full of files: $filePath"

            return $True
        }

    } else {
        $checksumFilePath = $filePath + ".sha256"

        if( (Test-Path $checksumFilePath) -eq $False) {
            Write-DebugMessage " - false, local checksum path does not exist: $checksumFilePath"
            return $False
        }

        $fileName = Split-Path $filePath -Leaf
    }

    Write-DebugMessage "checking checksum"
    Write-DebugMessage " - file    : $filePath"
    Write-DebugMessage " - checksum: $filePath.sha256"

    $hash        = (Get-FileHash -Algorithm SHA256 $filePath).Hash
    $content     = Get-Content "$($filePath).sha256"

    $contentHash = $content.Split("  ", [System.StringSplitOptions]::RemoveEmptyEntries)[0]
    $contentFile = $content.Split("  ", [System.StringSplitOptions]::RemoveEmptyEntries)[1]

    Write-DebugMessage "expected: $contentHash"
    Write-DebugMessage "was     : $hash"

    return (($hash -ieq $contentHash) -and ($fileName -ieq $contentFile))
}

function Confirm-FileValidity($resourceContainer, $filePath) {

    Write-DebugMessage "[~] checking file validity"

    # does cache file exist and checksum actually match?
    $fileExist = (Test-Path $filePath)

    if( $fileExist -eq $False) {
        Write-DebugMessage "[-] file does not exist:  $fileExist"
        return $False
    }

    $expectedChecksum      = $resourceContainer.Resource.checksum
    $expectedChecksumType  = $resourceContainer.Resource.checksum_type

    $currentChecksum      = Get-FileHash -Algorithm $expectedChecksumType $filePath
    $currentChecksumValue = $currentChecksum.Hash

    $fileChecksumValid = ($currentChecksumValue -ieq $expectedChecksum)

    if( $fileChecksumValid -eq $False) {
        Write-WarnMessage "[-] file checksum is incorrect:  $filePath"
        Write-WarnMessage "[-] expected: $expectedChecksumType $expectedChecksum"
        Write-WarnMessage "[-] current : $expectedChecksumType $currentChecksumValue"

        return $False
    }

    Write-DebugMessage "[-] file checksum is ok:  $filePath"
    Write-DebugMessage "[-] expected: $expectedChecksumType $expectedChecksum"
    Write-DebugMessage "[-] current : $expectedChecksumType $currentChecksumValue"

    return $True
}