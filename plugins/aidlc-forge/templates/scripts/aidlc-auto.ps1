<#
  Managed by the aidlc-forge plugin (templates/scripts/aidlc-auto.ps1, v3.5.0). Re-run /aidlc-forge:init to update.

.SYNOPSIS
  AI-DLC automatic mode, unattended. Runs /aidlc-forge:auto (or custom-workflow with -Phases) in Claude Code headless mode with enforced limits, then
  re-runs the regression itself instead of trusting Claude's report, and appends a metrics row. Shows progress live
  (agents, progress events, edits, commands) and sends a Windows notification at the end (-NoNotify to turn it off).
  Never pushes, deploys or closes CRs.

.EXAMPLE
  .\scripts\aidlc\aidlc-auto.ps1 -Intent continue
  .\scripts\aidlc\aidlc-auto.ps1 -Intent "continue CR-003" -Phases implementation,testing -MaxBudgetUsd 10
  .\scripts\aidlc\aidlc-auto.ps1 -Intent "Email the employee when leave is decided. Use a background queue, reuse IEmailSender."
#>
param(
    [Parameter(Mandatory = $true)] [string] $Intent,   # "continue", "continue CR-NNN", or the change plus how to implement it
    [string[]] $Phases = @('all'),                      # steps to run: requirements, planning, implementation, testing, deploy (or all)
    [decimal] $MaxBudgetUsd = 20,                       # hard spending cap for this run
    [switch] $NoNotify                                  # no Windows notification at the end
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

$clock = [System.Diagnostics.Stopwatch]::StartNew()   # total wall-clock time of the whole run
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

function Get-Short([string] $s, [int] $max = 110) {
    $s = ($s -replace '\s+', ' ').Trim()
    if ($s.Length -gt $max) { $s.Substring(0, $max - 3) + '...' } else { $s }
}

# Live output: stream-json prints events as they happen (agents started, progress events, edits, commands).
# The full stream is kept in the run folder; watch.ps1 in a second terminal shows the same run from the files.
Write-Host "[1/2] Claude: $prompt  (budget cap: $budget USD)" -ForegroundColor Cyan
Write-Host "      live view in another terminal: .\scripts\aidlc\watch.ps1" -ForegroundColor DarkGray
$cliArgs = @('-p', $prompt, '--permission-mode', 'acceptEdits', '--max-budget-usd', $budget,
             '--output-format', 'stream-json', '--verbose', '--allowedTools') + $allowed + @('--disallowedTools') + $denied
$streamFile = Join-Path $runDir 'claude-stream.jsonl'
$summary = $null
& claude @cliArgs | ForEach-Object {
    $line = [string]$_
    Add-Content -Path $streamFile -Value $line -Encoding utf8
    $ev = $null; try { $ev = $line | ConvertFrom-Json } catch { return }
    if ($ev.type -eq 'result') { $summary = $ev; return }
    if ($ev.type -ne 'assistant') { return }
    $fromAgent = [bool]$ev.parent_tool_use_id   # sub-agents: show only their progress lines, not every step
    foreach ($c in @($ev.message.content)) {
        if ($fromAgent -and -not ($c.type -eq 'tool_use' -and [string]$c.input.command -match 'progress\.sh')) { continue }
        if ($c.type -eq 'tool_use') {
            $cmd = [string]$c.input.command
            if ($c.name -in @('Agent', 'Task')) { Write-Host ("  [agent]    " + (Get-Short $c.input.description)) -ForegroundColor Cyan }
            elseif ($c.name -eq 'Bash' -and $cmd -match 'progress\.sh"?\s+"([^"]*)"\s+"([^"]*)"\s*(?:"([^"]*)")?') {
                $pHandle = $Matches[1]; $pEvent = $Matches[2]; $pDetail = [string]$Matches[3]   # copy before the next -match
                $color = if ($pEvent -match 'COMPLETE|DONE') { 'Green' } elseif ($pEvent -match 'STOP') { 'Red' } else { 'White' }
                Write-Host ("  [{0}] {1}  {2}" -f $pEvent, $pHandle, (Get-Short $pDetail 80)) -ForegroundColor $color
            }
            elseif ($c.name -eq 'Bash') { Write-Host ("  [run]      " + (Get-Short $cmd)) -ForegroundColor DarkGray }
            elseif ($c.name -in @('Write', 'Edit')) { Write-Host ("  [edit]     " + $c.input.file_path) -ForegroundColor DarkGray }
        } elseif ($c.type -eq 'text' -and $c.text -and $c.text.Trim()) {
            Write-Host ("  " + (Get-Short (($c.text.Trim() -split "`n")[0]) 120))
        }
    }
}
$claudeExit = $LASTEXITCODE
if ($summary) { $summary | ConvertTo-Json -Depth 6 | Out-File -FilePath (Join-Path $runDir 'claude-output.json') -Encoding utf8 }
if ($summary) {
    $summary.result | Out-File -FilePath (Join-Path $runDir 'claude-summary.md') -Encoding utf8
    $claudeTime = if ($summary.duration_ms) { '{0:hh\:mm\:ss}' -f [timespan]::FromMilliseconds([double]$summary.duration_ms) } else { '?' }
    Write-Host ("Claude finished in {3}: error={0} turns={1} cost=`${2}" -f $summary.is_error, $summary.num_turns, $summary.total_cost_usd, $claudeTime)
}

# Independent check: never rely only on the agent's own claim that the tests are green.
Write-Host '[2/2] Independent regression run' -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'run-regression.ps1') *>&1 | Tee-Object -FilePath (Join-Path $runDir 'regression.log')
$regressionExit = $LASTEXITCODE

