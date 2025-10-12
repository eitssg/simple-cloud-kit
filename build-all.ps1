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
        # Build the command string dynamically
        $cmd = "..\build.ps1"
        if ($NoDev) { $cmd += " -NoDev" }
        if ($SkipTests) { $cmd += " -SkipTests" }
        if ($New) { $cmd += " -New" }
        if ($Publish) { $cmd += " -Publish" }
        if ($Package) { $cmd += " -Package" }
        if ($Force) { $cmd += " -Force" }

        Invoke-Expression $cmd
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

