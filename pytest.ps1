# Get the current folder name
$packageName = (Get-Item -Path ".\").Name

$version = (poetry version -s)

Write-Host "`n---- TESTING project: $packageName v${version}"

# if the file pyproject.toml does not exist, return with error "Must be in project folder":
if (-not (Test-Path -Path "./pyproject.toml" -PathType Leaf)) {
    Write-Host "Must be in project folder"
    return
}

# if the .env file does not exist, create it:
if (-not (Test-Path -Path "./.env" -PathType Leaf)) {
    Write-Host "Creating .env file"

    # Wrote the line "LOCAL_MODE=True" to .env
    Add-Content -Path ".env" -Value "LOCAL_MODE=True"
}

poetry run pytest
