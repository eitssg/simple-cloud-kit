# Get the name of the current folder
$packageName = (Get-Item -Path ".\").Name

$version = (poetry version -s)

Write-Host "`n---- PACKAGING project: $packageName v${version} for Lambda"

# if the file pyproject.toml does not exist, return with error "Must be in project folder":
if (-not (Test-Path -Path "./pyproject.toml" -PathType Leaf)) {
    Write-Host "Must be in project folder"
    return
}

write-host "Packaging Lambda $packageName"

# Get the current version of the poetry version -s command
$version = (poetry version -s)

# Package Name
$artefactName = "$packageName-$version.zip"

# Remove the artefact by packageName
Remove-Item -Path "$packageName*.zip" -ErrorAction SilentlyContinue -Force

# Remove the package folder if it exists
if (Test-Path -Path "package" -PathType Container) {
    Remove-Item -Path "package" -Recurse -Force
}

# Find the .whl file in the dist folder
$whlFile = Get-ChildItem -Path "dist" -Filter "*.whl" | Select-Object -First 1

if ($null -eq $whlFile) {
    Write-Host "No .whl file found in the dist folder."
    exit 1
}

# Install the .whl file into the package folder
poetry run pip -q install --upgrade -t package $whlFile.FullName

if (Test-Path -Path "package") {
    Set-Location -Path package
    & "C:\Program Files\7-Zip\7z.exe" a -bd -bb0 ../$artefactName * -xr!*.pyc > $null 2>&1
    Set-Location -Path ..
    Remove-Item -Path "package" -Recurse -Force
} else {
    Write-Host "Package creation failed."
    exit 1
}

Write-Host "Lambda package: $artefactName"
