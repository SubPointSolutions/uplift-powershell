

function Write-LogMessage {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]
    param(
        $message,
        $level,
        $loggerName = "uplift"
    )

    if($level -ieq "RAW")  {
        Write-Host $message
        return
    }

    $stamp = $(get-date -f "yyyy-MM-dd HH:mm:ss.fff")

    # asking for debug trace but log level is no-debug, returning
    if( ($level -ieq "debug") -and ($ENV:UPLF_LOG_LEVEL -ine "debug") ) {
        return;
    }

    # custom logger name
    if($null -ne $ENV:UPLF_LOG_NAME) {
        $loggerName = $ENV:UPLF_LOG_FORMAT
    }

    # no color flag?
    $noColor = $null -ne $ENV:UPLF_LOG_NO_COLOR

    # log format, time is a default one
    $logFormat = $ENV:UPLF_LOG_FORMAT
    if($null -eq $logFormat) { $logFormat = "time" }

    $messageColor = "White"

    if($level -ieq "INFO")  { $messageColor = "Green" }
    if($level -ieq "DEBUG") { $messageColor = "Blue"; }
    if($level -ieq "ERROR") { $messageColor = "Red" }
    if($level -ieq "WARN")  { $messageColor = "Yellow" }

    # aligning all level messages
    $level = $level.PadRight(5)

    # add right shift for all [+], [-] or [~]
    if( ($null -ne $message  ) -and `
        ( ($message.StartsWith("[+]") -eq $True) `
            -or ($message.StartsWith("[-]") -eq $True) `
            -or ($message.StartsWith("[~]") -eq $True) )
      ) {
        $message = " $message"
    }

    # default is just a message
    $logMessage = [String]::Join(" : ", @(
        $message
    ))

    # custom log message layouts
    switch($logFormat) {
        "short" {
            $logMessage = [String]::Join(" : ", @(
                $message
            ))
        }

        "time" {
            $logMessage = [String]::Join(" : ", @(
                $stamp,
                $message
            ))
        }

        "full" {
            # use [environment]::UserDomainName / [environment]::UserName
            # $env:USERDOMAIN won't work on non-windows platforms

            $logMessage = [String]::Join(" : ", @(
                $loggerName,
                $stamp,
                $level,
                "$([environment]::UserDomainName)/$([environment]::UserName)",
                $message
            ))
        }
    }

    if($noColor -eq $True) {
        Write-Host $logMessage
    } else {
        Write-Host $logMessage `
            -ForegroundColor $messageColor
    }
}

function Write-InfoMessage($message) {
    Write-LogMessage "$message" "INFO"
}

function Write-DebugMessage($message) {
    Write-LogMessage "$message" "DEBUG"
}

function Write-WarningMessage($message) {
    Write-LogMessage "$message" "WARN"
}

function Write-WarnMessage($message) {
    Write-WarningMessage $message
}

function Write-ErrorMessage($message) {
    Write-LogMessage "$message" "ERROR"
}

function Write-RawMessage($message) {
    Write-LogMessage "$message" "RAW"
}