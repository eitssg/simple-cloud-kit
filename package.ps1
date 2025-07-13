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

Write-Host "---- Python version and source folder`n"
$pythonCommand = Get-Command python
$pythonCommand | Select-Object -Property Version, Source | Format-List | Out-String -Stream | Select-String -Pattern "Version|Source"

# Check if poetry is installed
if (-not (Get-Command poetry -ErrorAction SilentlyContinue)) {
    Write-Host "Poetry is not installed. Installing it."
    python -m pip install -q poetry poetry-dynamic-versioning
}

$version = (poetry version -s)

Write-Host "`n---- PACKAGING project: $packageName v${version} for Lambda`n"

# Remove the dist folder if it exists
if (-not (Test-Path -Path "dist" -PathType Container)) {
    Write-Host "The dist folder does not exist.  You must build the project first."
    exit 1
}

# Remove the package folder if it exists
if (Test-Path -Path "package" -PathType Container) {
    Remove-Item -Path "package" -Recurse -Force
}

write-Host "Packaging Lambda $packageName"

# Get the current version of the poetry version -s command
$version = (poetry version -s)

# Package Name
$artefactName = "$packageName-$version.zip"

# Remove the artefact by packageName
Remove-Item -Path "$packageName*.zip" -ErrorAction SilentlyContinue -Force

# Find the .whl file in the dist folder
$whlFile = Get-ChildItem -Path "dist" -Filter "*.whl" | Select-Object -First 1

if ($null -eq $whlFile) {
    Write-Host "No .whl file found in the dist folder."
    exit 1
}

# if the program 7-Zip is not installed, return with error "7-Zip is not installed. Please install 7-Zip."
if (-not (Get-Command "C:\Program Files\7-Zip\7z.exe" -ErrorAction SilentlyContinue)) {
    Write-Host "7-Zip is not installed. Please install 7-Zip. (It's free software)"
    exit 1
}

# Install the .whl file into the package folder
Write-Host "Installing $($whlFile.Name) into package folder"
pip -q install --upgrade -t package $whlFile.FullName

if (Test-Path -Path "package") {
    Set-Location -Path package
    & "C:\Program Files\7-Zip\7z.exe" a -bd -bb0 ../$artefactName * -x"r!*.pyc" > $null 2>&1
    
    Set-Location -Path ..
    Remove-Item -Path "package" -Recurse -Force -ProgressAction SilentlyContinue

    Write-Host "Package created successfully: $artefactName"

    # Move the zip file to the destination folder ../sck-core-docker/lambda and create the folder if it does not exist
    $destinationFolder = "../sck-core-docker/lambda"
    if (-not (Test-Path -Path $destinationFolder)) {
        New-Item -ItemType Directory -Path $destinationFolder
    }

    # if any file begins with the prifix $packageName and ends with .zip, remove it
    $existingFiles = Get-ChildItem -Path $destinationFolder -Filter "$packageName*.zip" -ErrorAction SilentlyContinue
    if ($existingFiles) {
        Remove-Item -Path $existingFiles.FullName -Force
    }

    # Move the artefact to the destination folder
    Move-Item -Path $artefactName -Destination $destinationFolder -Force
    Write-Host "Package moved to: $destinationFolder"
    Write-Host "Package creation completed successfully."

} else {
    Write-Host "Package creation failed."
    exit 1
}

Write-Host "`nLambda package: $artefactName"
