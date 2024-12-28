# define an input parameter named "tag" of type string
param(
    [string]$tag
)

$example = "Example: .\tag-all.ps1 -tag v1.0.0"

# ensure the tag is not empty else fail
if (-not $tag) {
    Write-Host "Tag must be provided"
    Write-Host $example
    return
}

# ensure the tag begins with the letter "v" else fail
if ($tag.Substring(0, 1) -ne "v") {
    Write-Host "Tag must begin with 'v'"
    Write-Host $example
    return
}

# check that the string after the v is in the semver format
if (-not ($tag -match "^v\d+\.\d+\.\d+$")) {
    Write-Host "Tag must be in semver format"
    Write-Host $example
    return
}

# define a list of folders to iterate over
$folders = @("sck-core-api", "sck-core-cli", "sck-core-component", "sck-core-db", "sck-core-deployspec", "sck-core-docker",
"sck-core-docs", "sck-core-execute", "sck-core-framework", "sck-core-invoker", "sck-core-runner")

# iterate over the folders.  For each folder:
foreach ($folder in $folders) {

    $currentFolder = Get-Location

    # change to the folder
    Set-Location -Path $folder

    # get the current folder name
    $packageName = (Get-Item -Path ".\").Name

    # get the version from the pyproject.toml file
    $version = (poetry version -s)

    # write the project name and version
    Write-Host "Checking project: $packageName v${version}"

    # Get all the tags in the git repository in the submodule
    $tags = git tag

    if ($tags -contains $tag) {
        Write-Host "Tag $tag already exists project $folder"
        # continue to the next folder
        continue
    }

    # if the tag does not exist, create it
    git tag $tag

    # push the tag to the remote repository
    git push origin $tag

    # build the project with "..\build.ps1" command
    ..\build.ps1

    # change back to the parent folder
    Set-Location -Path $currentFolder
}
