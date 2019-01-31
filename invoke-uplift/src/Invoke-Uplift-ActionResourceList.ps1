
function Invoke-ActionResourceList () {
    param(
        $commandOptions
    )

    # resource match prefix
    $thirdOption = $commandOptions.Third
    $isDetailed  = Get-CommandOptionValue @("-detailed", "-details") $commandOptions

    $resources   = Get-AllResourcesMatch $thirdOption

    $resourceIds = $resources | `
        Select-Object `
            -Property id `
            -ExpandProperty id

    $resourceCount = $resources.Count
    # $resourceIndex = 0

    if($resourceCount -eq 0) {
        Write-WarnMessage "Found no *.resource.json files."
    }
    else {
        $resourceMessage = ""

        if($isDetailed -eq $True) {
            $prefix = " - "

            $resourceMessage = ($prefix + [String]::Join(
                ([Environment]::NewLine + $prefix),
                (
                    $resources | ForEach-Object {
                        return [String]::Join([Environment]::NewLine,
                            $_.id,
                            "    src: " + $_.uri,
                            "    cmd: invoke-uplift resource download $($_.id)",
                            "    loc: invoke-uplift resource download-local $($_.id)",
                            ""
                        )
                    }
                )
            ))

        } else {
            $prefix = " - "
            $resourceMessage = ($prefix + [String]::Join(
                ([Environment]::NewLine + $prefix),
                $resourceIds
            ))
        }

        Write-InfoMessage ([String]::Join([Environment]::NewLine, @(
            "found $resourceCount resources:",
            $resourceMessage
        )))
    }

    return 0
}