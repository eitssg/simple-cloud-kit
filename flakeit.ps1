# Get the current folder name
$packageName = (Get-Item -Path ".\").Name

$version = (poetry version -s)

Write-Host "`n---- LINTING project: $packageName v${version}"

# if the file pyproject.toml does not exist, return with error "Must be in project folder":
if (-not (Test-Path -Path "./pyproject.toml" -PathType Leaf)) {
    Write-Host "Must be in project folder"
    return
}

poetry run black .

poetry run flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics

