# Feature 1 — Implementation evidence

Traceability log for the **What-If Grade Calculator**: pull requests, project board
status, merge commits, verification, and plan alignment. Updated as slices land on
`main`.

## Project summary

| Item | Value |
|------|-------|
| **Repo** | https://github.com/isaac-c-edwards/canvas-lms-master |
| **Integration branch** | `main` |
| **Agent spec** | `agents/feature-implementation.md` |
| **GitHub Project** | https://github.com/users/isaac-c-edwards/projects/1 |
| **Feature research** | `agents/tasks/feature-1/implementation-research.md`, `feature-1.md` |

**Delivery status:** Five plan-aligned slices merged (PRs #11–#14). Calculator, API,
UI, and polish/tests are on `main`.

**Demo environment (verified 2026-05-19):**

- URL: http://18.210.170.91/courses/1/grades
- Course: *What-If Test Course* (id **1**) — total-points grading; Midterm 800/800
  graded, Final 200 pts ungraded (1000 pts possible)
- Student: `student@example.com` / `password`
- Post-merge: `git pull origin main` on EC2; smoke test confirmed panel, slider,
  toggle, and gray grade-table estimates

**Remaining work:**

| Issue | Title | Status |
|-------|-------|--------|
| #1 | Spike / brownfield investigation | Open on board — conclusions recorded in `implementation-research.md` §4 |
| #7 | NFR performance + a11y spot-check | Open — labeled inputs and abort-on-stale fetch in UI; full audit deferred |
| #10 | Manual spreadsheet verification | Documented below for demo course; weighted-course scenario deferred |

---

## Slice #2 — Backend calculation engine

**Issue #2:** Backend: What-if grade calculation engine (uniform %, points, weights)

**Project item id:** `185630669`

### Board status timeline

| When | Item | Status |
|------|------|--------|
| 2026-05-19 | #2 Backend calculation engine | Todo → **In progress** (MCP `projects_write`, option `47fc9ee4`) |
| 2026-05-19 | #2 Backend calculation engine | **In progress** → **Done** (`98236657`) after PR #11 merge |

### Pull request

**PR:** https://github.com/isaac-c-edwards/canvas-lms-master/pull/11

**Branch:** `feature/2-what-if-calculator-engine`

**What changed:**

- Added `WhatIfRequiredGradeCalculator` (`lib/what_if_required_grade_calculator.rb`)
- Read-only uniform required-% math for total-points and weighted assignment groups
- RSpec coverage in `spec/lib/what_if_required_grade_calculator_spec.rb`
- Agent spec: `agents/feature-implementation.md`

### Merge evidence

**Status:** ✅ **Merged**

- [x] PR opened
- [x] PR merged to `main`
- [x] Issue #2 → **Done** on project board

**Merge commit:** https://github.com/isaac-c-edwards/canvas-lms-master/commit/8977646c62fb7a5085f56ff12595e9c2e57a2141

### Plan trace

Implements **milestone 1** from `implementation-research.md` (grade calculation logic):
**FR1** (uniform calculation), **FR2** (point-based courses), **FR3** (weighted
groups) via pure Ruby aggregation. Brownfield spike (#1) concluded a separate
reverse-target calculator was needed rather than reusing Canvas what-if score storage.
Drop-lowest (FR5) intentionally excluded in v1.

### Verification performed

- [x] `bin/rspec spec/lib/what_if_required_grade_calculator_spec.rb`
- [x] No DB writes in calculator layer (read-only math)

### MCP notes

GitHub MCP set issue #2 to **In progress** before implementation and **Done** after
PR #11 merge (2026-05-19).

---

## Slice #3 — Student read-only API

**Issue #3:** Backend: Student-facing read-only API for what-if result

**Project item id:** `185630670`

**Branch:** `feature/3-what-if-required-grade-api`

**Endpoint:** `GET /api/v1/courses/:course_id/what_if/required_grade?target_percent=`

**PR:** https://github.com/isaac-c-edwards/canvas-lms-master/pull/12

**Status:** ✅ **Merged**

- [x] PR opened
- [x] PR merged to `main`
- [x] Issue #3 → **Done** on project board (2026-05-19)

**Merge commit:** https://github.com/isaac-c-edwards/canvas-lms-master/commit/85aaba48050c959fe5790568f5a53e4c9190b7f7

**What changed:**

- `WhatIfRequiredGradesApiController` + `WhatIf::RequiredGradeService`
- Student session auth (`read_grades`, `hide_final_grades` guard)
- Service/controller RSpec coverage

**Plan trace:** Student-facing read-only surface per NFR Security & Privacy; wires
calculator (#2) to Course / AssignmentGroup / Submission data for the React client (#4).

### Verification performed

- [x] `bin/rspec spec/services/what_if/required_grade_service_spec.rb`
- [x] `bin/rspec spec/controllers/what_if_required_grades_api_controller_spec.rb`

---

## Slice #4 — What-if UI (#4, #5, #6)

**Issues:**

| Issue | Scope |
|-------|-------|
| #4 | React/TS panel, positive framing, slider wiring |
| #5 | Unreachable target error (FR4) |
| #6 | Drop-lowest disclaimer (FR5) |

**Project item ids:** `#4` `185630673`, `#5` `185630675`, `#6` `185630680`

**Branch:** `feature/4-what-if-required-grade-ui`

**PR:** https://github.com/isaac-c-edwards/canvas-lms-master/pull/13

**Status:** ✅ **Merged**

- [x] PR opened
- [x] PR merged to `main`
- [x] Issues #4, #5, #6 → **Done** on project board (2026-05-19)

**Merge commit:** https://github.com/isaac-c-edwards/canvas-lms-master/commit/a7304d7dcbec394b9a7ddec372c86db34d31e7b7

**What changed:**

- `ui/features/what_if_required_grade/` — **Path to Your Goal** panel on grade summary
- Feature bundle registration; mount point in `grade_summary.html.erb`
- Distinct a11y labels; `AbortController` cancels stale API calls on slider change
- Unreachable-target messaging and drop-lowest disclaimer in panel copy

**Plan trace:** Milestone 2 from research (frontend input/slider, positive framing).
Maps to FR1–FR3 via UX, FR4 error handling, FR5 scope disclaimer.

### Verification performed

- [x] `yarn test ui/features/what_if_required_grade/react/__tests__/WhatIfRequiredGradePanel.test.tsx`
- [x] Manual EC2: student Grades → **Path to Your Goal** panel renders (post PR #14 mount fix)

---

## Slice #5 — Polish, tests, grade table estimates (#8, #9, #10)

**Issues:**

| Issue | Scope |
|-------|-------|
| #8 | RSpec for calculation module + service extensions |
| #9 | Vitest for React panel (toggle, fetch, error states) |
| #10 | Manual verification against spreadsheet |

**Branch:** `feature/14-path-to-goal-polish`

**PR:** https://github.com/isaac-c-edwards/canvas-lms-master/pull/14

**Status:** ✅ **Merged**

- [x] PR opened
- [x] PR merged to `main`
- [x] Issues #8, #9 → **Closed** via PR (2026-05-19)

**Merge commit:** https://github.com/isaac-c-edwards/canvas-lms-master/commit/1f478aec92da3125e13ba38f6d257fb8f2ba103b

**What changed:**

- **Mount fix:** `js_bundle :what_if_required_grade` moved after `load_grade_summary_data` in `GradebooksController` so `@presenter.editable?` is set and the bundle loads
- **Opt-in toggle:** `ToggleDetails` — panel collapsed by default; no API calls or gray estimates until opened
- **Slider/input fix:** Correct Instructure UI `RangeInput` / `NumberInput` callback signatures
- **`estimated_assignments`:** Service returns per-assignment estimates; `pathToGoalEstimates.js` paints gray italic scores on ungraded rows; totals recalc via GradeSummary jQuery
- **Styles:** `.what-if-path-estimate` in `grade_summary.scss`
- **Tests:** Extended `required_grade_service_spec.rb`; panel tests for toggle/fetch/clear behavior
- **Ops scripts:** `agents/scripts/ec2-bootstrap-fix.sh`, `setup_course.rb`, `setup_student_demo.rb`

**Plan trace:** Closes automated test gaps (#8, #9) from research §5; integrates
calculator output into the grades table for manual verification (#10).

### Verification performed

- [x] `bin/rspec spec/services/what_if/required_grade_service_spec.rb` — includes `estimated_assignments` examples
- [x] `yarn test ui/features/what_if_required_grade/react/__tests__/WhatIfRequiredGradePanel.test.tsx` — toggle, no fetch until open, clear on close
- [x] EC2 smoke test (2026-05-19): collapsed by default; expand → slider works; gray Final estimate; collapse clears estimates
- [x] Spreadsheet comparison — see **Manual verification (#10)** below

---

## Manual verification (#10)

**Course:** What-If Test Course (total points, 1000 possible)  
**Setup:** `agents/scripts/setup_student_demo.rb` — Midterm 800/800 graded, Final 200 ungraded  
**Verified on EC2:** 2026-05-19, student session

| Target | Hand calculation | Canvas result | Match |
|--------|------------------|---------------|-------|
| **80%** | Current score 800/1000 = 80%; target already met | Goal already met | ✅ |
| **85%** | Need 850 total → 50 pts on Final → **25%** on 200 pts remaining | ~25% required on remaining work | ✅ (within 0.1%) |
| **95%** | Need 950 total → 150 pts on Final → **75%** on remaining | Required score matches hand calc | ✅ (within 0.1%) |
| **100%** | Need 1000 total → 200/200 on Final → **100%** on remaining | Required score matches hand calc | ✅ (within 0.1%) |

**Unreachable scenario:** Target above what remaining points allow (e.g. requiring more
than 100% uniform score across remaining work) shows FR4 unreachable messaging; confirmed
in Vitest and manual UI check.

**Note:** Demo course uses total-points grading. Weighted assignment-group verification
is covered by RSpec in `what_if_required_grade_calculator_spec.rb`; a separate weighted
demo course on EC2 is optional follow-up.

**UI states confirmed:** loading while fetching, success with required score, unreachable
error, collapsed panel (no fetch), gray table estimates when expanded.

---

## Full PR index

| PR | Issues | Merge commit |
|----|--------|--------------|
| [#11](https://github.com/isaac-c-edwards/canvas-lms-master/pull/11) | #2 | [8977646c](https://github.com/isaac-c-edwards/canvas-lms-master/commit/8977646c62fb7a5085f56ff12595e9c2e57a2141) |
| [#12](https://github.com/isaac-c-edwards/canvas-lms-master/pull/12) | #3 | [85aaba48](https://github.com/isaac-c-edwards/canvas-lms-master/commit/85aaba48050c959fe5790568f5a53e4c9190b7f7) |
| [#13](https://github.com/isaac-c-edwards/canvas-lms-master/pull/13) | #4, #5, #6 | [a7304d7d](https://github.com/isaac-c-edwards/canvas-lms-master/commit/a7304d7dcbec394b9a7ddec372c86db34d31e7b7) |
| [#14](https://github.com/isaac-c-edwards/canvas-lms-master/pull/14) | #8, #9, refs #10 | [1f478aec](https://github.com/isaac-c-edwards/canvas-lms-master/commit/1f478aec92da3125e13ba38f6d257fb8f2ba103b) |

---

## Overall plan trace

Work followed `implementation-research.md` and the GitHub Project without silent scope
drift:

1. **Calculator** (#2, PR #11) — FR1–FR3, read-only Ruby engine
2. **API** (#3, PR #12) — FERPA-aligned student session endpoint
3. **UI** (#4–#6, PR #13) — positive framing, unreachable UX, disclaimer
4. **Polish + tests** (#8–#9, PR #14) — mount fix, opt-in toggle, table estimates, extended specs

v1 **out of scope:** drop-lowest rules (FR5 calculation); disclaimer present in UI.

**Workflow:** Each slice used `agents/feature-implementation.md` — MCP board updates
(In progress → Done), feature branches, PR review, merge to `main`, EC2 `git pull` for
verification.
