#requires -Version 5.1
# Spec-Driven Develop documentation self-check; run it together with scripts/validate.sh.
# Checks what validate.sh does not: README/CHANGELOG version parity, SKILL.md references,
# behavioral-rule numbering and cited rule titles, section citations, contract fingerprints,
# the cross-repo contract shared with tav-workflow, and the decision-note contract shared
# with write-notes-like-deepseek. Manifest versions, agent files, the review-context smoke
# test, and the archive / GitHub-recovery / S.U.P.E.R-template invariants are validate.sh
# checks (b)-(j).
# Run: pwsh scripts/verify.ps1 [-TavPath <tav-workflow-repo>] [-DshPath <write-notes-like-deepseek-repo>]

param(
  [string]$TavPath = '',
  [string]$DshPath = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$skillDir = Join-Path $root 'plugins/spec-driven-develop/skills/spec-driven-develop'
$agentsDir = Join-Path $root 'plugins/spec-driven-develop/agents'
if ($TavPath -eq '') { $TavPath = Join-Path (Split-Path -Parent $root) 'tav-workflow' }
if ($DshPath -eq '') { $DshPath = Join-Path (Split-Path -Parent $root) 'write-notes-like-deepseek' }
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

# True when $text has a heading named exactly $anchor (optionally followed by a
# parenthetical qualifier), or a line-leading label, plain or bold, then ':' or '('.
function Test-Anchor([string]$text, [string]$anchor) {
  $a = [regex]::Escape($anchor)
  if ($text -match ('(?m)^#{1,6}\s+' + $a + '(\s+\([^)]*\))?\s*$')) { return $true }
  return ($text -match ('(?m)^\s*(?:[-*]\s+|\d+\.\s+)?(?:\*\*)?' + $a + '(?:\*\*)?\s*[:(]'))
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

# 2. README and CHANGELOG versions match SKILL.md (manifest versions: validate.sh check (c))
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

# 4. Agent files: validate.sh check (b)

# 5. behavioral-rules.md numbering is a gapless 1..N sequence
$br = Get-Content (Join-Path $skillDir 'references/behavioral-rules.md') -Raw -Encoding UTF8
$nums = @([regex]::Matches($br, '(?m)^(\d+)\.\s+\*\*') | ForEach-Object { [int]$_.Groups[1].Value })
$expected = @(1..$nums.Count)
if ($nums.Count -eq 0) { Fail 'behavioral-rules.md contains no numbered rules' }
elseif (Compare-Object $nums $expected -SyncWindow 0) { Fail "behavioral-rules.md numbering broken: found $($nums -join ',')" }
else { Ok "behavioral-rules.md rules numbered 1..$($nums.Count) with no gaps" }

# 5b. Every "rule N" / "rules N-M" citation names a pinned rule whose title is unchanged,
# so a renumbering cannot silently repoint a citation at a different rule
$rulePins = @{
  16 = 'Stable learnings go to the resolved memory surface'
  17 = 'Issues and PRs have different cardinality'
  18 = 'Reviewer boundaries are enforced, not advisory'
  19 = 'Sub-agent dispatch is an economic decision, not a default'
}
$docs = @(Get-Item (Join-Path $skillDir 'SKILL.md')) + @(Get-ChildItem -Path @((Join-Path $skillDir 'references'), $agentsDir) -Recurse -Filter '*.md')
$failsBefore = $script:fail
$cited = @{}
foreach ($doc in $docs) {
  foreach ($m in [regex]::Matches((Get-Content $doc.FullName -Raw -Encoding UTF8), '\b[Rr]ules? (\d+)(?:-(\d+))?\b')) {
    $first = [int]$m.Groups[1].Value
    $last = if ($m.Groups[2].Success) { [int]$m.Groups[2].Value } else { $first }
    foreach ($n in $first..$last) { $cited[$n] = $doc.Name }
  }
}
foreach ($n in $cited.Keys) {
  if (-not $rulePins.ContainsKey($n)) { Fail "$($cited[$n]) cites rule $n, which has no title pin in verify.ps1" }
}
foreach ($n in $rulePins.Keys) {
  if ($br -notmatch ('(?m)^' + $n + '\.\s+\*\*' + [regex]::Escape($rulePins[$n]) + '\*\*')) { Fail "behavioral rule $n is no longer '$($rulePins[$n])'" }
}
if ($script:fail -eq $failsBefore) { Ok "cited behavioral rules $((@($cited.Keys) | Sort-Object) -join ', ') keep their pinned titles" }

# 5c. Every quoted section citation resolves: `references/x.md` "Name" or `SKILL.md` "Name"
# (several names may follow one path, joined by and/or/commas)
$sect = [string][char]0x00A7
$cite = '`((?:references|examples)/[\w\-./]+\.md|SKILL\.md)`\s*(?:' + $sect + '\s*)?((?:"[^"\r\n]+"(?:\s*(?:,|and|or)\s*)?)+)'
$failsBefore = $script:fail
$citeCount = 0
foreach ($doc in $docs) {
  foreach ($m in [regex]::Matches((Get-Content $doc.FullName -Raw -Encoding UTF8), $cite)) {
    $target = Join-Path $skillDir $m.Groups[1].Value
    if (-not (Test-Path $target)) { Fail "$($doc.Name) cites missing file: $($m.Groups[1].Value)"; continue }
    $targetText = Get-Content $target -Raw -Encoding UTF8
    foreach ($q in [regex]::Matches($m.Groups[2].Value, '"([^"]+)"')) {
      $citeCount++
      if (-not (Test-Anchor $targetText $q.Groups[1].Value)) { Fail "$($doc.Name) cites missing section: $($m.Groups[1].Value) '$($q.Groups[1].Value)'" }
    }
  }
}
if ($script:fail -eq $failsBefore) { Ok "$citeCount section citations in SKILL.md, references/, and agents/ resolve" }

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
  'must be reported BLOCKED before editing',
  'contradicts a recorded decision'
)
Require-Fingerprints 'code-reviewer two-axis contract' $reviewer @(
  'Standards Axis',
  'Spec Axis',
  'never combine them into one score',
  'Machine Validation Run',
  'contradicts a recorded decision'
)
Require-Fingerprints 'parallel review contract' $parallel @(
  'Two-Axis Review Contract',
  'contradicts a recorded decision',
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
$progressTemplate = Get-Content (Join-Path $skillDir 'references/templates/progress.md') -Raw -Encoding UTF8

Require-Fingerprints 'GitHub authority gates' $github @(
  '## Authority Gates',
  'Commit authorization does not authorize',
  'Tier 2 must not start',
  'git add -- {task_specific_paths}',
  'stop after local integration validation'
)
if ($github -like '*git add -A*') { Fail 'github-integration.md still stages unrelated paths with git add -A' }
elseif ($github -like '*refs #{issue_1}, refs #{issue_2}*') { Fail 'github-integration.md still demonstrates one commit referencing multiple Issues' }
else { Ok 'GitHub commit examples are task-atomic and path-scoped' }

Require-Fingerprints 'task-card delivery shape and rollback' ($github + $parallel) @(
  '**Delivery Shape**: {delivery_shape}',
  '**Rollback Boundary**: {rollback_boundary}',
  'Per-task delivery shape, rollback boundary, and S.U.P.E.R design drivers',
  'Tracking mode, per-task delivery shape and rollback boundary, and the resolved instruction surfaces'
)
Require-Fingerprints 'optional OCR delegate in the Standards axis' ($parallel + $reviewer + $executor) @(
  'ocr delegate preview --format json',
  'ocr delegate rule --format json',
  'never install OCR during a review'
)
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

# 7. Cross-repo contract fingerprint with tav-workflow
# Since tav 3.16.0 the installable skill lives in skills/tav-workflow/ of the tav repo.
$tavSkillDir = Join-Path $TavPath 'skills/tav-workflow'
$tavSkillPath = Join-Path $tavSkillDir 'SKILL.md'
if (-not (Test-Path $tavSkillPath)) {
  $msg = "tav-workflow skill not found at '$tavSkillDir' - cross-repo contract checks skipped (pass -TavPath to enable)"
  if ($env:CI -eq 'true') { Fail $msg } else { Warn $msg }
} else {
  $tav = Get-Content $tavSkillPath -Raw -Encoding UTF8

  # 7a. TAV owns the task-level specialist disciplines. Since tav 3.13.0 the
  # branch contracts live in references/branches.md; SKILL.md keeps the triggers.
  $tavSections = @(
    @{ File = 'references/branches.md'; Name = 'Hard-bug diagnosis branch'; Fingerprints = @('red-capable', 'original feedback command') },
    @{ File = 'references/branches.md'; Name = 'TDD execution branch'; Fingerprints = @('highest stable public boundary', 'vertical behavior slice') },
    @{ File = 'SKILL.md'; Name = 'Two-axis review'; Fingerprints = @('Standards', 'Spec', 'Do not merge the axes into one score', 'contradicts a recorded decision') }
  )
  foreach ($entry in $tavSections) {
    $tavFile = Join-Path $tavSkillDir $entry.File
    $section = if (Test-Path $tavFile) { Get-Section (Get-Content $tavFile -Raw -Encoding UTF8) $entry.Name } else { $null }
    if ($null -eq $section) { Fail "tav $($entry.File) section '$($entry.Name)' not found" }
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

  $tavInteropPath = Join-Path $tavSkillDir 'references/spec-driven-interop.md'
  $tavOp = if (Test-Path $tavInteropPath) { Get-Section (Get-Content $tavInteropPath -Raw -Encoding UTF8) 'Operating Inside a Spec-Driven Project' } else { $null }
  if ($null -eq $tavOp) { Fail 'tav references/spec-driven-interop.md section "Operating Inside a Spec-Driven Project" not found' }
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

  # 7c'. Intake parity: each input-mapping row has a matching TAV task-intake bullet
  $intakeFields = @(
    @{ Row = 'Task description'; Tav = 'task definition' },
    @{ Row = 'Acceptance criteria + test expectation'; Tav = 'acceptance criteria and explicit test expectation' },
    @{ Row = 'S.U.P.E.R design drivers'; Tav = 'S.U.P.E.R design drivers' },
    @{ Row = 'Relevant files / dependencies'; Tav = 'relevant/affected files and dependencies' },
    @{ Row = 'Delivery batch, delivery shape, and rollback boundary'; Tav = 'delivery-batch ID, delivery shape, and rollback boundary' },
    @{ Row = 'Memory/governance impact'; Tav = 'memory/governance impact' }
  )
  $mapping = [regex]::Match($spdBoundary, '(?s)\*\*Input mapping.*?(?=\*\*Write-back mapping)').Value
  $rowNames = @(($mapping -split "`r?`n") | Where-Object { $_ -match '^\|\s*[^\s|:-]' } | Select-Object -Skip 1 | ForEach-Object { ($_ -split '\|')[1].Trim() })
  $intake = [regex]::Match($tavOp, '(?s)\*\*Task intake \(Thinker\):\*\*.*?(?=\r?\n\*\*)').Value
  $failsBefore = $script:fail
  if ($rowNames.Count -ne $intakeFields.Count) { Fail "input mapping has $($rowNames.Count) rows; the intake parity list expects $($intakeFields.Count)" }
  foreach ($f in $intakeFields) {
    if ($rowNames -notcontains $f.Row) { Fail "input mapping lacks row '$($f.Row)'" }
    if (-not $intake.Contains($f.Tav)) { Fail "tav task intake lacks '$($f.Tav)'" }
  }
  if ($script:fail -eq $failsBefore) { Ok "input mapping and tav task intake carry the same $($intakeFields.Count) fields" }

  # 7d. Cross-references by section name must resolve both ways
  if ($skill -notlike '*Operating Inside a Spec-Driven Project*') { Fail 'SKILL.md no longer cites tav section "Operating Inside a Spec-Driven Project"' }
  elseif ($tav -notlike '*Boundary with TAV*') { Fail 'tav SKILL.md no longer cites spd section "Boundary with TAV"' }
  else { Ok 'cross-repo section citations resolve both ways' }
}

# 8. Decision-note contract with write-notes-like-deepseek: every .agents/notes/<folder>/
# named here must be a lifecycle (or the archive) that DSH's tree gate accepts
$dshSkillDir = Join-Path $DshPath 'skills/write-notes-like-deepseek'
$dshTreePath = Join-Path $dshSkillDir 'scripts/agent-note-tree.ts'
if (-not (Test-Path $dshTreePath)) {
  $msg = "write-notes-like-deepseek not found at '$DshPath' - decision-note contract checks skipped (pass -DshPath to enable)"
  if ($env:CI -eq 'true') { Fail $msg } else { Warn $msg }
} else {
  $tree = Get-Content $dshTreePath -Raw -Encoding UTF8
  $failsBefore = $script:fail
  if ((Get-Content (Join-Path $dshSkillDir 'SKILL.md') -Raw -Encoding UTF8) -notmatch '(?m)^name:\s*write-notes-like-deepseek\s*$') { Fail 'DSH SKILL.md name is no longer write-notes-like-deepseek' }
  if (-not $tree.Contains("'.agents/notes'")) { Fail 'DSH tree gate no longer defaults to .agents/notes' }
  $life = [regex]::Match($tree, 'AGENT_NOTE_LIFECYCLES\s*=\s*\[([^\]]*)\]')
  $arch = [regex]::Match($tree, 'AGENT_NOTE_ARCHIVE\s*=\s*''([^'']+)''')
  if (-not $life.Success -or -not $arch.Success) { Fail 'DSH tree gate lifecycle or archive constant not found' }
  else {
    $allowed = @([regex]::Matches($life.Groups[1].Value, '''([^'']+)''') | ForEach-Object { $_.Groups[1].Value }) + $arch.Groups[1].Value
    foreach ($l in 'proposed', 'implemented', 'rejected', 'archived') {
      if ($allowed -notcontains $l) { Fail "DSH tree gate no longer accepts '$l', which rule 16's decision-note lifecycle names" }
    }
    foreach ($doc in $docs) {
      foreach ($m in [regex]::Matches((Get-Content $doc.FullName -Raw -Encoding UTF8), '\.agents/notes/([a-z-]+)/')) {
        if ($allowed -notcontains $m.Groups[1].Value) { Fail "$($doc.Name) names unknown decision-note folder: .agents/notes/$($m.Groups[1].Value)/" }
      }
    }
  }
  if ($script:fail -eq $failsBefore) { Ok 'decision-note folders and lifecycles match the write-notes-like-deepseek tree gate' }
}

if ($script:fail -gt 0) { Write-Host "`n$($script:fail) check(s) FAILED" -ForegroundColor Red; exit 1 }
Write-Host "`nAll checks passed" -ForegroundColor Green; exit 0
