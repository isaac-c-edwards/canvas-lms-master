# Feature 1 — Implementation evidence (Lab 3.2)

## Slice implemented

**Issue #2:** [Feature 1] Backend: What-if grade calculation engine (uniform %, points, weights)

**Project item id:** `185630669`  
**Project:** https://github.com/users/isaac-c-edwards/projects/1

## Board status timeline

| When | Item | Status |
|------|------|--------|
| 2026-05-19 | #2 Backend calculation engine | Todo → **In progress** (MCP `projects_write`, option `47fc9ee4`) |
| _pending merge_ | #2 | **In progress** → **Done** (`98236657`) after PR merge |

## Pull request

**PR:** https://github.com/isaac-c-edwards/canvas-lms-master/pull/11

**Branch:** `feature/2-what-if-calculator-engine`

**What changed:**

- Added `WhatIfRequiredGradeCalculator` (`lib/what_if_required_grade_calculator.rb`)
- Read-only uniform required-% math for total-points and weighted groups
- RSpec coverage in `spec/lib/what_if_required_grade_calculator_spec.rb`
- Agent spec: `agents/feature-implementation.md`

## Merge evidence

**Status:** ⏸ **PAUSED — awaiting human review and merge**

- [x] PR opened
- [ ] PR merged to `main`
- [ ] Merge commit URL recorded below

_Merge URL:_ (fill after merge)

## Plan trace

This slice implements **milestone 1** from `implementation-research.md` (grade
calculation logic) and maps to **FR1** (uniform calculation), **FR2** (point-based
courses), and **FR3** (weighted assignment groups) via pure Ruby aggregation.
It deliberately excludes drop-lowest (FR5), student API (#3), and React UI (#4)
for a reviewable Lab 3.2 cycle. Existing Canvas `GradeCalculator` / what-if score
storage was investigated; this feature uses a separate reverse-target calculator
aligned with the project issue #2 and test issue #8.

## Verification performed

- [ ] `bin/rspec spec/lib/what_if_required_grade_calculator_spec.rb` (record output after run)
- [ ] Manual Canvas check (N/A for this backend-only slice)

## MCP notes

GitHub MCP used to set issue #2 project item to **In progress** before implementation.
**Done** will be set via MCP after merge (see `agents/feature-implementation.md`).
