param(
    [switch]$NoDev,
    [switch]$SkipTests,
    [switch]$New,
    [switch]$Package,
    [switch]$Publish,
    [switch]$Force,
    [switch]$Help
)

# Store script name for usage display
$ScriptName = $MyInvocation.MyCommand.Name

function Show-Usage {
    Write-Host @"
Usage: $ScriptName [-NoDev] [-SkipTests] [-New] [-Package] [-Publish] [-Force] [-Help]

Options:
  -NoDev        Disable development mode (default is enabled: uv sync --all-extras)
  -SkipTests    Skip running tests
  -New          Recreate venv (.venv) before install
  -Package      If .lambda exists, run package.ps1 to build Lambda bundle
  -Publish      Run publish step after build/tests
  -Force        Force overwrite when publishing
  -Help         Show this help and exit.
"@
}

if ($Help) {
    Show-Usage
    exit 0
}

# Determine desired Python version for this module
function Get-DesiredPythonVersion {
    if ($env:PYTHON_VERSION) {
        return $env:PYTHON_VERSION
    }
    if (Test-Path ".python-version") {
        return (Get-Content ".python-version" | Select-Object -First 1).Trim()
    }
    if (Test-Path "pyproject.toml") {
        $req = Select-String -Path "pyproject.toml" -Pattern '^\s*requires-python\s*=' | Select-Object -First 1
        if ($req) {
            $req = $req.Line -replace '.*"([^"]+)".*', '$1'
            if ($req -match '3\.12') { return "3.12" }
            if ($req -match '>?=\s*3\.11' -and $req -match '<\s*3\.13') { return "3.12" }
            $exact = [regex]::Match($req, '==\s*([0-9]+\.[0-9]+)').Groups[1].Value
            if ($exact) { return $exact }
            $simple = [regex]::Match($req, '([0-9]+\.[0-9]+)').Groups[1].Value
            if ($simple -eq "3.11") { return "3.12" }
            if ($simple) { return $simple }
        }
    }
    return "3.12"
}

function Test-PythonVersionInstalled {
    param([string]$Desired)
    Write-Host "Desired Python version: $Desired"
    & uv run ../test-python.py $Desired
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Python $Desired is not installed. Aborting..."
        exit 1
    }
    Write-Host "Python $Desired is installed."
}

# Exit if the python command cannot be found
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Python could not be found"
    exit 1
}

# Get the current folder name
$packageName = (Get-Item -Path ".\").Name

# Force deactivate any active virtual environment to avoid confusing uv
if ($env:VIRTUAL_ENV) {
    if (Get-Command deactivate -ErrorAction SilentlyContinue) {
        deactivate
    } else {
        # Fallback: manually unset venv vars
        $env:VIRTUAL_ENV = $null
        $env:PATH = ($env:PATH -split ';' | Where-Object { $_ -notlike '*\.venv\*' }) -join ';'
    }
}

# if the file pyproject.toml does not exist, return with error "Must be in project folder":
if (-not (Test-Path -Path "./pyproject.toml" -PathType Leaf)) {
    Write-Host "Must be in project folder"
    exit 1
}

if (($env:NEW -eq "1") -or $New) {
    Write-Host "Recreating virtual env"
    # Use uv venv --clear to remove and recreate
    uv venv --clear --python $desiredPy
} else {
    # if the .venv folder does not exist, create it (prefer uv-located interpreter when available)
    if (-not (Test-Path -Path ".venv" -PathType Container)) {
        if (Get-Command uv -ErrorAction SilentlyContinue) {
            # Use uv to create venv with the desired Python
            uv venv --python $desiredPy
        } else {
            python -m venv .venv
        }
    }
}

# Note: With uv, we don't need to activate the venv explicitly; uv manages environments

# Check if the virtual environment is activated and show only the version and source folder and do not show titles
Write-Host "`n---- Python version and source folder"
$pythonVersion = uv run python --version 2>&1
$pythonSource = uv run python -c "import sys; print(sys.executable)" 2>&1
Write-Host "Version: $pythonVersion"
Write-Host "Source: $pythonSource"

$version = uv version --short

Write-Host "`n---- BUILDING project: $packageName v${version}"

# Remove the dist folder if it exists
if (Test-Path -Path "dist" -PathType Container) {
    Remove-Item -Path "dist" -Recurse -Force
}

# Remove the build folder if it exists
if (Test-Path -Path "build" -PathType Container) {
    Remove-Item -Path "build" -Recurse -Force
}

Write-Host "`n---- Installing the project and dependencies using UV"

# Install project dependencies
if (-not $NoDev) {
    Write-Host "Installing with DEVELOPMENT tools"
    uv sync --all-extras
} else {
    uv sync
}

Write-Host "`n---- Building the distribution files for project: $packageName v${version}"

uv build

$distPath = "../sck-core-docker/dist"
if (-not (Test-Path -Path $distPath -PathType Container)) {
    New-Item -ItemType Directory -Path $distPath | Out-Null
}

$filePrefix = $packageName -replace '-', '_'

# if the dist folder contains files with the project prefix remove them
Get-ChildItem -Path $distPath -File | Where-Object { $_.Name -like "$filePrefix*" } | Remove-Item -Force

# Copy the files from the dist folder to the destination folder
Get-ChildItem -Path "dist" -File | ForEach-Object {
    $destinationPath = Join-Path -Path $distPath -ChildPath $_.Name
    Copy-Item -Path $_.FullName -Destination $destinationPath -Force
}
Write-Host "`n---- Distribution files copied to $distPath"
Write-Host "`n---- Build complete for project: $packageName v${version}"

# Static checks when dev is enabled (default)
if (-not $NoDev) {
    # Lint/format gate
    if (Test-Path "../flakeit.ps1") {
        . ..\flakeit.ps1
    }
}

# Tests when dev is enabled (default) and not skipped
if (-not $NoDev -and -not $SkipTests) {
    if (Test-Path "../pytest.ps1") {
        . ..\pytest.ps1
    }
}

# if the file .lambda exists then execute package.ps1 script
if ((Test-Path -Path ".\.lambda" -PathType Leaf) -and $Package) {
    . ..\package.ps1
}

# Publish only when requested
if ($Publish) {
    if (Test-Path "../publish.ps1") {
        if ($Force) {
            . ..\publish.ps1 -Force
        } else {
            . ..\publish.ps1
        }
    }
}