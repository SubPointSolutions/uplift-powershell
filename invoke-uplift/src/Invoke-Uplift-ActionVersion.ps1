function Invoke-ActionVersion {
    [System.ComponentModel.CategoryAttribute("Action")]
    [System.ComponentModel.DescriptionAttribute("Shows current version")]
    param(
        $commandOptions
    )

    Write-RawMessage "uplift v$(Get-UpliftVersion)"

    return 0
}