$A = @(
    "sck-core-api",
    "sck-core-cli",
    "sck-core-codecommit",
    "sck-core-component",
    "sck-core-db",
    "sck-core-deployspec",
    "sck-core-docker",
    "sck-core-docker-base",
    "sck-core-docker-server",
    "sck-core-docs",
    "sck-core-execute",
    "sck-core-framework",
    "sck-core-invoker",
    "sck-core-organization",
    "sck-core-report",
    "sck-core-runner",
    "sck-core-ui",
    "sck-core-ai"
)

# Load environment variables from .env file
. .\Load-EnvFile.ps1
Import-EnvFile

if (-not $BRANCH) {
    $BRANCH = "develop"
}

write-Host "Using branch: $BRANCH" -ForegroundColor Green

foreach ($B in $A) {
    Write-Host $B -ForegroundColor Green

    Set-Location $B

    try {
        git rev-parse --verify $BRANCH > $null 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Branch '$BRANCH' does not exist in $B. Creating it now." -ForegroundColor Yellow
            git checkout -b $BRANCH
            git push --set-upstream origin $BRANCH
        }
        else {
            git checkout $BRANCH
        }
        
        git pull
        git pull --tags
    } catch {
        Write-Host "Error processing ${B}: $_" -ForegroundColor Red
    } finally {
        Set-Location ..
    }
}
