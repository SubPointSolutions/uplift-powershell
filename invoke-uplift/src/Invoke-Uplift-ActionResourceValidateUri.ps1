

function Invoke-ActionResourceValidate-Uri() {
    [System.ComponentModel.CategoryAttribute("ActionCommand")]
    [System.ComponentModel.DescriptionAttribute("Validates resources uri, expects 200 HTTP responce")]

    param(
        $commandOptions
    )

    $resources   = Get-AllResourcesMatch $commandOptions.Third

    $resourceCount = $resources.Count
    $resourceIndex = 0

    Write-InfoMessage "Validating resources, HTTP HEAD agasint uri, expecting 200"

    $errors = @{}

    foreach($resource in $resources) {
        $resourceIndex = $resourceIndex  + 1

        $resourceId    = $resource.id
        $resourceUri   = $resource.uri

        try {
            Write-InfoMessage "[$resourceIndex/$resourceCount] resource: $resourceId - $resourceUri"

            if( (Invoke-UrlAvialabilityCheck $resourceUri) -eq $false) {
                throw "[-] non-200 result on uri: $($resourceUri)"
            }
        } catch {
            Write-ErrorMessage "Error while validating resource: $resourceId"
            Write-ErrorMessage $_

            $errors[$resourceId] = $_
        }
    }

    return $errors.Count
}