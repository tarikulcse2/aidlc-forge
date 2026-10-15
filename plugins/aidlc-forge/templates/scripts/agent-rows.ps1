<#
  Managed by the aidlc-forge plugin (templates/scripts/agent-rows.ps1, v3.6.1). Re-run /aidlc-forge:init to update.

.SYNOPSIS
  Claude Code "subagentStatusLine" for aidlc-forge: rewrites the row of each running aidlc-forge agent in the agent
  panel below the prompt, e.g.
    coder - CR-006-admin-login U-12 Sign-out - green after 1 attempt(s) - 02:14 - 12.4k tokens
  A long row shortens its label; the time, token count and status always stay visible.
  Input (stdin): {"columns": n, "tasks": [{"id", "name", "agentType", "status", "description", "startTime", "tokenCount", "cwd", ...}]}
  Output: one JSON line per row it changes: {"id":"<task id>","content":"<row>"}. Other agents keep their default row.
  Read-only, no AI. Installed by /aidlc-forge:init into .claude/settings.local.json as
    "subagentStatusLine": { "type": "command",
      "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"<project>/scripts/aidlc/agent-rows.ps1\"" }
#>
$ErrorActionPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
$dot = ' ' + [char]0x00B7 + ' '

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $in = $raw | ConvertFrom-Json } catch { exit 0 }
$cols = if ($in.columns) { [int]$in.columns } else { 100 }

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$log = Join-Path $root '.aidlc\progress.log'
$lines = if (Test-Path $log) { @(Get-Content $log -Encoding UTF8 -Tail 400) } else { @() }
$nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

foreach ($t in @($in.tasks)) {
    $type = [string]$t.agentType
    if ($type -notlike 'aidlc-forge:*') { continue }                 # leave other agents' rows alone
    $role = $type.Substring('aidlc-forge:'.Length)
    $desc = [string]$t.description
    $row = "$role$dot$desc"

    # Latest progress line for this agent's CR and unit (from the PROGRESS: tag / its label).
    $handle = if ($desc -match '(CR-\d+[\w-]*)') { $Matches[1] } else { '' }
    $unit = if ($desc -match '\b(U-\d+)\b') { $Matches[1] } else { '' }
    # Each agent writes "<U-NN> <who>: ..."; only use this agent's own lines (the reviewer writes "review:").
    $who = switch ($role) { 'code-reviewer' { 'review' } 'devops' { 'deploy' } 'discovery-analyst' { 'discovery' } default { $role } }
    if ($handle -and $t.status -eq 'running') {
        for ($i = $lines.Count - 1; $i -ge 0; $i--) {
            $p = $lines[$i] -split '\|'
            if ($p.Count -lt 4) { continue }
            if ($p[2].Trim() -match 'RUN START') { break }             # only the current run
            if ($p[1].Trim() -eq $handle -and $p[2].Trim() -eq 'PROGRESS') {
                $d = $p[3].Trim()
                $rest = if ($unit) { $d -replace "^$unit\s+", '' } else { $d }
                if ((-not $unit -or $d -like "$unit *") -and $rest -like "${who}:*") {
                    $d = $d -replace "^$unit\s+", '' -replace '^[a-z-]+:\s*', ''
                    $row += "$dot$d"; break
                }
            }
        }
    }

    # The tail (time, tokens, status) always stays visible; a long row shortens its head (role, label, progress).
    $tail = ''
    if ($t.startTime) {
        $s = [math]::Max(0, [int](($nowMs - [int64]$t.startTime) / 1000))
        $tail += $dot + ('{0:00}:{1:00}' -f [math]::Floor($s / 60), ($s % 60))
    }
    # Token count, as in Claude Code's default row (e.g. 850 tokens, 12.4k tokens, 1.2M tokens).
    if ($null -ne $t.tokenCount -and "$($t.tokenCount)" -ne '') {
        $n = [double]$t.tokenCount; $inv = [System.Globalization.CultureInfo]::InvariantCulture
        $tok = if ($n -ge 1000000) { [string]::Format($inv, '{0:0.0}M', $n / 1000000) }
               elseif ($n -ge 1000) { [string]::Format($inv, '{0:0.0}k', $n / 1000) }
               else { [string]::Format($inv, '{0:0}', $n) }
        $tail += "$dot$tok tokens"
    }
    if ($t.status -and $t.status -ne 'running') { $tail += "$dot$($t.status)" }
    $room = $cols - $tail.Length
    if ($row.Length -gt $room) { $row = $row.Substring(0, [math]::Max(10, $room - 3)) + '...' }
    $row += $tail
    [Console]::Out.WriteLine((@{ id = [string]$t.id; content = $row } | ConvertTo-Json -Compress))
}
exit 0
