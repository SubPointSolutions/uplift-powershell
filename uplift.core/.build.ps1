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

$moduleName = "Uplift.Core"

. "$dirPath/../_shared/.build-helpers.ps1"
. "$dirPath/../_shared/.build.ps1"

task PrepareResourceFiles -After PrepareModule {

    Copy-Item "$dirPath/src/Uplift.AppInsights.ps1" "$moduleFolder/$moduleName/"

}