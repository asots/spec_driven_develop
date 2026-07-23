#requires -Version 5.1
# Spec-Driven Develop documentation self-check.
# Verifies version consistency (single source = SKILL.md frontmatter), referenced-file
# integrity, behavioral-rule numbering, and the cross-repo contract fingerprint shared
# with tav-workflow (escalation signals + delivery-batch write-back protocol).
# Run: pwsh scripts/verify.ps1 [-TavPath <path-to-tav-workflow-repo>]

param(
  [string]$TavPath = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$skillDir = Join-Path $root 'plugins/spec-driven-develop/skills/spec-driven-develop'
if ($TavPath -eq '') { $TavPath = Join-Path (Split-Path -Parent $root) 'tav-workflow' }
$script:fail = 0

function Fail($msg) { Write-Host "FAIL: $msg" -ForegroundColor Red; $script:fail++ }
function Ok($msg)   { Write-Host "OK:   $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "WARN: $msg" -ForegroundColor Yellow }

# Returns the text of a markdown section: from the heading line (matched by exact
# heading text, any #-level) to the next heading of the same or higher level.
function Get-Section([string]$text, [string]$heading) {
  $lines = $text -split "`r?`n"
  $start = -1
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match ('^(#{1,6})\s+' + [regex]::Escape($heading) + '\s*$')) { $start = $i; break }
  }
  if ($start -lt 0) { return $null }
  $level = ($lines[$start] -replace '^(#+).*$', '$1').Length
  $end = $lines.Count
  for ($i = $start + 1; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^(#{1,6})\s' -and $Matches[1].Length -le $level) { $end = $i; break }
  }
  return ($lines[$start..($end - 1)] -join "`n")
}

function Get-Bullets([string]$section) {
  @(($section -split "`r?`n") | Where-Object { $_ -match '^- ' } | ForEach-Object { $_.TrimEnd() })
}

# 1. SKILL.md frontmatter version is the single source of truth
$skillPath = Join-Path $skillDir 'SKILL.md'
$skill = Get-Content $skillPath -Raw -Encoding UTF8
if ($skill -notmatch '(?m)^\s*version:\s*(.+)$') { Fail 'SKILL.md frontmatter missing version'; $skillVer = '<none>' }
else { $skillVer = $Matches[1].Trim(); Ok "SKILL.md version = $skillVer (source of truth)" }

# 2. Every plugin manifest version must match
$manifests = @(
  'plugins/spec-driven-develop/.claude-plugin/plugin.json',
  'plugins/spec-driven-develop/.codex-plugin/plugin.json',
  '.claude-plugin/marketplace.json'
)
foreach ($m in $manifests) {
  $t = Get-Content (Join-Path $root $m) -Raw -Encoding UTF8
  if ($t -match '"version"\s*:\s*"([^"]+)"') {
    $v = $Matches[1].Trim()
    if ($v -ne $skillVer) { Fail "$m version = '$v' != SKILL.md '$skillVer'" }
    else { Ok "$m version = $v" }
  } else { Fail "$m has no version field" }
}

# 3. Every references/... file mentioned in SKILL.md exists
$failsBefore = $script:fail
$refs = [regex]::Matches($skill, 'references/[\w\-./]+\.(?:md|json)') | ForEach-Object { $_.Value } | Sort-Object -Unique
foreach ($r in $refs) {
  if (-not (Test-Path (Join-Path $skillDir $r))) { Fail "SKILL.md references missing file: $r" }
}
if ($script:fail -eq $failsBefore) { Ok "all $($refs.Count) referenced files exist" }

# 4. Agent definitions the workflow spawns exist
$failsBefore = $script:fail
foreach ($a in 'project-analyzer', 'task-architect', 'task-executor') {
  if (-not (Test-Path (Join-Path $root "plugins/spec-driven-develop/agents/$a.md"))) { Fail "missing agent definition: $a.md" }
}
if ($script:fail -eq $failsBefore) { Ok 'agent definitions exist' }

# 5. behavioral-rules.md numbering is a gapless 1..N sequence
$br = Get-Content (Join-Path $skillDir 'references/behavioral-rules.md') -Raw -Encoding UTF8
$nums = @([regex]::Matches($br, '(?m)^(\d+)\.\s+\*\*') | ForEach-Object { [int]$_.Groups[1].Value })
$expected = @(1..$nums.Count)
if ($nums.Count -eq 0) { Fail 'behavioral-rules.md contains no numbered rules' }
elseif (Compare-Object $nums $expected -SyncWindow 0) { Fail "behavioral-rules.md numbering broken: found $($nums -join ',')" }
else { Ok "behavioral-rules.md rules numbered 1..$($nums.Count) with no gaps" }

# 6. Cross-repo contract fingerprint with tav-workflow
$tavSkillPath = Join-Path $TavPath 'SKILL.md'
if (-not (Test-Path $tavSkillPath)) {
  Warn "tav-workflow not found at '$TavPath' - cross-repo contract checks skipped (pass -TavPath to enable)"
} else {
  $tav = Get-Content $tavSkillPath -Raw -Encoding UTF8

  # 6a. Escalation signal lists must match verbatim, bullet for bullet
  $spdSec = Get-Section $skill 'Escalation Signals'
  $tavSec = Get-Section $tav 'L2 Escalation Signals'
  if ($null -eq $spdSec) { Fail 'SKILL.md section "Escalation Signals" not found' }
  elseif ($null -eq $tavSec) { Fail 'tav SKILL.md section "L2 Escalation Signals" not found' }
  else {
    $spdB = Get-Bullets $spdSec
    $tavB = Get-Bullets $tavSec
    if ($spdB.Count -ne $tavB.Count) {
      Fail "escalation signals count differs: spd=$($spdB.Count) tav=$($tavB.Count)"
    } else {
      $mismatch = $false
      for ($i = 0; $i -lt $spdB.Count; $i++) {
        if ($spdB[$i] -ne $tavB[$i]) { Fail "escalation signal $($i + 1) differs:`n  spd: $($spdB[$i])`n  tav: $($tavB[$i])"; $mismatch = $true }
      }
      if (-not $mismatch) { Ok "escalation signals verbatim-identical across repos ($($spdB.Count) bullets)" }
    }
  }

  # 6b. Write-back protocol fingerprint: tav must carry the delivery-batch semantics
  if ($tav -match 'Close the Issue via PR') { Fail 'tav SKILL.md still contains pre-delivery-batch wording "Close the Issue via PR"' }
  else { Ok 'tav SKILL.md free of pre-delivery-batch write-back wording' }

  $tavOp = Get-Section $tav 'Operating Inside a Spec-Driven Project'
  if ($null -eq $tavOp) { Fail 'tav SKILL.md section "Operating Inside a Spec-Driven Project" not found' }
  else {
    $failsBefore = $script:fail
    foreach ($fp in 'Closes #N', 'do not create a task-level PR') {
      if ($tavOp -notlike "*$fp*") { Fail "tav write-back section missing fingerprint: '$fp'" }
    }
    if ($script:fail -eq $failsBefore) { Ok 'tav write-back section carries delivery-batch fingerprints' }
  }

  $spdBoundary = Get-Section $skill 'Boundary with TAV'
  if ($null -eq $spdBoundary) { Fail 'SKILL.md section "Boundary with TAV" not found' }
  elseif ($spdBoundary -notlike '*Closes #N*') { Fail 'spd "Boundary with TAV" missing delivery-batch fingerprint "Closes #N"' }
  else { Ok 'spd boundary section carries delivery-batch fingerprint' }

  # 6c. Cross-references by section name must resolve both ways
  if ($skill -notlike '*Operating Inside a Spec-Driven Project*') { Fail 'SKILL.md no longer cites tav section "Operating Inside a Spec-Driven Project"' }
  elseif ($tav -notlike '*Boundary with TAV*') { Fail 'tav SKILL.md no longer cites spd section "Boundary with TAV"' }
  else { Ok 'cross-repo section citations resolve both ways' }
}

if ($script:fail -gt 0) { Write-Host "`n$($script:fail) check(s) FAILED" -ForegroundColor Red; exit 1 }
Write-Host "`nAll checks passed" -ForegroundColor Green; exit 0
