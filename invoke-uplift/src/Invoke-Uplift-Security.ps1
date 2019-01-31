
function Get-StringHash([String] $value, $checksumType = "SHA256")
{
    # https://gallery.technet.microsoft.com/scriptcenter/Get-StringHash-aa843f71

    $stringBuilder = New-Object System.Text.StringBuilder

    $alg = [System.Security.Cryptography.HashAlgorithm]::Create($checksumType)

    $alg.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($value)) | ForEach-Object{
        [Void]$stringBuilder.Append($_.ToString("x2"))
    }

    return $stringBuilder.ToString().ToUpper()
}

function Get-StringHashInner
{
    param(
        [Parameter(Mandatory = $true)]
        [String] $String,
        [String] $HashName = "SHA256"
    )

    $String = $String.Trim()

    # http://jongurgul.com/blog/get-stringhash-get-filehash/
    # https://gallery.technet.microsoft.com/scriptcenter/Get-StringHash-aa843f71

    $StringBuilder = New-Object System.Text.StringBuilder
    [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String)) `
        | ForEach-Object{
            [Void]$StringBuilder.Append($_.ToString("x2"))
        }

    return $StringBuilder.ToString().ToUpper()
}

function Get-StringHash([String] $String, $HashName = "SHA256")
{
    # check that it works at all

    if("356A192B7913B04C54574D18C28D46E6395428AB" -ne (Get-StringHashInner "1"  "SHA1" ) ) {
        throw "Get-StringHash() seems to be broken, incorrect hash for value '1'"
    }

    return Get-StringHashInner $String $HashName
}


function Confirm-ChecksumFileFilePath($dstFolder, $checksumType, $checksum) {
    $fileName = "$checksumType-$checksum".ToUpper()

    return (Join-Path -Path $dstFolder -ChildPath $fileName)
}

function Get-Checksum($filePath, $checksum, $checksumType) {

    Write-DebugMessage "Calculating checksum:"
    Write-DebugMessage " - filePath : $filePath"
    Write-DebugMessage " - checksum : $checksum"
    Write-DebugMessage " - checksumType: $checksumType"

    $checksumCacheExists = Validate-ChecksumFile $filePath $checksumType $checksum

    if($checksumCacheExists -eq $True)  {
        Write-DebugMessage "[+] Checksum cache exists, skipping checksum calculation"

        return New-Object PSObject -Property @{
            Result = $true
            Hash   = $checksum.ToUpper()
        }
    } else {
        Write-DebugMessage "[-] Checksum cache does not exist, will calculate checksum again (might take a long time)"
    }

    $fileChecksum = Get-FileHash -Algorithm $checksumType $filePath

    if($fileChecksum.Hash -eq $checksum.ToUpper()) {
        return New-Object PSObject -Property @{
            Result = $true
            Hash   = $fileChecksum.Hash.ToUpper()
        }
    }

    return New-Object PSObject -Property @{
        Result = $false
        Hash   = $fileChecksum.Hash.ToUpper()
    }
}
