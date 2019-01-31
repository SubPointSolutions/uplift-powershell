function Get-ToolCmd($name) {

    Write-DebugMessage "Detecting presense: $name"

    $cmd = (Get-Command $name -ErrorAction SilentlyContinue)
    Write-DebugMessage "`t- result: $($null -ne $cmd)"

    return $cmd
}