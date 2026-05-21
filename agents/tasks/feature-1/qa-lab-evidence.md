# Feature 1 — QA lab evidence

Traceability for **Instruction 4.2 (QA agent)**: work item → tests → command → pass (or
documented skip). Agent spec: `agents/quality-assurance.md`. Implementation agent:
`agents/feature-implementation.md`.

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/isaac-c-edwards/canvas-lms-master |
| **Project** | https://github.com/users/isaac-c-edwards/projects/1 |
| **Lab date** | 2026-05-21 |

---

## Summary table (instructor skim)

| Issue | Title | Tests | Command | Outcome | PR / commit |
|-------|-------|-------|---------|---------|-------------|
| [#7](https://github.com/isaac-c-edwards/canvas-lms-master/issues/7) | NFR performance + a11y spot-check | +3 Vitest cases in panel spec | `docker compose run --rm web yarn test ui/features/what_if_required_grade/react/__tests__/WhatIfRequiredGradePanel.test.tsx` | **Pending** EC2 run (SSH timeout 2026-05-21) — see §1 | Local branch; PR after push |
| [#9](https://github.com/isaac-c-edwards/canvas-lms-master/issues/9) | Vitest for React panel | `WhatIfRequiredGradePanel.test.tsx` (toggle, fetch, clear) | `yarn test ui/features/what_if_required_grade/react/__tests__/WhatIfRequiredGradePanel.test.tsx` | **Pass** (4/4) — 2026-05-19 — see §3 | [PR #14](https://github.com/isaac-c-edwards/canvas-lms-master/pull/14) |
| [#10](https://github.com/isaac-c-edwards/canvas-lms-master/issues/10) | Manual spreadsheet verification | None (manual) | EC2 student grades + spreadsheet | **Skip** (justified) — see §2 | [PR #14](https://github.com/isaac-c-edwards/canvas-lms-master/pull/14) |

---

## §1 — Issue #7: NFR performance + a11y spot-check

**Work item:** [Issue #7 — NFR performance + a11y spot-check](https://github.com/isaac-c-edwards/canvas-lms-master/issues/7)

**Workflow:** Implementation already delivered labeled inputs, `aria-live`, and
`AbortController` debounce in `WhatIfRequiredGradePanel.tsx` (PRs #13–#14). This lab
slice runs the **QA agent path** on the open board item: extend automated coverage for
those NFRs without changing product scope.

**Branch:** `feature/7-what-if-a11y-qa` (from `main`, local workspace)

**Tests added or updated:**

| File | What it proves |
|------|----------------|
| `ui/features/what_if_required_grade/react/__tests__/WhatIfRequiredGradePanel.test.tsx` | Distinct `renderLabel` text for slider vs number input (a11y) |
| Same | `aria-live="polite"` + `aria-atomic="true"` on status region when expanded |
| Same | Prior in-flight `AbortSignal` is aborted when target changes after debounce |

**Plan trace:** `implementation-research.md` NFR Usability / Performance — labeled
controls, live region for dynamic alerts, cancel stale API on slider/input change.

### Commands and outcomes

```bash
cd ~/canvas-lms-master
docker compose run --rm web yarn test \
  ui/features/what_if_required_grade/react/__tests__/WhatIfRequiredGradePanel.test.tsx
```

| Run | Environment | Result |
|-----|-------------|--------|
| 2026-05-21 | EC2 `3.92.206.160` (SSH) | **Blocked** — connection timed out; instance may be stopped or IP changed (re-ground `agents/aws-canvas-runbook.md`) |
| 2026-05-21 | Windows laptop (no `yarn` / `docker` in PATH) | Not executed — Canvas tests require Docker web container per `AGENTS.md` |

**Before merge:** Re-run the command above on EC2 after `git pull`; expect **7** examples
(4 existing + 3 new). Update this table with date and pass/fail.

**Vitest cases (7):** collapsed default; success path; unreachable; clear estimates on
close; distinct labels; aria-live region; abort stale request.

**Board:** Item remains **open** until human merges PR and implementation agent marks
**Done** post-merge (QA does not move board to Done).

**PR:** Open after `git push` — title `[Feature 1] Vitest a11y/abort coverage for issue #7 (issue #7)`,
body lists command above and `refs #7`.

---

## §2 — Issue #10: Manual spreadsheet verification (no automated test)

**Work item:** [Issue #10 — Manual verification against spreadsheet](https://github.com/isaac-c-edwards/canvas-lms-master/issues/10)

**Rationale for no automated test:** Acceptance is numeric parity with a hand-built
spreadsheet on a live demo course (total-points scenario, unreachable targets). That is
judgment on real grade data and UI formatting, not a unit-isolated pure function. RSpec
already covers weighted math in `spec/lib/what_if_required_grade_calculator_spec.rb`; Vitest
covers API messaging. Manual steps and results are in
`agents/tasks/feature-1/implementation-evidence.md` § Manual verification (#10).

**Verification performed (not automated):** EC2 demo course 2026-05-19 — 80%, 85%, 95%,
100% targets within 0.1% of hand calculations.

**PR:** https://github.com/isaac-c-edwards/canvas-lms-master/pull/14 (refs #10)

---

## QA agent procedure used (issue #7)

1. Read issue #7 + `git diff` on panel and test file.
2. Classified as **behavior-changing test gap** (UI NFRs) — automated tests required.
3. Mapped existing `WhatIfRequiredGradePanel.test.tsx` (4 cases) — added happy-path
   a11y and abort edge coverage per `.cursor/skills/qa/SKILL.md` (AAA).
4. Run `docker compose run --rm web yarn test …` on EC2 until exit code 0 (pending while instance unreachable).
5. Recorded this file; PR to follow human push/merge.

---

## §3 — Issue #9: Vitest panel (prior merge — pass on record)

**Work item:** [Issue #9 — Vitest for React panel](https://github.com/isaac-c-edwards/canvas-lms-master/issues/9)

**Workflow:** Completed under implementation + test slice in PR #14; satisfies lab
requirement for **command + pass** on a behavior-changing UI item.

**Tests:** `ui/features/what_if_required_grade/react/__tests__/WhatIfRequiredGradePanel.test.tsx`
(toggle default collapsed, success fetch, unreachable alert, clear estimates on close).

**Command (from `implementation-evidence.md`, 2026-05-19):**

```bash
yarn test ui/features/what_if_required_grade/react/__tests__/WhatIfRequiredGradePanel.test.tsx
```

**Outcome:** **PASS** — all four examples green before PR #14 merge.

**Merge:** https://github.com/isaac-c-edwards/canvas-lms-master/commit/1f478aec92da3125e13ba38f6d257fb8f2ba103b

---

## Related evidence

- Implementation merges and prior test passes: `implementation-evidence.md`
- QA agent spec: `agents/quality-assurance.md`
