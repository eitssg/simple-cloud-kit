# Load-EnvFile.ps1 - Best practices for loading .env files in PowerShell

function Import-EnvFile {
    <#
    .SYNOPSIS
        Loads environment variables from a .env file
    .PARAMETER Path
        Path to the .env file (default: .env)
    .EXAMPLE
        Import-EnvFile
        Import-EnvFile -Path "config.env"
    #>
    param(
        [string]$Path = ".env"
    )

    if (-not (Test-Path $Path)) {
        Write-Warning "Environment file not found: $Path"
        return
    }

    $loaded = 0
    Get-Content $Path | Where-Object {
        # Skip empty lines and comments
        $line = $_.Trim()
        $line -and -not $line.StartsWith('#')
    } | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()

            # Handle quoted values
            if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
                ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                $value = $value.Substring(1, $value.Length - 2)
            }

            # Always set the environment and script-scoped variables
            Set-Item -Path "env:$key" -Value $value
            Set-Variable -Name $key -Value $value -Scope 1 -Force
            $loaded++
        }
    }

    Write-Host "Loaded $loaded environment variables from $Path"
}

