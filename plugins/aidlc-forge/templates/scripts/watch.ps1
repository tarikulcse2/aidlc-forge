<#
  Managed by the aidlc-forge plugin (templates/scripts/watch.ps1, v3.5.0). Re-run /aidlc-forge:init to update.

.SYNOPSIS
  Live progress of an AI-DLC run, with no AI involved. It refreshes every few seconds with the active CR, its status,
  gates and units, the latest events from .aidlc/progress.log and the elapsed time. It stops with
  "RUN COMPLETE: GREEN / RED / HARD STOP" when the run ends.
  Run it in a second terminal while /aidlc-forge:auto, /aidlc-forge:custom-workflow or aidlc-auto.ps1 is running.

.EXAMPLE
  .\scripts\aidlc\watch.ps1
  .\scripts\aidlc\watch.ps1 -Seconds 10 -Notify
  .\scripts\aidlc\watch.ps1 -Once
#>
param(
    [int] $Seconds = 5,     # refresh interval
    [switch] $Once,         # print one snapshot and exit
    [switch] $Notify        # Windows notification when the run completes
)

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$log = Join-Path $root '.aidlc\progress.log'

function Get-Flat([string[]] $lines, [string] $key) {
    foreach ($l in $lines) { if ($l -match "^$([regex]::Escape($key)):\s*(.*)$") { return $Matches[1].Trim() } }
    return ''
}

function Show-AidlcNotification([string] $title, [string] $text) {
    try {
        Add-Type -AssemblyName System.Windows.Forms, System.Drawing
        $n = New-Object System.Windows.Forms.NotifyIcon
        $n.Icon = [System.Drawing.SystemIcons]::Information
        $n.BalloonTipTitle = $title; $n.BalloonTipText = $text; $n.Visible = $true
        $n.ShowBalloonTip(10000); Start-Sleep -Seconds 6; $n.Dispose()
    } catch { }
}

