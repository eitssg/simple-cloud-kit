
# if the folder simple_cloud_kit doesn't exist, then bail out with error
if (-not (Test-Path -Path ".\simple_cloud_kit" -PathType Container)) {
    Write-Host "Must be in project folder"
    exit 1
}

# the .venv folder doesn't exist, create it 
if (-not (Test-Path -Path ".\.venv" -PathType Container)) {
    Write-Host "Creating virtual environment..."
    python -m venv .\.venv
}

# Acteivate virtual environment
. .\.venv\Scripts\Activate.ps1

# Simply run the pip requirements silently
uv sync

# This doesnot work.  we wrote it for uv
# uv run simple_cloud_kit\prebuild.py