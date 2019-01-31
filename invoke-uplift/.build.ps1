param(
    # build params
    $buildVersion = $null,
    
    # publishing params
    $publishRepoName            = $null,
    $publishRepoSourceLocation  = $null,
    $publishRepoPublishLocation = $null,
    $publishRepoNuGetApiKey     = $null,

    # QA params
    $QA_FIX = $null
)

$dirPath    = $BuildRoot
$scriptPath = $MyInvocation.MyCommand.Name

$moduleName = "InvokeUplift"

. "$dirPath/../_shared/.build-helpers.ps1"
. "$dirPath/../_shared/.build.ps1"

task PrepareResourceFiles -After PrepareModule {

    New-Item "$moduleFolder/$moduleName/resource-files" -ItemType directory -Force | Out-Null
    Copy-Item "$dirPath/src/resource-files/*" "$moduleFolder/$moduleName/resource-files/"

}