function Show-Snapshot {
    $out = New-Object System.Collections.Generic.List[string]
    $project = Get-Flat (Get-Content (Join-Path $root '.aidlc\config.yaml') -Encoding UTF8 -ErrorAction SilentlyContinue) 'project'
    $out.Add("AI-DLC live progress - $project - $(Get-Date -Format 'HH:mm:ss')")
    $out.Add(('-' * 72))

    # Active CR: the most recently updated CR that isn't closed.
    $states = Get-ChildItem (Join-Path $root 'docs\changes') -Filter state.yaml -Recurse -Depth 1 -ErrorAction SilentlyContinue |
        Where-Object { (Get-Flat (Get-Content $_.FullName -Encoding UTF8) 'status') -ne 'closed' } |
        Sort-Object LastWriteTime -Descending
    if ($states) {
        $s = Get-Content $states[0].FullName -Encoding UTF8
        $handle = Get-Flat $s 'handle'; if (-not $handle -or $handle -eq 'CR-NNN-slug') { $handle = $states[0].Directory.Name }
        $ticket = Get-Flat $s 'ticket'; if ($ticket) { $handle = "$handle ($ticket)" }
        $out.Add("CR      : $handle - $(Get-Flat $s 'title')")
        $out.Add("Status  : $(Get-Flat $s 'status')    units $(Get-Flat $s 'units_done')/$(Get-Flat $s 'units_total')")
        $out.Add("Gates   : requirements=$(Get-Flat $s 'gate_requirements')  planning=$(Get-Flat $s 'gate_planning')  deploy=$(Get-Flat $s 'gate_deploy')")
        $units = Join-Path $states[0].Directory.FullName 'units.md'
        if (Test-Path $units) {
            $out.Add('Units   :')
            Get-Content $units -Encoding UTF8 | Where-Object { $_ -match '^###\s+U-\d+' } |
                ForEach-Object { $out.Add('  ' + ($_ -replace '^###\s+', '')) }
        }
        if ($states.Count -gt 1) { $out.Add("(+ $($states.Count - 1) other open CR(s); /aidlc-forge:status shows all)") }
    } else {
        $out.Add('No open CR yet (a new run creates one during requirements).')
    }

    # Events of the current run (since the last RUN START).
    $complete = $null
    if (Test-Path $log) {
        $lines = @(Get-Content $log -Encoding UTF8)
        $start = -1; for ($i = $lines.Count - 1; $i -ge 0; $i--) { if ($lines[$i] -match '\|\s*RUN START\s*\|') { $start = $i; break } }
        $run = if ($start -ge 0) { $lines[$start..($lines.Count - 1)] } else { $lines }
        if ($start -ge 0) {
            $t0 = [datetime]::Parse(($lines[$start] -split '\|')[0].Trim()).ToUniversalTime()
            $el = (Get-Date).ToUniversalTime() - $t0
            $out.Add("Elapsed : {0:hh\:mm\:ss} since RUN START" -f $el)
        }
        $quiet = [int]((Get-Date) - (Get-Item $log).LastWriteTime).TotalMinutes
        $out.Add(('-' * 72)); $out.Add('Latest events:')
        $run | Select-Object -Last 12 | ForEach-Object { $out.Add('  ' + $_) }
        $last = $run | Select-Object -Last 1
        if ($last -match '\|\s*RUN COMPLETE\s*\|\s*(.*)$') {
            $complete = $Matches[1].Trim()
            # Timing summary from the durations progress.sh appended (" in HH:MM:SS").
            $slowStep = $null; $slowUnit = $null; $stepT = [timespan]::Zero; $unitT = [timespan]::Zero
            foreach ($r in $run) {
                if ($r -match '\|\s*(STEP DONE|UNIT DONE|UNIT STOP)\s*\|\s*(.+?) in (\d{2}:\d{2}:\d{2})\s*$') {
                    $kind = $Matches[1]; $what = $Matches[2].Trim(); $t = [timespan]::Parse($Matches[3])
                    if ($kind -eq 'STEP DONE') { if ($t -gt $stepT) { $stepT = $t; $slowStep = "$what ($($Matches[3]))" } }
                    elseif ($t -gt $unitT) { $unitT = $t; $slowUnit = "$what ($($Matches[3]))" }
                }
            }
            $out.Add(('-' * 72))
            if ($start -ge 0) {
                $t1 = [datetime]::Parse(($last -split '\|')[0].Trim()).ToUniversalTime()
                $out.Add('Total   : {0:hh\:mm\:ss}  (RUN START -> RUN COMPLETE)' -f ($t1 - $t0))
            }
            if ($slowStep) { $out.Add("Slowest step : $slowStep") }
            if ($slowUnit) { $out.Add("Slowest unit : $slowUnit") }
        }
        elseif ($quiet -ge 10) { $out.Add("  (no new events for $quiet min: still working on a long step, or the run stopped)") }
    } else {
        $out.Add(('-' * 72)); $out.Add('No .aidlc/progress.log yet: it appears when an auto or custom-workflow run starts.')
    }

    if (-not $Once) { Clear-Host }
    $out | ForEach-Object { Write-Host $_ }
    return $complete
}

while ($true) {
    $done = Show-Snapshot
    if ($done) {
        $color = if ($done -match '^GREEN') { 'Green' } elseif ($done -match '^RED') { 'Red' } else { 'Yellow' }
        Write-Host ''; Write-Host "RUN COMPLETE: $done" -ForegroundColor $color
        Write-Host 'Report: docs/ops/auto-run-report.md - next: /aidlc-forge:step to ratify the auto gates'
        try { [Console]::Beep(880, 300) } catch { }
        if ($Notify) { Show-AidlcNotification 'AI-DLC run complete' $done }
        exit 0
    }
    if ($Once) { exit 0 }
    Start-Sleep -Seconds $Seconds
}
