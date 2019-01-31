

# Big list of http static server one-liners · GitHub
# https://gist.github.com/willurd/5720255

function Confirm-ToolAvailability($toolName, $helperMessage = $null) {
    $isToolAvailable = ($null -ne (Get-ToolCmd $toolName))

    if($isToolAvailable -eq $False) {

        $errorMessage = "Cannot find tool: $toolName, please install and make it available in the path"

        if($null -ne $helperMessage) {
            $errorMessage += ", $helperMessage"
        }

        throw $errorMessage
    }
}

function Invoke-ActionServeAsNodeHttpServer($path, $port) {

    # npm install http-server -g
    # https://github.com/indexzero/http-server

    Confirm-ToolAvailability "http-server" "npm install http-server -g"

    if([String]::IsNullOrEmpty($port) -eq $True) {

        Write-DebugMessage "cd $path ; http-server"
        pwsh -c "cd $path; http-server"

    } else {

        Write-DebugMessage "cd $path ; http-server -p $port"
        pwsh -c "cd $path; http-server -p $port"
    }
}

function Invoke-ActionServe {
    [System.ComponentModel.CategoryAttribute("Action")]
    [System.ComponentModel.DescriptionAttribute("Starts http web server for local respository")]
    param(
        $commandOptions
    )

    $result = Invoke-ActionVersion

    $path     = Get-LocalRepositoryPath $commandOptions
    $port     = Get-CommandOptionValue @("-p", "-port")     $commandOptions 8080
    $toolName = Get-CommandOptionValue @("-t", "-tool") $commandOptions "http-server"

    Write-InfoMessage "[~] Starting http server for repository"

    Write-InfoMessage " - tool : $toolName"

    if([String]::IsNullOrEmpty($port) -eq $True) {
        throw "-p or -port option is required"
    } else {
        Write-InfoMessage " - port : $port"
    }

    Write-InfoMessage " - path : $path"

    switch($toolName) {
        "http-server"   { return Invoke-ActionServeAsNodeHttpServer $path $port }

        default {
            throw "unsupported tool: $toolName"
        }
    }

    $result = 0

    return $result
}