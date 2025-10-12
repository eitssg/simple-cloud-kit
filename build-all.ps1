# PowerShell equivalent of build-all.sh

$ErrorActionPreference = 'Stop'

# Store script name for usage display
$ScriptName = $MyInvocation.MyCommand.Name

# Parse parameters manually since param keyword is causing issues
$NoDev = $false
$SkipTests = $false
$New = $false
$Publish = $false
$Package = $false
$Force = $false
$Help = $false
$h = $false

foreach ($arg in $args) {
    switch ($arg) {
        "-NoDev" { $NoDev = $true }
        "-SkipTests" { $SkipTests = $true }
        "-New" { $New = $true }
        "-Publish" { $Publish = $true }
        "-Package" { $Package = $true }
        "-Force" { $Force = $true }
        "-Help" { $Help = $true }
        "-h" { $h = $true }
        default { Write-Host "Unknown argument: $arg"; exit 1 }
    }
}

function Show-Usage {
    Write-Host @"
Usage: $ScriptName [-NoDev] [-SkipTests] [-New] [-Publish] [-Package] [-Force] [-h]

Options:
    -NoDev        Disable development mode (default is enabled: uv sync --all-extras)
    -SkipTests    Skip running tests (passed through; sub-builds will not execute pytest).
    -New          Recreate venvs in sub-builds (fresh .venv)
    -Publish      Run publish step in sub-builds at the end
    -Package      If .lambda exists, run package.sh to build Lambda bundle
    -Force        Force overwrite when publishing (passed to publish.ps1)
    -h, -Help     Show this help and exit.

Examples:
  $ScriptName
  $ScriptName -NoDev
  $ScriptName -Publish
  $ScriptName -Package
  $ScriptName -SkipTests
  $ScriptName -NoDev -SkipTests
  $ScriptName -New
  $ScriptName -Publish -Force
"@
}

function Get-DesiredPythonVersion {
    # Priority: env PYTHON_VERSION -> .python-version -> [project].requires-python -> default 3.12
    if ($env:PYTHON_VERSION) {
        return $env:PYTHON_VERSION
    }
    if (Test-Path ".python-version") {
        return (Get-Content ".python-version" | Select-Object -First 1).Trim()
    }
    if (Test-Path "pyproject.toml") {
        # Try PEP 621 requires-python
        $content = Get-Content "pyproject.toml" -Raw
        $match = [regex]::Match($content, 'requires-python\s*=\s*"([^"]+)"')
        if ($match.Success) {
            $req = $match.Groups[1].Value
            # Prefer 3.12 when allowed by the range (e.g., ">=3.11,<3.13")
            if ($req -match '3\.12') {
                return "3.12"
            }
            if ($req -match '>=3\.11' -and $req -match '<3\.13') {
                return "3.12"
            }
            # Exact pin (==3.x)
            $exactMatch = [regex]::Match($req, '==\s*([0-9]+\.[0-9]+)')
            if ($exactMatch.Success) {
                return $exactMatch.Groups[1].Value
            }
            # Fallback: first major.minor, but avoid choosing 3.11 by default
            $simpleMatch = [regex]::Match($req, '([0-9]+\.[0-9]+)')
            if ($simpleMatch.Success) {
                $simple = $simpleMatch.Groups[1].Value
                if ($simple -eq "3.11") {
                    return "3.12"
                }
                return $simple
            }
        }
        # No Poetry support; repository uses uv only
    }
    return "3.12"
}

function Test-PythonVersion {
    param (
        [string]$DesiredVersion
    )
    # Check if python command works and version matches
    try {
        $versionOutput = & python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
        if ($versionOutput -eq $DesiredVersion) {
            return $true
        }
    } catch {
        return $false
    }
    return $false
}

function Confirm-PythonVersionInstalled {
    param (
        [string]$DesiredVersion
    )
    # Prefer accepting current python first
    if (Get-Command python -ErrorAction SilentlyContinue) {
        if (Test-PythonVersion -DesiredVersion $DesiredVersion) {
            $currentVersion = & python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
            Write-Host "Using current Python ${currentVersion} (satisfies '$DesiredVersion')"
            return
        }
    }

    # Otherwise require uv to have the interpreter installed
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        try {
            & uv python find $DesiredVersion | Out-Null
            Write-Host "Resolved Python via uv (satisfies '$DesiredVersion')"
            return
        } catch {
            Write-Error "Required Python $DesiredVersion is not installed (uv). Install it with: uv python install $DesiredVersion"
            exit 1
        }
    }

    # Fallback strict check without uv
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $currentVersion = & python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
        if ($currentVersion -eq $DesiredVersion) {
            Write-Host "Using current Python ${currentVersion} (exact match)"
            return
        }
        Write-Error "Python $DesiredVersion required but current python is $currentVersion. Install with uv or adjust PATH."
        exit 1
    }
    Write-Error "uv not found and python not available to verify version. Please install uv or Python $DesiredVersion."
    exit 1
}

# Root-level Python version check (once)
$rootDesiredPy = Get-DesiredPythonVersion
Confirm-PythonVersionInstalled -DesiredVersion $rootDesiredPy

if ($h -or $Help) {
    Show-Usage
    exit 0
}

# if the file build-all.ps1 does not exist, return with error "Must be in main toolkit folder":
if (-not (Test-Path -Path "./build-all.ps1" -PathType Leaf)) {
    Write-Error "Must be in main toolkit folder"
    exit 1
}

# Function to build and package a project
function Build-AppComponent {
    param (
        [string]$Project,
        [string[]]$ForwardArgs
    )

    # Return if the project path cannot be found
    if (-not (Test-Path -Path $Project -PathType Container)) {
        Write-Host "Project $Project does not exist"
        return
    }

    # Change to the sub-project folder
    Push-Location -Path $Project

    try {
        Write-Host "`n`n--------------------------------------------"
        Write-Host "Building $Project"
        Write-Host "--------------------------------------------"

        # Per-module Python enforcement happens in build.ps1; no per-project check here

        # Execute the build with forwarded args
        if ($ForwardArgs) {
            & ..\build.ps1 @ForwardArgs
        } else {
            & ..\build.ps1
        }
    }
    finally {
        # Return to the original directory
        Pop-Location
    }
}

# Build the argument list to forward directly to build.ps1
$forwardArgs = @()
if ($NoDev) {
    $forwardArgs += "-NoDev"
}
if ($SkipTests) {
    $forwardArgs += "-SkipTests"
}
if ($New) {
    $forwardArgs += "-New"
}
if ($Publish) {
    $forwardArgs += "-Publish"
}
if ($Package) {
    $forwardArgs += "-Package"
}
if ($Force) {
    $forwardArgs += "-Force"
}

# Initialize a variable with a list of folders for regular projects. The lambda functions are dependent on the core-framework
# so use the same python version. AWS maximum lambda runtime is "python3.12"
$projects = @(
    "sck-core-framework"
    "sck-core-db"
    "sck-core-execute"
    "sck-core-report"
    "sck-core-runner"
    "sck-core-component"
    "sck-core-deployspec"
    "sck-core-invoker"
    "sck-core-organization"
    "sck-core-api"
    "sck-core-codecommit"
    "sck-core-cli"
    "sck-core-ai"
    "sck-core-docs"
)

foreach ($project in $projects) {
    Build-AppComponent -Project $project -ForwardArgs $forwardArgs
}

