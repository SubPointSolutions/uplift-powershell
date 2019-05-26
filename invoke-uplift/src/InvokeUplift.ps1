$ErrorActionPreference = "Stop"

# avoid global pollution
# wrap a function, perform all actions, then return the exit code

function Invoke-TheUplifter42($options) {

    # include telemetry helper
    . "$PSScriptRoot/Uplift.AppInsights.ps1"

    # include core fucntions, then logger, and other utils
    . "$PSScriptRoot/Invoke-Uplift-Core.ps1"

    . "$PSScriptRoot/Invoke-Uplift-Log.ps1"

    . "$PSScriptRoot/Invoke-Uplift-OS.ps1"
    . "$PSScriptRoot/Invoke-Uplift-IO.ps1"

    . "$PSScriptRoot/Invoke-Uplift-HTTP.ps1"
    . "$PSScriptRoot/Invoke-Uplift-Security.ps1"

    # helpers
    . "$PSScriptRoot/Invoke-Uplift-Helpers.ps1"

    # include command handlers
    . "$PSScriptRoot/Invoke-Uplift-ActionVersion.ps1"
    . "$PSScriptRoot/Invoke-Uplift-ActionHelp.ps1"

    . "$PSScriptRoot/Invoke-Uplift-ActionResource.ps1"
    . "$PSScriptRoot/Invoke-Uplift-ActionServe.ps1"

    # handling null array, call without any parameters
    if($null -eq $options) {
        $options = @()
    }

    # 0.1.0 gets patched by the builds process
    # don't move this anywhere
    function Get-UpliftVersion() {
        return '0.1.0'
    }

    $cmdElapsedMilliseconds = $null

    $cmdStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $cmdException = $null

    $cmdName    = ""
    $cmdOptions = @()

    $cmdCommandOptions = $null

    try
    {
        $commandOptions        = Invoke-CommandOptionsParse $options
        $cmdCommandOptions     = $commandOptions

        $script:CommandOptions = $commandOptions

        Write-DebugMessage "Running with options: `r`n$($commandOptions | ConvertTo-Json -Depth 3)"

        $cmdName    = $commandOptions.First
        $cmdOptions = $options

        switch($commandOptions.First)
        {
            "help"     { return (Invoke-ActionHelp      $commandOptions) }
            "version"  { return (Invoke-ActionVersion   $commandOptions) }

            "resource" { return (Invoke-ActionResource  $commandOptions) }

            "serve"    { return (Invoke-ActionServe     $commandOptions) }

            default    { return (Invoke-ActionHelp      $commandOptions) }
        }
    } catch {
        Write-ErrorMessage "General error: $($_.Exception)"
        Write-ErrorMessage $_.Exception

        $cmdException = $_

        return 1
    } finally {

        $cmdStopwatch.Stop()
        $cmdElapsedMilliseconds = $cmdStopwatch.ElapsedMilliseconds

        # update telemetry
        try {
            Confirm-UpliftUpliftAppInsightClient

            # masked values
            $maskedValues = @(
                [string](Get-CommandOptionValue @("-r", "-repository") $options)
            )

            $cmdCommandOptionValue = [String]::Join(" ", $cmdOptions)

            foreach($maskedValue in $maskedValues) {
                if([string]::IsNullorEmpty($maskedValue) -eq $True) { continue; }

                $cmdCommandOptionValue = $cmdCommandOptionValue.Replace($maskedValue, '*****')
            }

            $eventHash =  @{
                "cmd_version" = (Get-UpliftVersion)
                "cmd_name"    = $cmdName
                "cmd_elapsed" = $cmdElapsedMilliseconds
                "cmd_options" = $cmdCommandOptionValue
            }

            if($null -ne $cmdCommandOptions) {
                $eventHash["cmd_option_first"]  = $cmdCommandOptions.First
                $eventHash["cmd_option_second"] = $cmdCommandOptions.Second
                $eventHash["cmd_option_third"]  = $cmdCommandOptions.Third
            }

            $eventProps = New-UpliftAppInsighsProperties $eventHash

            if($null -ne $cmdException) {
                $eventProps.Add("cmd_error", $cmdException.ToString())
            }

            New-UpliftTrackEvent "uplift-invoke" $eventProps

            if($null -ne $cmdException) {
                New-UpliftTrackException $cmdException.Exception $eventProps $null
            }

        } catch {
            Write-WarnMessage "[!] Cannot use AppInsight, please report this error or use UPLF_NO_APPINSIGHT env variable to disable it."
            Write-WarnMessage "[!] $_"
        }
    }
}

exit (Invoke-TheUplifter42 $args)