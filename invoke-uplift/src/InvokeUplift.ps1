$ErrorActionPreference = "Stop"

# avoid global pollution
# wrap a function, perform all actions, then return the exit code

function Invoke-TheUplifter42($options) {

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

    try
    {
        $commandOptions        = Invoke-CommandOptionsParse $options
        $script:CommandOptions = $commandOptions

        Write-DebugMessage "Running with options: `r`n$($commandOptions | ConvertTo-Json -Depth 3)"

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

        return 1
    }
}

exit (Invoke-TheUplifter42 $args)