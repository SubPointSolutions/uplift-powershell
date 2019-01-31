

function Invoke-ActionHelp {
    [System.ComponentModel.CategoryAttribute("Action")]
    [System.ComponentModel.DescriptionAttribute("Shows help")]
    param(
        $options
    )

    $result = Invoke-ActionVersion | Out-Null

    $actionFunctions = Get-AvailableActions
    Write-CommandHelp $actionFunctions

    $result = 0

    return $result
}