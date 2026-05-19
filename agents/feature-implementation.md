# Feature implementation agent

Agent spec for implementing **Feature 1: What-If Grade Calculator** in the
`isaac-c-edwards/canvas-lms-master` fork. Primary executor: Cursor (or compatible
coding agent). Human owns scope, review, merge, and manual Canvas verification.

## Role and non-goals

**Role:** Implement plan-aligned slices from the GitHub Project using agent-driven
code changes, tests, and PRs with board traceability.

**Non-goals:**

- Shipping the entire feature in one PR
- Pushing secrets, PATs, or `.pem` files
- Direct push to `main` (use feature branches + PR)
- Upstream merge to `instructure/canvas-lms`

## Inputs

| Artifact | Path / URL |
|----------|------------|
| Feature research (source of truth) | `agents/tasks/feature-1/implementation-research.md` |
| Feature framing | `agents/tasks/feature-1/feature-1.md` |
| Project creation spec | `agents/project-creation.md` |
| Brownfield analysis | `agents/analyze-repo.md`, `.repo-analysis/` |
| EC2 / Docker runbook | `agents/aws-canvas-runbook.md` |
| Memory / re-grounding | `agents/memory-practice.md` |
| Implementation evidence log | `agents/tasks/feature-1/implementation-evidence.md` |

**GitHub Project:**

- Owner: `isaac-c-edwards`
- Project number: **1** (title: `@isaac-c-edwards's test project`)
- URL: https://github.com/users/isaac-c-edwards/projects/1
- Repo: `isaac-c-edwards/canvas-lms-master`, branch `main`

**Status column mapping:**

| Board label | Project field `Status` option id |
|-------------|----------------------------------|
| Todo | `f75ad846` |
| **In progress** | `47fc9ee4` |
| **Done** | `98236657` |

Status field id: `345064183`.

## MCP: move to In progress

**When:** Immediately before substantive implementation on a selected issue (not
while only planning or authoring agent markdown).

**Tool:** GitHub MCP `projects_write`

```json
{
  "method": "update_project_item",
  "owner": "isaac-c-edwards",
  "project_number": 1,
  "item_id": "<PROJECT_ITEM_ID>",
  "updated_field": {
    "id": 345064183,
    "value": "47fc9ee4"
  }
}
```

**Locate `item_id`:** `projects_list` with `method: list_project_items`, match
`content.number` to GitHub issue number.

**Idempotency:** Safe to call if already In Progress.

**If MCP unavailable:** Move card manually in GitHub Projects UI; log date and
status in `implementation-evidence.md`.

## Implementation loop

1. **Select slice** — One issue from the project; must map to
   `implementation-research.md` (no silent scope drift).
2. **Re-ground** — Read research FR/NFR + issue body; read `AGENTS.md` EC2 workflow.
3. **Branch** — `feature/<issue#>-short-slug` from `main`.
4. **Implement** — Agent writes code/tests; human reviews diff.
5. **Verify** — Run checks for the slice type (see table below).
6. **Commit / push** — Conventional Canvas commit message; push branch.
7. **Open PR** — Link issue in body (`refs #N`); describe plan trace.

**Branch naming:** `feature/<issue#>-short-slug` (examples: `feature/2-what-if-calculator-engine`, `feature/14-path-to-goal-polish`)

**PR title:** `[Feature 1] <short description> (issue #N)`

**PR body must include:**

- Summary + plan trace (map to FR/NFR from research)
- `refs #N` (and related issues, e.g. `#8` for tests)
- Test plan checklist
- Out-of-scope note when relevant (drop-lowest, etc.)

## PR and merge gates

- PR is **required** before marking project item Done.
- Human (or explicit user request) **merges** PR to `main`.
- After merge: `git pull` on EC2; restart compose if testing there.

## MCP: mark Complete after merge

**When:** Only after PR is **merged** into `main`.

**Tool:** GitHub MCP `projects_write`

```json
{
  "method": "update_project_item",
  "owner": "isaac-c-edwards",
  "project_number": 1,
  "item_id": "<PROJECT_ITEM_ID>",
  "updated_field": {
    "id": 345064183,
    "value": "98236657"
  }
}
```

Update `agents/tasks/feature-1/implementation-evidence.md` with merge URL and
timestamp.

## Guardrails

- No AWS keys, session tokens, or `.pem` in tracked files
- Keep PRs small and reviewable (one project item per PR when possible)
- Document deviations from research in PR body + evidence file
- v1 excludes drop-lowest rules (FR5) — do not implement without plan update
- Read-only grade math only; no grade mutation in calculator layer

## Verification by slice type

| Slice | Required checks |
|-------|-----------------|
| Backend calculator (#2) | RSpec unit tests; no DB writes in calculator |
| API (#3) | Controller/request spec + permission check |
| Frontend (#4–6) | Vitest + manual student view on EC2 |
| Tests / polish (#8–9) | Extend RSpec/Vitest; record in evidence file |
| Manual (#10) | Spreadsheet comparison notes on demo course |
| Post-merge | `git pull` on EC2; smoke test grades page; log in evidence |

## Failure modes

| Failure | Mitigation |
|---------|------------|
| Stale EC2 IP | Re-ground from `aws-canvas-runbook.md`; Elastic IP `18.210.170.91` |
| MCP token expired | Manual board update + note in evidence |
| Scope creep | Stop; update research or create new issue first |
| RSpec env missing | Run inside `docker compose run --rm web bundle exec rspec ...` |

## Sync workflow (local ↔ EC2)

See `AGENTS.md` § EC2 dev workflow: edit locally → push → `git pull` on EC2.
