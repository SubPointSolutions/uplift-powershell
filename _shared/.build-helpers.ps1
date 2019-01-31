function Edit-ValueInFile($path, $old, $new) {
    (Get-Content $path).replace( $old, $new ) `
        | Set-Content $path
}

function Confirm-ExitCode($code, $message)
{
    if ($code -eq 0) {
        Write-Build Green "Exit code is 0, continue..."
    } else {
        $errorMessage = "Exiting with non-zero code [$code] - $message" 

        Write-Build Red  $errorMessage 
        throw  $errorMessage 
    }
}

function Confirm-Variable($name, $value, $description) {

    # value ok?
    if($null -ne $value) {
        return 
    }

     # it is ENV variable?
    if($null -ne  [System.Environment]::GetEnvironmentVariable($name) ) {
        return 
    }

    throw "Variable $name is null: $description"
}

function New-UpliftPSRepository {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    
    param(
        $name,
        $source,
        $publish = $null,
        $installPolicy = "Trusted"
    )

    $repo = Get-PSRepository `
        -Name $name `
        -ErrorAction SilentlyContinue

    if($null -eq $repo) {
        Write-Build Green " [~] Regestering repo: $name"
        Write-Build Green " - SourceLocation: $source"

        if($null -eq $publish) {
            Write-Build Green " - PublishLocation: $source"

            Register-PSRepository -Name $name `
                -SourceLocation $source `
                -InstallationPolicy $installPolicy
        } else {
            Write-Build Green " - PublishLocation: $publish"

            Register-PSRepository -Name $name `
                -SourceLocation $source `
                -PublishLocation $publish `
                -InstallationPolicy $installPolicy
        }
    } else {
        Write-Build Green "Repo exists: $name"
    }
}