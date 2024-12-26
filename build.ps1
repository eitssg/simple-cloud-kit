# Get the current folder name
$packageName = (Get-Item -Path ".\").Name

$version = (poetry version -s)

Write-Host "`n---- BUILDING project: $packageName v${version}"

# if the file pyproject.toml does not exist, return with error "Must be in project folder":
if (-not (Test-Path -Path "./pyproject.toml" -PathType Leaf)) {
    Write-Host "Must be in project folder"
    return
}

# Remove the dist folder if it exists
if (Test-Path -Path "dist" -PathType Container) {
    Remove-Item -Path "dist" -Recurse -Force
}

# check if vitual environment is activated and if not fail with an error
if (-not $env:VIRTUAL_ENV) {
    Write-Error "Virtual environment is not activated. Run '. ..\.venv\Scripts\Activate.ps1' to activate the virtual environment."
    exit 1
}

#Check if the virtual environment is activated and show only the version and source folder and do not show titles
Write-Host "`n---- Python version and source folder"
$pythonCommand = Get-Command python
$pythonCommand | Select-Object -Property Version, Source | Format-List | Out-String -Stream | Select-String -Pattern "Version|Source"

Write-Host "`n---- Installing/updating dependencies"
python -m pip -q install --upgrade pip
python -m pip -q install --upgrade poetry poetry-dynamic-versioning polib

poetry self add -q poetry-plugin-export

poetry config warnings.export false

# Run the poetry build command
poetry update

Write-Host "`n---- Building the project"

poetry build

# Install the project
Write-Host "`n---- Installing the project"
poetry install

# add to the existing file ../requirements.txt the output of "pip freeze" command and ensure the file is sorted
Write-Host "`n---- Updating requirements.txt"

python ..\pipit.py
