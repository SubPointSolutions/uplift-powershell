

function Invoke-ToolCmd($fileName, $arguments) {

    Write-DebugMessage "Tool: $fileName"
    Write-DebugMessage "Arguments: $arguments"

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "$fileName"

    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true

    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $arguments

    $p = New-Object System.Diagnostics.Process

    $p.StartInfo = $pinfo

    Write-DebugMessage "Started process: $fileName"
    $p.Start() | Out-Null

    Write-DebugMessage "Waiting for exit..."
    $p.WaitForExit()

    Write-DebugMessage "Started process: $fileName"
    Write-DebugMessage "ExitCode: $($p.ExitCode)"

    return $p.ExitCode
}

function Get-DownloadToolAvialablity() {

    $wgetToolName = "wget";
    $curlToolName = "curl";

    if($IsWindows -eq $True) {
        $wgetToolName = "wget.exe";
        $curlToolName = "curl.exe";
    }

    $result =  New-Object PsObject -Property @{
        wget = @{
            ToolName = $wgetToolName
            IsAvailable = ($null -ne (Get-ToolCmd $wgetToolName) )
        }

        curl = @{
            ToolName = $curlToolName
            IsAvailable = ($null -ne (Get-ToolCmd $curlToolName) )
        }
    }

    return $result;
}

function Invoke-DownloadFileAsWget($tool, $src, $dst) {

    # https://www.pair.com/support/kb/paircloud-downloading-files-with-wget/

    Write-DebugMessage 'Runnig wget'

    $cmdString = "-O $dst $src --quiet"
    $exitCode  = Invoke-ToolCmd $tool.ToolName $cmdString

    if($exitCode -ne 0) {
        throw "Cannot download file using wget.exe, exit code: $exitCode"
    }
}

function Invoke-DownloadFileAsCurl($tool, $src, $dst) {
   # http://www.compciv.org/recipes/cli/downloading-with-curl/

   Write-DebugMessage 'Runnig curl'

   $cmdString = " ""$src"" --output ""$dst"" --silent"
   $exitCode = Invoke-ToolCmd $tool.ToolName $cmdString

   if($exitCode -ne 0) {
       throw "Cannot download file using curl.exe, exit code: $exitCode"
   }
}

function Invoke-DownloadFileAsInvokeWebRequest($src, $dst) {

    Write-WarningMessage "[~] Downloading using Invoke-RestMethod"
    Write-WarningMessage "    - might not work in large files producing malformed downloads"
    Write-WarningMessage "    - install curl or wget"

    Write-DebugMessage "Downloading $src"

    # disable progress, it is also much faster!
    # https://stackoverflow.com/questions/18770723/hide-progress-of-invoke-webrequest

    $oldProgressPreference = $progressPreference
    $progressPreference = 'silentlyContinue'

    try {
        $oldProgressPreference = $progressPreference

        # download to file
        # always use UseBasicParsing, won't fail on bare new win VM after sysprep

        Invoke-WebRequest -Uri $src `
                    -OutFile $dst `
                    -MaximumRedirection 10 `
                    -UseBasicParsing
    } finally {
        $progressPreference = $oldProgressPreference
    }
}

function Invoke-UrlAvialabilityCheck($src) {

    # https://stackoverflow.com/questions/20259251/powershell-script-to-check-the-status-of-a-url

    Write-DebugMessage "[~] Checking URL availability: $src"

    $result = Invoke-WebRequest -Uri $src `
        -UseBasicParsing `
        -DisableKeepAlive `
        -Method HEAD

    if($result.StatusCode -eq 200) {
        Write-DebugMessage "[+] StatusCode: $($result.StatusCode)"
    } else {
        Write-ErrorMessage "[!] StatusCode: $($result.StatusCode), expected 200!"
    }

    return (
        ($null -ne $result ) -and ($result.StatusCode -eq 200)
    )
}

function Invoke-DownloadFile($src, $dst, $preferredTool = $null) {

    try {
        $tools = Get-DownloadToolAvialablity

        # check is file evem available?
        # HEAD must return 200

        if( (Invoke-UrlAvialabilityCheck $src) -eq $false) {
            throw "Cannot validate url, got non-200 result"
        }

        if($null -ne $preferredTool) {

            # using preferred tool
            $preferredToolValue = $preferredTool.ToLower()
            Write-DebugMessage "Using preferred tool: $preferredToolValue"

            if( $preferredToolValue -ilike "*wget*"  ) {
                if( $tools.wget.IsAvailable -eq $True) {
                    Invoke-DownloadFileAsWget $tools.wget $src $dst
                    return
                } else {
                    throw "Preferred tool is not available: $preferredToolValue"
                }
            } elseif( $preferredToolValue -ilike "*curl*"  ) {
                if( $tools.curl.IsAvailable -eq $True) {
                    Invoke-DownloadFileAsCurl $tools.curl $src $dst
                    return
                } else {
                    throw "Preferred tool is not available: $preferredToolValue"
                }
            } elseif( $preferredToolValue -ilike "*InvokeWebRequest*"  ) {
                Invoke-DownloadFileAsInvokeWebRequest $tools.curl $src $dst
                return
            }
            else {
                throw "Preferred tool is not supported: $preferredToolValue"
            }

        } else {
            # cascading wget -> curl -> InvokeWebRequest
            Write-DebugMessage "No preferred tool is set, cascading: wget -> curl -> InvokeWebRequest"

            # is wget available?
            if( $tools.wget.IsAvailable -eq $True) {
                Invoke-DownloadFileAsWget $tools.wget $src $dst
                return
            }

            # is curl available?
            if( $tools.curl.IsAvailable -eq $True) {
                Invoke-DownloadFileAsCurl $tools.curl $src $dst
                return
            }

            # default is  Invoke-WebRequest
            # might not work well with large files

            Invoke-DownloadFileAsInvokeWebRequest $src $dst
        }


    } catch {
        Write-ErrorMessage "Error while downloading file: $($_.Exception)"
        Write-ErrorMessage $_.Exception

        throw $_
    }
}