# Finding the Python interpreter and building the project using Poetry
$pythonCommand = Get-Command python

# If the python interpreter is not found, return with error "Python interpreter not found. Please install Python."
if (-not $pythonCommand) {
    Write-Host "Python interpreter not found. Please install Python."
    exit 1
}

# Get the current folder name
$packageName = (Get-Item -Path ".\").Name

# if the file pyproject.toml does not exist, return with error "Must be in project folder":
if (-not (Test-Path -Path "./pyproject.toml" -PathType Leaf)) {
    Write-Host "Must be in project folder"
    exit 1
}

# if the virtual environment does not exist, return with error "Virtual environment does not exist. Run 'poetry install' to create it."
if (-not (Test-Path -Path ".\.venv" -PathType Container)) {
    Write-Host "Creating virtual environment..."
    python -m venv .\.venv
    . .\.venv\Scripts\Activate.ps1
    python -m pip install -q --upgrade pip
    python -m pip install -q poetry poetry-dynamic-versioning
}

. .\.venv\Scripts\Activate.ps1

# if the virtual environmewnt is not activated, activate it
if (-not $env:VIRTUAL_ENV) {
    Write-Host "Cannot activate virtual environment..."
    exit 1
}

Write-Host "`n---- Python version and source folder"
$pythonCommand = Get-Command python
$pythonCommand | Select-Object -Property Version, Source | Format-List | Out-String -Stream | Select-String -Pattern "Version|Source"

# Check if poetry is installed
if (-not (Get-Command poetry -ErrorAction SilentlyContinue)) {
    Write-Host "Poetry is not installed. Installing it."
    python -m pip install -q poetry poetry-dynamic-versioning
}

$version = (poetry version -s)

Write-Host "`n---- BUILDING project: $packageName v${version}"

# Remove the dist folder if it exists
if (Test-Path -Path "dist" -PathType Container) {
    Remove-Item -Path "dist" -Recurse -Force
}

Remove-Item -Path "poetry.lock" -Force

Write-Host "`n---- Installing the project and depndencies using Poetry"

poetry install

Write-Host "`n---- Building the distribution files for project: $packageName v${version}`n"

poetry build

# Move the files from the dist folder to the folder ../sck-core-docker/dist and create the destination folder if necessary
$distPath = "..\sck-core-docker\dist"
if (-not (Test-Path -Path $distPath -PathType Container)) {
    New-Item -ItemType Directory -Path $distPath
}

# create a filePrefix for the package name changing dashes in the name to underscores
$filePrefix = $packageName -replace '-', '_'

# if the dist folder contains files with the project prefix remove them
Get-ChildItem -Path $distPath -File | Where-Object { $_.Name -like "$filePrefix*" } | Remove-Item -Force

# Copy the files from the dist folder to the destination folder
Write-Host "`n---- Copying distribution files to $distPath"

Get-ChildItem -Path "dist" -File | ForEach-Object {
    $destinationPath = Join-Path -Path $distPath -ChildPath $_.Name
    Copy-Item -Path $_.FullName -Destination $destinationPath -Force
}
Write-Host "`n---- Distribution files moved to $distPath"
Write-Host "`n---- Build complete for project: $packageName v${version}"

# if the file .lambda exists then execute package.ps1 script
if (Test-Path -Path ".\.lambda" -PathType Leaf) {
    . ..\package.ps1 
}