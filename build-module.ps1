# Powershell

# take in one parameter called "type" and default to "module"
param (
    [string]$type = "module"
)

Write-Host "Building module type: $type"

# if the file pyproject.toml does not exist, return with error "Must be in project folder":
if (-not (Test-Path -Path "./pyproject.toml" -PathType Leaf)) {
    Write-Host "Must be in project folder"
    return
}

# Source and execute the build script
. ..\build.ps1

# Source and execute the flakeit script
. ..\flakeit.ps1

# Source and execute the pytest script
. ..\pytest.ps1

# Source and execute the publish script
. ..\publish.ps1

if ($type -eq "lambda") {

    # Source and execute the package script
    . ..\package.ps1
}
