<#!
Runs pytest for every sck-core-* module by invoking the module-local virtual environment interpreter directly.
This avoids relying on VS Code's terminal auto-activation (which is not triggered for automated shell commands).

Usage:
  pwsh ./test-all.ps1 [-Verbose] [-StopOnFail]

Options:
  -StopOnFail   Stop immediately when a module test run fails.
  -SummaryOnly  Only print the final summary (suppress individual module output unless failing).
  -Pattern <glob>  Filter modules by wildcard pattern (e.g. -Pattern sck-core-a*).

Prerequisites:
  Each module should have its venv created (build scripts or manual) and dev deps installed so pytest plugins (pytest-cov) are available.
!#>
param(
  [switch]$StopOnFail,
  [switch]$SummaryOnly,
  [switch]$Smoke,
  [string]$Pattern = '*'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if($PSScriptRoot){ $root = $PSScriptRoot } else { $root = Split-Path -Parent $MyInvocation.MyCommand.Path }
Push-Location $root

$modules = @(
  'sck-core-framework',
  'sck-core-db',
  'sck-core-execute',
  'sck-core-report',
  'sck-core-runner',
  'sck-core-deployspec',
  'sck-core-component',
  'sck-core-invoker',
  'sck-core-organization',
  'sck-core-api',
  'sck-core-codecommit',
  'sck-core-cli',
  'sck-core-ai',
  'sck-core-docs'
)

$modules = $modules | Where-Object { $_ -like $Pattern }

$results = @()
function Write-Section($text){ Write-Host "`n==== $text ====\n" -ForegroundColor Cyan }
function Write-Warn($text){ Write-Host $text -ForegroundColor Yellow }
function Write-ErrLine($text){ Write-Host $text -ForegroundColor Red }
function Write-Ok($text){ Write-Host $text -ForegroundColor Green }

foreach($m in $modules){
  $modulePath = Join-Path $root $m
  $venvPy = Join-Path $modulePath '.venv/Scripts/python.exe'
  $hasVenv = Test-Path $venvPy
  $status = 'SKIPPED'
  $duration = [TimeSpan]::Zero
  $msg = ''

  if(-not $hasVenv){
    $msg = 'No .venv interpreter found'
    $results += [pscustomobject]@{Module=$m; Status=$status; DurationMs=$duration.TotalMilliseconds; Message=$msg}
    if(-not $SummaryOnly){ Write-Warn "[$m] $msg" }
    continue
  }

  $pytestIni = Join-Path $modulePath 'pytest.ini'
  if(-not (Test-Path $pytestIni)){
    $msg = 'No pytest.ini (assuming no tests)'
    $results += [pscustomobject]@{Module=$m; Status=$status; DurationMs=$duration.TotalMilliseconds; Message=$msg}
    if(-not $SummaryOnly){ Write-Warn "[$m] $msg" }
    continue
  }

  $start = Get-Date
  if(-not $SummaryOnly){ Write-Section "Testing $m" }

  if($Smoke){
    # Find first core_* package folder for import smoke
    $pkg = Get-ChildItem -Path $modulePath -Directory -Name 'core_*' | Select-Object -First 1
    if(-not $pkg){
      $msg = 'No core_* package directory found for smoke import'
      $status = 'SKIPPED'
      $results += [pscustomobject]@{Module=$m; Status=$status; DurationMs=0; Message=$msg}
      if(-not $SummaryOnly){ Write-Warn "[$m] $msg" }
      continue
    }
    & $venvPy -c "import $pkg; print('SMOKE_OK')" 2>$null
    $exit = $LASTEXITCODE
  } else {
    Push-Location $modulePath
    try {
      $pytestArgs = @('-m','pytest','-q')
      & $venvPy @pytestArgs
      $exit = $LASTEXITCODE
    } catch {
      $exit = 1
      $msg = $_.Exception.Message
    } finally {
      Pop-Location
    }
  }
  $duration = (Get-Date) - $start
  if($exit -eq 0){
    $status = 'PASS'
    if(-not $SummaryOnly){ Write-Ok "[$m] PASS ($([int]$duration.TotalMilliseconds) ms)" }
  } else {
    $status = 'FAIL'
    if(-not $SummaryOnly){ Write-ErrLine "[$m] FAIL ($([int]$duration.TotalMilliseconds) ms)" }
    if($StopOnFail){ break }
  }
  $results += [pscustomobject]@{Module=$m; Status=$status; DurationMs=$duration.TotalMilliseconds; Message=$msg}
}

Write-Host "`n================ SUMMARY ================" -ForegroundColor Cyan
$fmt = '{0,-20} {1,-6} {2,>8}ms {3}'
Write-Host ($fmt -f 'Module','Status','Time','Message') -ForegroundColor Gray
foreach($r in $results){
  $color = if($r.Status -eq 'PASS'){'Green'} elseif($r.Status -eq 'FAIL'){'Red'} else {'Yellow'}
  Write-Host ($fmt -f $r.Module, $r.Status, [int]$r.DurationMs, $r.Message) -ForegroundColor $color
}

$failCount = ($results | Where-Object Status -eq 'FAIL').Count
$passCount = ($results | Where-Object Status -eq 'PASS').Count
$skipCount = ($results | Where-Object Status -eq 'SKIPPED').Count
Write-Host "`nPassed: $passCount  Failed: $failCount  Skipped: $skipCount" -ForegroundColor Cyan

if($failCount -gt 0){ exit 1 } else { exit 0 }
