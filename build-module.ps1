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

# deactivate virutal enivonrment if active
if ($env:VIRTUAL_ENV) {
    Write-Host "Deactivating virtual environment"
    deactivate
}

# Remove the .venv folder if it exists
if (Test-Path -Path ".venv" -PathType Container) {
    Write-Host "Removing virtual environment"
    Remove-Item -Path ".venv" -Recurse -Force
}

# if the .venv folder doesn't exist, create  with python -m venv .venv
if (-not (Test-Path -Path ".venv" -PathType Container)) {
    Write-Host "Creating virtual environment"
    python -m venv .venv
}

# Activate the virtual environment
Write-Host "Activating virtual environment"
. .venv/Scripts/Activate.ps1

Write-Host "We want python $version"
Write-Host "Active python version is: $(python --version)"

Write-Host "`nUpdating Poetry dependencies"
python -m pip -q install --upgrade pip
python -m pip -q install --upgrade poetry poetry-dynamic-versioning polib
poetry self add -q poetry-plugin-export

# Remove poetry.lock if it exists (this is temporary)
if (Test-Path -Path "poetry.lock" -PathType Leaf) {
    Remove-Item -Path "poetry.lock" -Force
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
