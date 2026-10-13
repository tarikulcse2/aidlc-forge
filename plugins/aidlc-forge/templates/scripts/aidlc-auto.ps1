<#
  Managed by the aidlc-forge plugin (templates/scripts/aidlc-auto.ps1, v3.3.2). Re-run /aidlc-forge:init to update.

.SYNOPSIS
  AI-DLC automatic mode, unattended. Runs /aidlc-forge:auto (or custom-workflow with -Phases) in Claude Code headless mode with enforced limits, then
  re-runs the regression itself instead of trusting Claude's report, and appends a metrics row.
  Never pushes, deploys or closes CRs.

.EXAMPLE
  .\scripts\aidlc\aidlc-auto.ps1 -Intent continue
  .\scripts\aidlc\aidlc-auto.ps1 -Intent "continue CR-003" -Phases implementation,testing -MaxBudgetUsd 10
  .\scripts\aidlc\aidlc-auto.ps1 -Intent "Email the employee when leave is decided. Use a background queue, reuse IEmailSender."
#>
param(
    [Parameter(Mandatory = $true)] [string] $Intent,   # "continue", "continue CR-NNN", or the change plus how to implement it
    [string[]] $Phases = @('all'),                      # steps to run: requirements, planning, implementation, testing, deploy (or all)
    [decimal] $MaxBudgetUsd = 20                        # hard spending cap for this run
)
# All steps: /aidlc-forge:auto (no picker). Chosen steps: /aidlc-forge:custom-workflow --phases (skips its picker).
$phaseList = ($Phases -join ',').Replace(' ', '')
$prompt = if ($phaseList -eq 'all') { "/aidlc-forge:auto $Intent" } else { "/aidlc-forge:custom-workflow --phases $phaseList $Intent" }

# 'Continue', not 'Stop': in Windows PowerShell 5.1, stderr from native tools becomes a terminating error under 'Stop'.
$ErrorActionPreference = 'Continue'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $root

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { throw 'The Claude Code CLI (claude) is not on PATH.' }
if (-not (Test-Path '.aidlc\config.yaml')) { throw '.aidlc/config.yaml not found (run /aidlc-forge:init first).' }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$runDir = Join-Path $root ".aidlc\runs\$stamp"
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
$budget = $MaxBudgetUsd.ToString([System.Globalization.CultureInfo]::InvariantCulture)

# Limits enforced by Claude Code itself, not only by instructions:
#  - file edits are auto-accepted, except in .claude/, CLAUDE.md and .aidlc/config.yaml
#  - the git commands for local CR-branch commits are allowed; push, merge and rebase are denied
#  - the plugin's own scripts are allowed by each command's allowed-tools (only its scripts folder); `bash -c` and
#    `sh -c` are denied, because a wrapped command would get around the deny rules above
#  - every other shell command must already be on the project's allow-list (nobody is there to approve it)
$allowed = @('Bash(git status:*)', 'Bash(git diff:*)', 'Bash(git merge-base:*)', 'Bash(git config:*)',
             'Bash(git switch:*)', 'Bash(git checkout -b:*)', 'Bash(git add:*)', 'Bash(git commit:*)')
$denied  = @('Edit(.claude/**)', 'Write(.claude/**)', 'Edit(CLAUDE.md)', 'Write(CLAUDE.md)',
             'Edit(.aidlc/config.yaml)', 'Write(.aidlc/config.yaml)',
             'Bash(git push:*)', 'Bash(git merge:*)', 'Bash(git rebase:*)', 'Bash(git reset:*)', 'Bash(rm -rf:*)',
             'Bash(bash -c *)', 'Bash(sh -c *)')

Write-Host "[1/2] Claude: $prompt  (budget cap: $budget USD)" -ForegroundColor Cyan
$cliArgs = @('-p', $prompt, '--permission-mode', 'acceptEdits', '--max-budget-usd', $budget,
             '--output-format', 'json', '--allowedTools') + $allowed + @('--disallowedTools') + $denied
$raw = & claude @cliArgs
$claudeExit = $LASTEXITCODE
$json = $raw -join "`n"
$json | Out-File -FilePath (Join-Path $runDir 'claude-output.json') -Encoding utf8

$summary = $null
try { $summary = $json | ConvertFrom-Json } catch { }
if ($summary) {
    $summary.result | Out-File -FilePath (Join-Path $runDir 'claude-summary.md') -Encoding utf8
    Write-Host ("Claude finished: error={0} turns={1} cost=`${2}" -f $summary.is_error, $summary.num_turns, $summary.total_cost_usd)
}

# Independent check: never rely only on the agent's own claim that the tests are green.
Write-Host '[2/2] Independent regression run' -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'run-regression.ps1') *>&1 | Tee-Object -FilePath (Join-Path $runDir 'regression.log')
$regressionExit = $LASTEXITCODE

$ok = ($claudeExit -eq 0) -and -not ($summary -and $summary.is_error) -and ($regressionExit -eq 0)
$metrics = '.aidlc\metrics.csv'
if (-not (Test-Path $metrics)) { 'date,cr,unit,track,size,mode,result,attempts,tests_added,notes' | Out-File $metrics -Encoding utf8 }
$cost = if ($summary) { $summary.total_cost_usd } else { '' }
$note = ("run '{0}' cost_usd={1} turns={2}" -f $Intent, $cost, $(if ($summary) { $summary.num_turns } else { '' })).Replace(',', ';')
"$(Get-Date -Format 'yyyy-MM-dd'),,run,,,auto-headless,$(if ($ok) { 'done' } else { 'failed' }),,,$note" | Add-Content $metrics -Encoding utf8

Write-Host ''
Write-Host "Run folder : $runDir"
Write-Host 'Report     : docs/ops/auto-run-report.md'
Write-Host 'Next       : review the CR branch diff, run /aidlc-forge:step to ratify the auto-approved gates, then open a PR'
if (-not $ok) { Write-Host 'AUTO RUN: RED (Claude error, hard stop, or regression failure). See the run folder.' -ForegroundColor Red; exit 1 }
Write-Host 'AUTO RUN: GREEN' -ForegroundColor Green
exit 0
