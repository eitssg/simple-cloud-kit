param(
    [switch]$Force,
    [switch]$Verbose
)

# Get the current folder name
$packageName = (Get-Item -Path ".\").Name

# if the enironment variable NEXUS_SERVER is not set, return with error "NEXUS_SERVER environment variable not set"
if ((-not $Env:NEXUS_SERVER) -or (-not $Env:NEXUS_USERNAME) -or (-not $Env:NEXUS_PASSWORD)) {
    Write-Host "Error while PUBLISHING: NEXUS_SERVER environment variables are not set"
    exit 1
}

Write-Host "`n---- PUBLISHING project: $packageName to $Env:NEXUS_SERVER/repository/pypi-releases/"

# if the file pyproject.toml does not exist, return with error "Must be in project folder":
if (-not (Test-Path -Path "./pyproject.toml" -PathType Leaf)) {
    Write-Host "Must be in project folder"
    exit 1

}

# if the dist folder is empty, return with error "No distribution files found. Run 'uv build' to create them."
if (-not (Test-Path -Path "./dist" -PathType Container) -or
    (-not (Get-ChildItem -Path "./dist" -File | Where-Object { $_.Name -match "\.whl$|\.tar\.gz$" }))) {
    Write-Host "No distribution files found. Run 'uv build' to create them."
    exit 1
}

if ($Force) {
    # Get name and version from uv JSON output
    $uvJson = uv version --output-format json | ConvertFrom-Json
    $name = $uvJson.package_name
    $version = $uvJson.version

    if ($name -and $version) {
        # First search for the component to get its ID
        $searchUrl = "$Env:NEXUS_SERVER/service/rest/v1/search?repository=pypi-releases&name=$name&version=$version"
        Write-Host "Searching for existing package $name $version in Nexus..."

        try {
            # Use basic auth header like curl -u (to match publish.sh)
            $authString = "$($Env:NEXUS_USERNAME):$($Env:NEXUS_PASSWORD)"
            $authBytes = [System.Text.Encoding]::ASCII.GetBytes($authString)
            $authBase64 = [Convert]::ToBase64String($authBytes)
            $headers = @{ "Authorization" = "Basic $authBase64" }

            $searchResponse = Invoke-WebRequest -Uri $searchUrl -Method Get -Headers $headers -ErrorAction Stop
            if ($Verbose) {
                $searchResponse  # This will display the response object
            }
            $searchData = $searchResponse.Content | ConvertFrom-Json

            if ($searchData.items -and $searchData.items.Count -gt 0) {
                $componentId = $searchData.items[0].id
                $deleteUrl = "$Env:NEXUS_SERVER/service/rest/v1/components/$componentId"

                Write-Host "Force deleting existing package $name $version (ID: $componentId) from Nexus..."
                # Try the delete with the same auth header
                try {
                    $deleteResponse = Invoke-WebRequest -Uri $deleteUrl -Method Delete -Headers $headers -ErrorAction Stop
                    if ($Verbose) {
                        $deleteResponse  # This will display the response object
                    }
                    Write-Host "Deleted existing package."
                } catch {
                    $statusCode = $_.Exception.Response.StatusCode.value__
                    $statusDescription = $_.Exception.Response.StatusDescription
                    Write-Host "API Delete failed: $statusCode ($statusDescription)"
                    Write-Host "Request URL: $deleteUrl"
                    Write-Host "Continuing with publish anyway..."
                }
            } else {
                Write-Host "Package $name $version not found in Nexus - nothing to delete."
            }
        } catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $statusDescription = $_.Exception.Response.StatusDescription
            Write-Host "Failed to search for existing package: $statusCode ($statusDescription)"
            Write-Host "Cannot determine if package exists for force delete."
        }
    } else {
        Write-Host "Could not get name/version from uv for force delete."
    }
}

# Publish the package to PyPI repository
uv publish --config-file ..\uv.toml
