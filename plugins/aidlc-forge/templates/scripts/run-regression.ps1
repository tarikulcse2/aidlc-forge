<#
  Managed by the aidlc-forge plugin (templates/scripts/run-regression.ps1, v3.3.2). Re-run /aidlc-forge:init to update.

.SYNOPSIS
  Regression without AI: ONE test command from .aidlc/config.yaml. By default that's `test_all`, which builds and
  includes the fast tests. -Fast runs only `test_fast`, and -Story runs only `test_story`. Nothing runs twice.
  Exit code 0 = GREEN, 1 = RED. Use it by hand, from Task Scheduler, from a git pre-push hook, or in CI.

.EXAMPLE
  .\scripts\aidlc\run-regression.ps1
  .\scripts\aidlc\run-regression.ps1 -Story US004
#>
param(
    [string] $Story,      # optional: run only one story, e.g. US004
    [switch] $Fast        # optional: only the fast layer
)

# 'Continue', not 'Stop': in Windows PowerShell 5.1, stderr from native tools becomes a terminating error
# under 'Stop'. Results are decided by $LASTEXITCODE instead.
$ErrorActionPreference = 'Continue'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $root

$configPath = Join-Path $root '.aidlc\config.yaml'
if (-not (Test-Path $configPath)) { Write-Host 'RED: .aidlc/config.yaml not found (run /aidlc-forge:init)' -ForegroundColor Red; exit 1 }
$config = Get-Content $configPath
function Get-Config([string] $key) {
    $line = $config | Where-Object { $_ -match "^$([regex]::Escape($key)):\s*(.*)$" } | Select-Object -First 1
    if ($line -and $line -match "^$([regex]::Escape($key)):\s*(.*)$") { return $Matches[1].Trim() }
    return ''
}

function Invoke-Step([string] $name, [string] $command) {
    if (-not $command) { return $true }
    Write-Host "== $name : $command" -ForegroundColor Cyan
    # Out-Host: tool output must not become part of this function's return value, or the result is always "true".
    Invoke-Expression $command | Out-Host
    return ($LASTEXITCODE -eq 0)
}

# One command only: the test commands build the code themselves, and the fast tests are a subset of test_all.
if ($Story)    { $name = 'story'; $command = (Get-Config 'test_story').Replace('{ID}', $Story) }
elseif ($Fast) { $name = 'fast';  $command = Get-Config 'test_fast' }
else           { $name = 'all';   $command = Get-Config 'test_all' }

$failed = @()
if (-not (Invoke-Step $name $command)) { $failed += $name }

if ($failed.Count -gt 0) {
    Write-Host "RED: failed step(s): $($failed -join ', ')" -ForegroundColor Red
    exit 1
}
Write-Host 'GREEN: all steps passed' -ForegroundColor Green
exit 0
