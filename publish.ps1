# Get the current folder name
$packageName = (Get-Item -Path ".\").Name

# if the enironment variable NEXUS_SERVER is not set, return with error "NEXUS_SERVER environment variable not set"
if ((-not $Env:NEXUS_SERVER) -or (-not $Env:NEXUS_USERNAME) -or (-not $Env:NEXUS_PASSWORD)) {
    Write-Host "Error while PUBLISHING: NEXUS_SERVER environment variables are not set"
    return
}

Write-Host "`n---- PUBLISHING project: $packageName to $Env:NEXUS_SERVER/repository/pypi-releases/"

# if the file pyproject.toml does not exist, return with error "Must be in project folder":
if (-not (Test-Path -Path "./pyproject.toml" -PathType Leaf)) {
    Write-Host "Must be in project folder"
    return
}


# Set the URL for the nexus-releases repository
poetry config repositories.nexus-releases $Env:NEXUS_SERVER/repository/pypi-releases/

# Publish the package to PyPI repository
poetry publish --repository nexus-releases -u $Env:NEXUS_USERNAME -p $Env:NEXUS_PASSWORD
