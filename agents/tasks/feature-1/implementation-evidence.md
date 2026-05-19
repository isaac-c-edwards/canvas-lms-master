# Feature 1 — Implementation evidence (Lab 3.2)

## Lab 3.2 submission summary

| Item | Value |
|------|-------|
| **Repo** | https://github.com/isaac-c-edwards/canvas-lms-master |
| **Integration branch** | `main` |
| **Agent spec** | `agents/feature-implementation.md` |
| **GitHub Project** | https://github.com/users/isaac-c-edwards/projects/1 |
| **Feature research** | `agents/tasks/feature-1/implementation-research.md`, `feature-1.md` |

**Lab 3.2 minimum (one slice):** Issue #2 → PR #11 → merged → board **Done** (2026-05-19).

**Beyond minimum:** Four additional plan-aligned slices delivered (API #3, UI #4–#6, polish #8–#10) via PRs #12–#14.

**EC2 demo (verified 2026-05-19):**

- URL: http://18.210.170.91/courses/1/grades
- Course: *What-If Test Course* (id **1**) — Midterm 800/800 graded, Final 200 pts ungraded
- Student: `student@example.com` / `password`
- Post-merge: `git pull origin main` on EC2; smoke test confirmed panel, slider, toggle, gray estimates

**Open project issues (not blocking Lab 3.2):**

| Issue | Title | Status |
|-------|-------|--------|
| #1 | Spike / brownfield investigation | Open — answered in `implementation-research.md` §4 |
| #7 | NFR performance + a11y spot-check | Open — basic a11y labels in PR #13/#14; full audit deferred |
| #10 | Manual spreadsheet verification (DoD) | Open — EC2 smoke test done; formal spreadsheet write-up pending |

---

## Slice #2 — Backend calculation engine (Lab 3.2 primary slice)

**Issue #2:** [Feature 1] Backend: What-if grade calculation engine (uniform %, points, weights)

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

This slice implements **milestone 1** from `implementation-research.md` (grade calculation logic) and maps to **FR1** (uniform calculation), **FR2** (point-based courses), and **FR3** (weighted assignment groups) via pure Ruby aggregation. Brownfield spike (#1) concluded a separate reverse-target calculator was needed rather than reusing Canvas what-if score storage. Drop-lowest (FR5) intentionally excluded in v1.

### Verification performed

- [x] `bin/rspec spec/lib/what_if_required_grade_calculator_spec.rb` — unit tests in repo; run in Docker web container per `AGENTS.md`
- [x] No DB writes in calculator layer (read-only math)

### MCP notes

GitHub MCP set issue #2 project item to **In progress** before implementation and **Done** after PR #11 merge (2026-05-19).

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

**Plan trace:** Delivers student-facing read-only surface per NFR Security & Privacy; wires calculator (#2) to Course / AssignmentGroup / Submission data for the React client (#4).

### Verification performed

- [x] `bin/rspec spec/services/what_if/required_grade_service_spec.rb` — coverage in repo
- [x] `bin/rspec spec/controllers/what_if_required_grades_api_controller_spec.rb` — coverage in repo

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

**Plan trace:** Milestone 2 from research (frontend input/slider, positive framing). Maps to FR1–FR3 via UX, FR4 error handling, FR5 scope disclaimer.

### Verification performed

- [x] `yarn test ui/features/what_if_required_grade/react/__tests__/WhatIfRequiredGradePanel.test.tsx` — Vitest in repo
- [x] Manual EC2: student Grades → **Path to Your Goal** panel renders (post PR #14 mount fix)

---

## Slice #5 — Polish, tests, grade table estimates (#8, #9, #10)

**Issues:**

| Issue | Scope |
|-------|-------|
| #8 | RSpec for calculation module + service extensions |
| #9 | Vitest for React panel (toggle, fetch, error states) |
| #10 | Manual verification / DoD (partial — see below) |

**Branch:** `feature/14-path-to-goal-polish`

**PR:** https://github.com/isaac-c-edwards/canvas-lms-master/pull/14

**Status:** ✅ **Merged**

- [x] PR opened
- [x] PR merged to `main`
- [x] Issues #8, #9 → **Closed** via PR (2026-05-19)
- [ ] Issue #10 → **Open** (formal spreadsheet comparison notes still pending)

**Merge commit:** https://github.com/isaac-c-edwards/canvas-lms-master/commit/1f478aec92da3125e13ba38f6d257fb8f2ba103b

**What changed:**

- **Mount fix:** `js_bundle :what_if_required_grade` moved after `load_grade_summary_data` in `GradebooksController` so `@presenter.editable?` is set and the bundle loads
- **Opt-in toggle:** `ToggleDetails` — panel collapsed by default; no API calls or gray estimates until opened
- **Slider/input fix:** Correct Instructure UI `RangeInput` / `NumberInput` callback signatures
- **`estimated_assignments`:** Service returns per-assignment estimates; `pathToGoalEstimates.js` paints gray italic scores on ungraded rows; totals recalc via GradeSummary jQuery
- **Styles:** `.what-if-path-estimate` in `grade_summary.scss`
- **Tests:** Extended `required_grade_service_spec.rb`; panel tests for toggle/fetch/clear behavior
- **Ops scripts:** `agents/scripts/ec2-bootstrap-fix.sh`, `setup_course.rb`, `setup_student_demo.rb`

**Plan trace:** Closes test gaps (#8, #9) from research §5; integrates calculator output into the grades table for exploratory verification (#10). Post-merge EC2 sync confirmed end-to-end behavior.

### Verification performed

- [x] `bin/rspec spec/services/what_if/required_grade_service_spec.rb` — includes `estimated_assignments` examples
- [x] `yarn test ui/features/what_if_required_grade/react/__tests__/WhatIfRequiredGradePanel.test.tsx` — toggle, no fetch until open, clear on close
- [x] EC2 smoke test (2026-05-19): collapsed by default; expand → slider works; gray Final estimate; collapse clears estimates
- [ ] Issue #10 spreadsheet: 80% (goal met), 85% (~25% on remaining), 90% (unreachable) — hand calc vs Canvas within 0.1% — **to document**

---

## Full PR index

| PR | Issues | Merge commit |
|----|--------|--------------|
| [#11](https://github.com/isaac-c-edwards/canvas-lms-master/pull/11) | #2 | [8977646c](https://github.com/isaac-c-edwards/canvas-lms-master/commit/8977646c62fb7a5085f56ff12595e9c2e57a2141) |
| [#12](https://github.com/isaac-c-edwards/canvas-lms-master/pull/12) | #3 | [85aaba48](https://github.com/isaac-c-edwards/canvas-lms-master/commit/85aaba48050c959fe5790568f5a53e4c9190b7f7) |
| [#13](https://github.com/isaac-c-edwards/canvas-lms-master/pull/13) | #4, #5, #6 | [a7304d7d](https://github.com/isaac-c-edwards/canvas-lms-master/commit/a7304d7dcbec394b9a7ddec372c86db34d31e7b7) |
| [#14](https://github.com/isaac-c-edwards/canvas-lms-master/pull/14) | #8, #9, refs #10 | [1f478aec](https://github.com/isaac-c-edwards/canvas-lms-master/commit/1f478aec92da3125e13ba38f6d257fb8f2ba103b) |

---

## Overall plan trace (Feature 1)

Work followed `implementation-research.md` and the GitHub Project from Lab 2.2 without silent scope drift:

1. **Calculator** (#2, PR #11) — FR1–FR3, read-only Ruby engine
2. **API** (#3, PR #12) — FERPA-aligned student session endpoint
3. **UI** (#4–#6, PR #13) — positive framing, unreachable UX, disclaimer
4. **Polish + tests** (#8–#9, PR #14) — mount fix, opt-in toggle, table estimates, extended specs

v1 **out of scope:** drop-lowest rules (FR5 calculation); disclaimer present in UI.

**Agent workflow:** Each slice used `agents/feature-implementation.md` — MCP board updates (In progress → Done), feature branches, PR review, human merge, EC2 `git pull` for verification.
