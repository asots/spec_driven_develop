#requires -Version 5.1
# Spec-Driven Develop documentation self-check.
# Verifies version consistency (single source = SKILL.md frontmatter), referenced-file
# integrity, behavioral-rule numbering, integrated-discipline semantic fingerprints,
# and the cross-repo contract shared with tav-workflow.
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

function Require-Fingerprints([string]$name, [string]$text, [string[]]$fingerprints) {
  $failsBefore = $script:fail
  foreach ($fp in $fingerprints) {
    if ($text -notlike "*$fp*") { Fail "$name missing fingerprint: '$fp'" }
  }
  if ($script:fail -eq $failsBefore) { Ok "$name carries required fingerprints" }
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

$readmeVersionChecks = @(
  @{ Path = 'README.md'; Pattern = '\*\*Current version\*\*:\s*([^\s—]+)'; Label = 'Current version' },
  @{ Path = 'README.zh-CN.md'; Pattern = '\*\*当前版本\*\*：\s*([^\s—]+)'; Label = '当前版本' }
)
foreach ($check in $readmeVersionChecks) {
  $text = Get-Content (Join-Path $root $check.Path) -Raw -Encoding UTF8
  if ($text -notmatch $check.Pattern) { Fail "$($check.Path) lacks $($check.Label)" }
  elseif ($Matches[1].Trim() -ne $skillVer) { Fail "$($check.Path) $($check.Label) != SKILL.md $skillVer" }
  else { Ok "$($check.Path) $($check.Label) = $skillVer" }
}

$changelog = Get-Content (Join-Path $root 'CHANGELOG.md') -Raw -Encoding UTF8
if ($changelog -notmatch ('(?m)^## Version ' + [regex]::Escape($skillVer) + ' \(')) {
  Fail "CHANGELOG.md has no entry for current version $skillVer"
} else { Ok "CHANGELOG.md records current version $skillVer" }

# 3. Every references/... file mentioned in SKILL.md exists
$failsBefore = $script:fail
$refs = [regex]::Matches($skill, 'references/[\w\-./]+\.(?:md|json)') | ForEach-Object { $_.Value } | Sort-Object -Unique
foreach ($r in $refs) {
  if (-not (Test-Path (Join-Path $skillDir $r))) { Fail "SKILL.md references missing file: $r" }
}
if ($script:fail -eq $failsBefore) { Ok "all $($refs.Count) referenced files exist" }

# 4. Agent definitions the workflow spawns exist
$failsBefore = $script:fail
foreach ($a in 'project-analyzer', 'task-architect', 'task-executor', 'code-reviewer') {
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

# 6. Integrated planning, execution, and review discipline fingerprints
$disciplineRefs = @(
  'references/domain-modeling.md',
  'references/wayfinding.md',
  'references/decomposition-strategy.md'
)
$failsBefore = $script:fail
foreach ($r in $disciplineRefs) {
  if ($skill -notlike "*$r*") { Fail "SKILL.md missing canonical reference: '$r'" }
  elseif (-not (Test-Path (Join-Path $skillDir $r))) { Fail "canonical reference missing: '$r'" }
}
if ($script:fail -eq $failsBefore) { Ok 'integrated discipline references resolve' }

Require-Fingerprints 'SKILL.md planning/review contract' $skill @(
  'Conditional Wayfinding Gate',
  'record the selected delivery shape on every task card',
  'references/parallel-protocol.md',
  'independent authority gates'
)
Require-Fingerprints 'behavioral-rules.md additions' $br @(
  '23. **Version-control and external-write authority is explicit**',
  '24. **Resolve decision fog before decomposition**',
  '25. **Default behavior changes to vertical tracer slices; wide refactors use expand-contract**'
)

$executor = Get-Content (Join-Path $root 'plugins/spec-driven-develop/agents/task-executor.md') -Raw -Encoding UTF8
$reviewer = Get-Content (Join-Path $root 'plugins/spec-driven-develop/agents/code-reviewer.md') -Raw -Encoding UTF8
$parallel = Get-Content (Join-Path $skillDir 'references/parallel-protocol.md') -Raw -Encoding UTF8
Require-Fingerprints 'task-executor fallback contract' $executor @(
  'red-capable feedback loop',
  'highest stable public seam',
  'vertical RED',
  'Standards Review',
  'Spec Review',
  'must be reported BLOCKED before editing'
)
Require-Fingerprints 'code-reviewer two-axis contract' $reviewer @(
  'Standards Axis',
  'Spec Axis',
  'never combine them into one score',
  'Machine Validation Run'
)
Require-Fingerprints 'parallel review contract' $parallel @(
  'Two-Axis Review Contract',
  'explicit branch/worktree plus commit authorization',
  'downgrade the batch to Tier 0/1'
)

$github = Get-Content (Join-Path $skillDir 'references/github-integration.md') -Raw -Encoding UTF8
$planTemplate = Get-Content (Join-Path $skillDir 'references/templates/plan.md') -Raw -Encoding UTF8
$taskDefinitionTemplate = Get-Content (Join-Path $skillDir 'references/templates/task-definition.md') -Raw -Encoding UTF8
$analysisTemplate = Get-Content (Join-Path $skillDir 'references/templates/analysis.md') -Raw -Encoding UTF8
$wayfinding = Get-Content (Join-Path $skillDir 'references/wayfinding.md') -Raw -Encoding UTF8
$decomposition = Get-Content (Join-Path $skillDir 'references/decomposition-strategy.md') -Raw -Encoding UTF8
$adaptive = Get-Content (Join-Path $skillDir 'references/adaptive-control.md') -Raw -Encoding UTF8
$super = Get-Content (Join-Path $skillDir 'references/super-philosophy.md') -Raw -Encoding UTF8
$archiveTemplate = Get-Content (Join-Path $skillDir 'references/templates/archive.md') -Raw -Encoding UTF8
$progressTemplate = Get-Content (Join-Path $skillDir 'references/templates/progress.md') -Raw -Encoding UTF8

Require-Fingerprints 'GitHub authority gates' $github @(
  '## Authority Gates',
  'Commit authorization does not authorize',
  'Tier 2 must not start',
  'git add -- {task_specific_paths}',
  'stop after local integration validation'
)
Require-Fingerprints 'GitHub Project recovery contract' $github @(
  'exact lookup → contract check → reuse/create → immediate ledger write',
  'ITEM_MATCH_COUNT',
  'record ITEM_JSON id',
  'Field or item identity lookup/create failures are blocking'
)
if ($github -like '*git add -A*') { Fail 'github-integration.md still stages unrelated paths with git add -A' }
elseif ($github -like '*refs #{issue_1}, refs #{issue_2}*') { Fail 'github-integration.md still demonstrates one commit referencing multiple Issues' }
else { Ok 'GitHub commit examples are task-atomic and path-scoped' }

Require-Fingerprints 'plan template delivery and authority contract' $planTemplate @(
  'Standalone Docs, Governance, Validation, Release, or Archive tasks',
  'branch/worktree and commit authorization',
  'instead of returning uncommitted lane worktrees'
)
Require-Fingerprints 'Phase 2 task-definition template' $taskDefinitionTemplate @(
  '## Goal',
  '## Non-goals',
  '## Acceptance Criteria',
  '## Dependencies',
  '## Rollback Boundary',
  '## Testing Policy',
  '## Domain Decisions and Write-Back',
  '## S.U.P.E.R Priorities',
  '## Governance and Memory Decision',
  'Change this document before changing downstream task cards'
)
Require-Fingerprints 'archive template contract' $archiveTemplate @(
  'docs/archives/<project-name>/<run-id>/',
  './<project-name>/<run-id>/progress/MASTER.md',
  'locally validated — awaiting remote sync'
)
Require-Fingerprints 'archived MASTER tombstone contract' $progressTemplate @(
  '## Archived MASTER.md Tombstone',
  '**Workflow State**: archived',
  '**Archive MASTER**:',
  '**Pending Operations**:',
  'This file is a recovery pointer, not an active task tracker.'
)
Require-Fingerprints 'core tombstone lifecycle' $skill @(
  '**Workflow State**: archived',
  'Pending Operations',
  'do not reconstruct active task execution from the tombstone'
)
if ($archiveTemplate -like '*<project-name>-<run-id>*') { Fail 'archive template still uses flattened project-run naming' }
else { Ok 'archive template uses only the canonical nested run path' }

if ($planTemplate.Contains('**S (Single Purpose)**') -or $planTemplate.Contains('**R (Replaceable Parts)**')) {
  Fail 'plan template still redefines canonical S.U.P.E.R principles'
} elseif ($planTemplate -notlike '*references/super-philosophy.md*') {
  Fail 'plan template no longer cites the canonical S.U.P.E.R reference'
} else { Ok 'plan template references S.U.P.E.R without redefining it' }

if ($parallel -notlike '*references/adaptive-control.md*"Canonical Storage"*"Controller Activation"*') {
  Fail 'parallel-protocol.md does not delegate storage and activation to adaptive-control.md'
} else { Ok 'parallel protocol keeps only orchestration timing and writer boundaries' }

if ($br -notlike '*references/parallel-protocol.md*"Writer model"*') {
  Fail 'behavioral reviewer rule no longer cites the canonical writer model'
} elseif ($br -like '*Reviewers never create or comment on GitHub Issues/PRs*') {
  Fail 'behavioral-rules.md still duplicates the detailed reviewer writer model'
} else { Ok 'behavioral reviewer rule is a concise safety boundary plus canonical pointer' }
Require-Fingerprints 'analysis coverage and affected-boundary contract' ($analysisTemplate + $planTemplate + $skill) @(
  'Coverage',
  'deep / shallow',
  'Affected Files',
  'declared affected files/modules/contracts/prerequisites',
  'task-definition.md'
)
Require-Fingerprints 'wayfinding boundary contract' $wayfinding @(
  'research | prototype | grilling | investigation',
  'may not leave persistent product changes behind',
  'one active non-research decision at a time',
  'may resolve several decisions sequentially'
)
if ($wayfinding -like '*prerequisite-task*' -or $wayfinding -like '*Resolve no more than one non-research decision per session*') {
  Fail 'wayfinding.md still carries the conflicting prerequisite-task or per-session decision limit'
} else { Ok 'wayfinding.md is sequential-per-agent and preparation-only' }

Require-Fingerprints 'decomposition strategy scope' $decomposition @(
  '## Default: Vertical Tracer Slices for Behavior Changes',
  '## Non-Behavior Operational Tasks',
  'Do not disguise maintenance or milestone work as user-visible behavior'
)

$failsBefore = $script:fail
Require-Fingerprints 'adaptive-control event protocol' $adaptive @(
  '## Execution Events',
  '## Response Levels',
  '### Watch',
  '### Replan',
  '### Rescope',
  '## Canonical Storage',
  'one authoritative task record',
  'lightweight progress mirror'
)
foreach ($legacy in 'task_drift =', 'threshold_annotate', 'threshold_replan', 'threshold_rescope', 'Milestone description YAML') {
  if ($adaptive -like "*$legacy*") { Fail "adaptive-control.md still carries legacy scoring/threshold contract: '$legacy'" }
}
if ($script:fail -eq $failsBefore) { Ok 'adaptive control is event-driven and free of legacy scoring thresholds' }

Require-Fingerprints 'S.U.P.E.R scope contract' $super @(
  '## E — Environment-Appropriate',
  'Run the checks that match the task''s declared S.U.P.E.R drivers',
  'Unrelated checks are not scored.'
)
if ($super -like '*Environment-Agnostic*') { Fail 'super-philosophy.md still uses the obsolete Environment-Agnostic principle' }
else { Ok 'S.U.P.E.R is environment-appropriate and task-scoped' }

if ($executor -like '*Think (steps 1-2)*' -or $executor -like '*Act (step 3)*' -or $executor -like '*refs #{issue_1}, refs #{issue_2}*' -or $executor -like '*reviewer fixes remain identified, uncommitted worktree changes*') {
  Fail 'task-executor.md still carries brittle step mapping, a multi-Issue commit, or an uncommitted Tier 2 reviewer handoff'
} else { Ok 'task-executor role mapping and commit example are stable and task-atomic' }

if ($reviewer -like '*uncommitted worktree change*' -or $reviewer -like '*explicitly identified uncommitted fixes*') {
  Fail 'code-reviewer.md still permits an uncommitted Tier 2 review handoff'
} else { Ok 'code-reviewer fixes are authorized append-only commits or ESCALATE' }

$smokeOutput = & python scripts/smoke-review-context.py 2>&1
if ($LASTEXITCODE -ne 0) { Fail "review-context UTF-8 smoke test failed: $($smokeOutput -join ' ')" }
else { Ok 'review-context UTF-8 smoke test passed' }

# 7. Cross-repo contract fingerprint with tav-workflow
$tavSkillPath = Join-Path $TavPath 'SKILL.md'
if (-not (Test-Path $tavSkillPath)) {
  Warn "tav-workflow not found at '$TavPath' - cross-repo contract checks skipped (pass -TavPath to enable)"
} else {
  $tav = Get-Content $tavSkillPath -Raw -Encoding UTF8

  # 7a. TAV owns the task-level specialist disciplines
  $tavSections = @(
    @{ Name = 'Hard-bug diagnosis branch'; Fingerprints = @('red-capable', 'original feedback command') },
    @{ Name = 'TDD execution branch'; Fingerprints = @('highest stable public boundary', 'vertical behavior slice') },
    @{ Name = 'Two-axis review'; Fingerprints = @('Standards', 'Spec', 'Do not merge the axes into one score') }
  )
  foreach ($entry in $tavSections) {
    $section = Get-Section $tav $entry.Name
    if ($null -eq $section) { Fail "tav SKILL.md section '$($entry.Name)' not found" }
    else { Require-Fingerprints "tav section '$($entry.Name)'" $section $entry.Fingerprints }
  }

  # 7b. Escalation signal lists must match verbatim, bullet for bullet
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

  $fallback = 'A refactor confined to one module — however messy — stays at L1 (TAV territory).'
  if ($spdSec -notlike "*$fallback*" -or $tavSec -notlike "*$fallback*") {
    Fail 'L2 fallback sentence is not verbatim-identical across repos'
  } else { Ok 'L2 fallback sentence is verbatim-identical across repos' }

  # 7c. Write-back protocol fingerprint: tav must carry the delivery-batch semantics
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

  $canonicalPayload = 'Outcome, Rework, Plan returns, Unplanned dependencies, and Focused S.U.P.E.R result'
  if ($spdBoundary -notlike "*$canonicalPayload*") { Fail 'spd boundary lacks the canonical execution-event payload' }
  elseif ($tavOp -notlike "*$canonicalPayload*") { Fail 'tav interop section lacks the canonical execution-event payload' }
  else { Ok 'execution-event payload is canonical and mirrored across repos' }

  $contractId = 'spec-tav/v1'
  if ($spdBoundary -notlike "*$contractId*") { Fail "spd boundary lacks handoff contract ID $contractId" }
  elseif ($tavOp -notlike "*$contractId*") { Fail "tav interop section lacks handoff contract ID $contractId" }
  else { Ok "handoff contract ID $contractId is mirrored across repos" }

  $statePattern = '(?ms)\*\*State ownership:\*\*\s*(.*?)(?:\n---|\z)'
  $spdStateMatch = [regex]::Match($spdBoundary, $statePattern)
  $tavStateMatch = [regex]::Match($tavOp, $statePattern)
  if (-not $spdStateMatch.Success -or -not $tavStateMatch.Success) {
    Fail 'state ownership block missing from one side of the handoff contract'
  } else {
    $spdState = ($spdStateMatch.Groups[1].Value -replace "`r", '').Trim()
    $tavState = ($tavStateMatch.Groups[1].Value -replace "`r", '').Trim()
    if ($spdState -ne $tavState) { Fail 'state ownership block differs across repos' }
    else { Ok 'three-layer state ownership block is mirrored across repos' }
  }

  # 7d. Cross-references by section name must resolve both ways
  if ($skill -notlike '*Operating Inside a Spec-Driven Project*') { Fail 'SKILL.md no longer cites tav section "Operating Inside a Spec-Driven Project"' }
  elseif ($tav -notlike '*Boundary with TAV*') { Fail 'tav SKILL.md no longer cites spd section "Boundary with TAV"' }
  else { Ok 'cross-repo section citations resolve both ways' }
}

if ($script:fail -gt 0) { Write-Host "`n$($script:fail) check(s) FAILED" -ForegroundColor Red; exit 1 }
Write-Host "`nAll checks passed" -ForegroundColor Green; exit 0
