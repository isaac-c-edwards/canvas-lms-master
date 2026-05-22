# Feature 1 — QA lab evidence

Traceability log: work item → tests → command → pass (or documented skip). Agent spec:
`agents/quality-assurance.md`. Implementation agent: `agents/feature-implementation.md`.

| Field | Value |
|-------|-------|
| **Repo** | https://github.com/isaac-c-edwards/canvas-lms-master |
| **Project** | https://github.com/users/isaac-c-edwards/projects/1 |
| **Last updated** | 2026-05-21 |

---

## Summary

| Issue | Title | Tests | Command | Outcome | PR / commit |
|-------|-------|-------|---------|---------|-------------|
| [#7](https://github.com/isaac-c-edwards/canvas-lms-master/issues/7) | NFR performance + a11y spot-check | +3 Vitest cases in panel spec | `docker compose run --rm web yarn test ui/features/what_if_required_grade/react/__tests__/WhatIfRequiredGradePanel.test.tsx` | **Pending** EC2 sync (AWS creds expired) — see §1 | [PR #15](https://github.com/isaac-c-edwards/canvas-lms-master/pull/15) merged |
| [#9](https://github.com/isaac-c-edwards/canvas-lms-master/issues/9) | Vitest for React panel | `WhatIfRequiredGradePanel.test.tsx` (toggle, fetch, clear) | `yarn test ui/features/what_if_required_grade/react/__tests__/WhatIfRequiredGradePanel.test.tsx` | **Pass** (4/4) — 2026-05-19 — see §3 | [PR #14](https://github.com/isaac-c-edwards/canvas-lms-master/pull/14) |
| [#10](https://github.com/isaac-c-edwards/canvas-lms-master/issues/10) | Manual spreadsheet verification | None (manual) | EC2 student grades + spreadsheet | **Skip** (justified) — see §2 | [PR #14](https://github.com/isaac-c-edwards/canvas-lms-master/pull/14) |

---

## §1 — Issue #7: NFR performance + a11y spot-check

**Work item:** [Issue #7 — NFR performance + a11y spot-check](https://github.com/isaac-c-edwards/canvas-lms-master/issues/7)

**Workflow:** Implementation delivered labeled inputs, `aria-live`, and `AbortController`
debounce in `WhatIfRequiredGradePanel.tsx` (PRs #13–#14). QA extended automated coverage
for those NFRs without changing product scope.

**Branch:** `feature/7-what-if-a11y-qa`

**Tests added or updated:**

| File | What it proves |
|------|----------------|
| `ui/features/what_if_required_grade/react/__tests__/WhatIfRequiredGradePanel.test.tsx` | Distinct accessible names for slider and number input |
| Same | `aria-live="polite"` + `aria-atomic="true"` on status region when expanded |
| Same | `AbortSignal` passed to API and aborted when the tool closes |

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
| 2026-05-22 | EC2 sync | **Blocked** — AWS session token expired; run `git pull origin main` + Vitest after refreshing Learner Lab creds |
| 2026-05-21 | EC2 (pre-fix) | 5/7 — fixed in `ed5170d2`, merged via PR #15 |

**Merge:** https://github.com/isaac-c-edwards/canvas-lms-master/pull/15 → [aae36cc6](https://github.com/isaac-c-edwards/canvas-lms-master/commit/aae36cc67a831a175b361fd7b8cc4384e9bd5847)

**Board:** Issue #7 → **Done** (project item `185630688`, 2026-05-22)

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

## §3 — Issue #9: Vitest panel

**Work item:** [Issue #9 — Vitest for React panel](https://github.com/isaac-c-edwards/canvas-lms-master/issues/9)

**Tests:** `ui/features/what_if_required_grade/react/__tests__/WhatIfRequiredGradePanel.test.tsx`
(toggle default collapsed, success fetch, unreachable alert, clear estimates on close).

**Command (2026-05-19):**

```bash
yarn test ui/features/what_if_required_grade/react/__tests__/WhatIfRequiredGradePanel.test.tsx
```

**Outcome:** **PASS** — all four examples green before PR #14 merge.

**Merge:** https://github.com/isaac-c-edwards/canvas-lms-master/commit/1f478aec92da3125e13ba38f6d257fb8f2ba103b

---

## Related evidence

- Implementation merges and verification: `implementation-evidence.md`
- QA agent spec: `agents/quality-assurance.md`
