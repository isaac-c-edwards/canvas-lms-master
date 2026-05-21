# Quality assurance (QA) agent

Agent spec for **automated test verification** on Feature 1 (What-If Grade Calculator)
and future slices in `isaac-c-edwards/canvas-lms-master`. Primary executor: Cursor with
`.cursor/skills/qa/SKILL.md` (or equivalent). Human owns scope, merge, and when to mark a
project item **Done**.

## Role and relationship to the feature-implementation agent

| Agent | Owns | Does not own |
|-------|------|----------------|
| **Feature implementation** (`agents/feature-implementation.md`) | Selecting slice, branch, code changes, opening PR, board **In progress**, merge, board **Done** after merge | Treating an item as Done without merged PR; skipping plan traceability |
| **QA (this spec)** | Test gap analysis, proposing/extending automated tests, running test commands until **green**, recording pass/skip in evidence | Product scope, large hand-authored test suites, merge rights, secrets |

**Order of operations:**

1. Implementation agent (or human) moves board item to **In progress** and implements on a feature branch.
2. Implementation agent opens a PR with `refs #N` and a test plan checklist (may include initial tests).
3. **QA agent runs before the item is treated complete** — after the PR exists or the branch is ready for review, and **before** MCP marks the project item **Done** (which still requires merge per `feature-implementation.md`).
4. Human reviews diff, approves merge; implementation agent merges and updates board + `implementation-evidence.md`.
5. QA agent (or human) adds/updates `agents/tasks/feature-1/qa-lab-evidence.md` for lab traceability.

QA does not duplicate implementation: it does not rewrite feature logic except to fix tests or minimal hooks required for testability. If tests fail, QA and human fix tests or narrow scope until green, or document an honest blocker.

## Inputs

| Input | Location / how to identify |
|-------|---------------------------|
| Active work item | GitHub Project #1 — match `content.number` to issue via MCP `projects_list` / `list_project_items`, or issue URL `https://github.com/isaac-c-edwards/canvas-lms-master/issues/N` |
| Branch | `feature/<issue#>-short-slug` (from PR or `git branch --show-current`) |
| Feature scope | `agents/tasks/feature-1/implementation-research.md`, issue body |
| Implementation trace | `agents/tasks/feature-1/implementation-evidence.md` |
| QA trace (this lab) | `agents/tasks/feature-1/qa-lab-evidence.md` |
| Diff under test | `git diff main...HEAD` or PR files tab |
| Cursor QA skill | `.cursor/skills/qa/SKILL.md` (AAA, happy path + edge cases) |
| Ruby test skill | `.claude/skills/rspec/SKILL.md` when editing `*_spec.rb` |

**GitHub Project** (same as implementation agent):

- Owner: `isaac-c-edwards`, project **1**
- Status field id: `345064183` — **In progress** `47fc9ee4`, **Done** `98236657`
- QA does **not** move items to Done; that remains post-merge on the implementation agent.

## Test commands and definition of passing

Run commands in an environment that matches the fork (prefer Docker per `AGENTS.md`).

| Stack | Command | Passing means |
|-------|---------|---------------|
| Ruby unit / service | `docker compose run --rm web bundle exec rspec <path>` or `bin/rspec <path>` inside web container | Exit code **0**; no failures; do not use `skip` or remove existing examples to greenwash |
| Ruby (directory) | `docker compose run --rm web bundle exec rspec spec/lib/what_if_required_grade_calculator_spec.rb` (example) | Same |
| Frontend (Vitest) | `docker compose run --rm web yarn test <path>` or `yarn test ui/features/.../Foo.test.tsx` | Exit code **0**; all examples in the targeted file(s) pass |
| Frontend (watch / dev) | `yarn test:watch` | Not used for completion gate — use single run for evidence |
| Lint (optional pre-test) | `yarn check:ts` for TS slices; `bin/rubocop` for touched Ruby | No new offenses in touched files (human may waive) |

**Local Windows without yarn/docker:** Record the exact command and run on EC2 after `git pull` (see `agents/aws-canvas-runbook.md`), or in `docker compose run --rm web bash`.

**Passing** for a work item: every command listed in `qa-lab-evidence.md` for that item exited 0 on the cited commit/branch, or the item has a **documented exception** (below).