$ok = ($claudeExit -eq 0) -and -not ($summary -and $summary.is_error) -and ($regressionExit -eq 0)
$clock.Stop(); $total = '{0:hh\:mm\:ss}' -f $clock.Elapsed
$metrics = '.aidlc\metrics.csv'
if (-not (Test-Path $metrics)) { 'date,cr,unit,track,size,mode,result,attempts,tests_added,notes' | Out-File $metrics -Encoding utf8 }
$cost = if ($summary) { $summary.total_cost_usd } else { '' }
$note = ("run '{0}' cost_usd={1} turns={2} duration={3}" -f $Intent, $cost, $(if ($summary) { $summary.num_turns } else { '' }), $total).Replace(',', ';')
"$(Get-Date -Format 'yyyy-MM-dd'),,run,,,auto-headless,$(if ($ok) { 'done' } else { 'failed' }),,,$note" | Add-Content $metrics -Encoding utf8

$verdict = if ($ok) { 'GREEN' } else { 'RED' }
$cr = ''
if (Test-Path '.aidlc\progress.log') {
    $lastCr = Get-Content '.aidlc\progress.log' -Encoding UTF8 | Where-Object { $_ -match '^\S+ \| (CR-[^|]+?) \|' } | Select-Object -Last 1
    if ($lastCr -match '^\S+ \| (CR-[^|]+?) \|') { $cr = $Matches[1].Trim() }
}
# The runner's own verdict, after the independent regression, so watch.ps1 and the log show the final word.
Add-Content -Path '.aidlc\progress.log' -Value ("{0} | {1} | RUNNER VERDICT | {2} in {4} (independent regression; claude exit {3})" -f `
    (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'), $(if ($cr) { $cr } else { '-' }), $verdict, $claudeExit, $total) -Encoding utf8

Write-Host ''
Write-Host "Total time : $total  (Claude run plus the independent regression)"
Write-Host "Run folder : $runDir"
Write-Host 'Report     : docs/ops/auto-run-report.md'
Write-Host 'Next       : review the CR branch diff, run /aidlc-forge:step to ratify the auto-approved gates, then open a PR'

if (-not $NoNotify) {
    try {
        Add-Type -AssemblyName System.Windows.Forms, System.Drawing
        $n = New-Object System.Windows.Forms.NotifyIcon
        $n.Icon = if ($ok) { [System.Drawing.SystemIcons]::Information } else { [System.Drawing.SystemIcons]::Warning }
        $n.BalloonTipTitle = "AI-DLC run $verdict in $total"
        $n.BalloonTipText = "$(if ($cr) { $cr } else { 'aidlc' }) - see docs/ops/auto-run-report.md"
        $n.Visible = $true; $n.ShowBalloonTip(10000); Start-Sleep -Seconds 6; $n.Dispose()
    } catch { }
}

if (-not $ok) { Write-Host "AUTO RUN: RED in $total (Claude error, hard stop, or regression failure). See the run folder." -ForegroundColor Red; exit 1 }
Write-Host "AUTO RUN: GREEN in $total" -ForegroundColor Green
exit 0
