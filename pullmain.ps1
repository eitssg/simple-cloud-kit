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

$BRANCH = "develop"

foreach ($B in $A) {
    Write-Host $B
    Set-Location $B
    git checkout $BRANCH
    git pull
    git pull --tags
    Set-Location ..
}