## Procedure: implementation ready → tests green → pass recorded

1. **Identify item** — Issue #N from board or PR body (`refs #N`).
2. **Re-ground** — Read issue, research FR/NFR, and `git diff main...HEAD` (or PR diff).
3. **Classify** — Behavior-changing code vs docs-only / manual-only (see criteria below).
4. **Map tests** — List existing specs/tests touching changed paths; note gaps (happy path + material edge cases per QA skill).
5. **Propose or extend tests** — Smallest credible level: RSpec for Ruby (`lib/`, `app/services/`, controllers); Vitest + Testing Library for `ui/features/`. Arrange–Act–Assert; no skipping/deleting tests to force green.
6. **Run commands** — Execute table above for every new/changed test file and at least one related existing spec if integration risk exists.
7. **Fix loop** — On failure: fix test or production code within slice scope; re-run until green or stop and document blocker.
8. **Record evidence** — Append row/section to `agents/tasks/feature-1/qa-lab-evidence.md`: issue title, test paths, command, outcome, PR/commit link.
9. **PR alignment (Lab 3.2)** — Ensure PR test plan checklist matches commands run; comment on PR if QA added tests after initial open.
10. **Hand off** — Human merges; implementation agent marks board **Done** and updates `implementation-evidence.md`.

Optional MCP: QA may comment on the issue with test commands and pass/fail summary; it does not call `projects_write` for **Done**.

## When automated tests are required (“where it makes sense”)

**Required (no “makes sense” skip):**

- New or changed Ruby in `lib/`, `app/models/`, `app/services/`, `app/controllers/`, serializers, or policies
- New or changed React/TS in `ui/features/` or `ui/shared/` with user-visible behavior
- Bug fixes in application code
- API contract or permission changes

**Smallest credible check:** Prefer unit tests (`rspec` example groups, Vitest `describe` blocks). Use request/controller specs when the slice is HTTP-bound; use one focused Vitest file per feature bundle when UI changes.

**Documented exception only (1–2 sentences in `qa-lab-evidence.md`):**

- Agent markdown, runbooks, or project specs only (`agents/*.md`, no runtime code)
- Pure manual verification slices (e.g. spreadsheet compare on EC2) where automation would duplicate human judgment and issue acceptance criteria say manual
- Open spike/conclusion docs with no code delta
- Tooling/scripts not wired to CI/test harness **and** no behavior change (e.g. one-off EC2 bootstrap) — still list manual verification performed

**Not acceptable:** “Makes sense” to skip tests on calculator, API, or UI logic; “will add tests later” without an open follow-up issue.

## MCP / PR alignment with Lab 3.2

- Repo: `isaac-c-edwards/canvas-lms-master`, integration branch `main`
- PR title: `[Feature 1] <description> (issue #N)`
- PR body: summary, plan trace, `refs #N`, **test plan** listing exact commands QA ran
- Board **Done** only after merge (implementation agent) — QA evidence must exist **before** you treat the slice as complete in the lab sense (tests green or justified skip)

## Guardrails

- Do not commit AWS keys, PATs, `.pem`, or tokens; redact secrets from logs and evidence
- Do not remove or `skip` existing tests to obtain green runs
- Do not mark project **Done** from the QA agent
- Do not expand scope (e.g. drop-lowest FR5) without research/issue update
- If tests cannot run locally, document environment (e.g. EC2 + docker) and the command; do not claim pass without a real run on the cited commit

## Failure modes

| Failure | Mitigation |
|---------|------------|
| `yarn` / `docker` missing on laptop | Run via `docker compose run --rm web` on EC2 |
| RSpec DB/env errors | Use web container; see `feature-implementation.md` |
| Flaky Vitest timing | Use `waitFor`, fake timers for debounce; avoid arbitrary `setTimeout` in tests |
| Scope too large for one QA pass | Split issue; QA completes per merged PR |

## Related files

- `agents/feature-implementation.md` — implementation loop and board MCP
- `.cursor/skills/qa/SKILL.md` — step-by-step test authoring behavior
- `agents/tasks/feature-1/qa-lab-evidence.md` — per-item test trace for instructors
- `AGENTS.md` — Canvas build/test commands
