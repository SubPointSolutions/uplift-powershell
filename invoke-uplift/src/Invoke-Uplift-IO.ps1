function New-Folder {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    param(
        $folder
    )

    if(!(Test-Path $folder))
    {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
}

function Invoke-CleanFolder {
    param(
        $path
    )

    Remove-Item "$path/*" `
        -Force `
        -Recurse `
        -ErrorAction SilentlyContinue
}