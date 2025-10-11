
# Function to build and package a project
function Merge {
    param (
        [string]$project
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
        Write-Host "Merging $project"
        Write-Host "--------------------------------------------"

        git checkout main
        git pull
        git merge develop
        git push
        git push --tags
        git checkout develop

    }
    catch {
        Write-Host "Error merging $project"
    }
    finally {
        # Return to the original directory
        Set-Location -Path $mainDir
    }
}

# Initialize a variable with a list of folders for regular projects.  The lambda functions are depnedent on the core-framework
# so use the same python version.  AWS maximum lambda runtime is "python3.11"
$projects = @(
    "sck-core-framework"
    "sck-core-db"
    "sck-core-execute",
    "sck-core-report",
    "sck-core-runner"
    "sck-core-component",
    "sck-core-deployspec",
    "sck-core-invoker",
    "sck-core-organization",
    "sck-core-api",
    "sck-core-codecommit"
    "sck-core-cli",
    "sck-core-docs",
    "sck-core-ai"
)

foreach ($p in $projects) {
    Merge -project $p
}

