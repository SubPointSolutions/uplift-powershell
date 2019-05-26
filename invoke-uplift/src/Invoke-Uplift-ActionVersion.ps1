function Invoke-ActionVersion {
    [System.ComponentModel.CategoryAttribute("Action")]
    [System.ComponentModel.DescriptionAttribute("Shows current version")]
    param(
        $commandOptions
    )

    $isSilent = Get-CommandOptionValue @("-json", "-silent") $commandOptions

    if($isSilent -eq $False) {
        Write-RawMessage "uplift v$(Get-UpliftVersion)"
    }

    return 0
}