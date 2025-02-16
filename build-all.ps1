# Powershell

# if the file build-all.ps1 does not exist, return with error "Must be in main tookit folder":
if (-not (Test-Path -Path "./build-all.ps1" -PathType Leaf)) {
    Write-Host "Must be in main tookit folder"
    return
}

# Function to build and package a project
function Build-AppComponent {
    param (
        [string]$project,
        [string]$type,
        [string]$version
    )

    # Save the original directory
    $mainDir = Get-Location

    try {
        # Return if the project path cannot be found
        if (-not (Test-Path -Path $project -PathType Container)) {
            Write-Host "Project $project does not exist"
            return
        }

        # Change to the sub-project folder
        Set-Location -Path $project

        Write-Host "`n`n--------------------------------------------"
        Write-Host "Building $project"
        Write-Host "--------------------------------------------"

        . ..\build-module.ps1 -type $type

    }
    catch {
        Write-Host "Error building $project"
    }
    finally {
        # Return to the original directory
        Set-Location -Path $mainDir
    }
}

# Function to build all components
function Build-AllComponents {
    param (
        [string]$type,
        [string]$version,
        [string[]]$projects
    )

    foreach ($p in $projects) {
        Build-AppComponent -project $p -type $type -version $version
    }
}

# Initialize a variable with a list of folders for regular projects.  The lambda functions are depnedent on the core-framework
# so use the same python version.  AWS maximum lambda runtime is "python3.11"
$projects = @(
    "sck-core-framework"
    "sck-core-db"
)

Build-AllComponents -type "app" -version "3.12.4" -projects $projects

# Initialize a variable with a list of folders for Lambda projects
# core-lambda-api is dependent on the core-framework so use the same python version.  AWS maximum lambda runtime is "python3.12"

$lambdaProjects = @(
    "sck-core-execute",
    "sck-core-report",
    "sck-core-runner"
    "sck-core-component",
    "sck-core-deployspec",
    "sck-core-invoker",
    "sck-core-organization",
    "sck-core-api",
    "sck-core-codecommit"
)

Build-AllComponents -type "lambda" -version "3.12.4" -projects $lambdaProjects

# Initialize a variable with a list of folders for regular projects
$projects = @(
    "sck-core-cli",
    "sck-core-docs"
)

# Build all command-line apps and modules with python 3.12.4.  There are only 2 "command line" executable
# sck-mod-core and docs.  sck-mod-core command is "core", and docs command is "core-docs"
Build-AllComponents -type "app" -version "3.12.4" -projects $projects
