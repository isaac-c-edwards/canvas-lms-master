# Memory technique: Last-verified metadata + explicit re-grounding

## Why this fits Canvas work

Canvas LMS is a large brownfield fork with Docker, Ruby, and frontend build steps that drift quickly after upstream pulls or partial clones. A **last-verified timestamp** on agent-facing notes plus an **explicit re-grounding trigger** after environment changes keeps agents from trusting stale setup advice (wrong IPs, missing config files, outdated compose steps).

## Connection to Lab 2 agent

This pattern attaches to [`agents/analyze-repo.md`](analyze-repo.md). Before `analyze-repo` runs a bounded pass, I check whether `.repo-analysis/manifest.json` and this file’s **Last verified** block are current. If infra or clone state changed since last verification, I re-run targeted commands (or ask the agent to) instead of relying on prior chat memory.

## Procedure (prompts / file rituals)

1. **Before a long agent session** on AWS or Docker: open `agents/aws-canvas-runbook.md` and confirm **Last verified** is today or note what changed.
2. **After merges, upstream pulls, or EC2 stop/start**: tell the agent: *“Re-ground from `agents/aws-canvas-runbook.md` and `AGENTS.md`; do not assume prior IP or config paths.”*
3. **After a successful verification**: update **Last verified** in the runbook with date, command, and signal (HTTP status, container names).
4. **Purge policy**: do not paste AWS keys, `.pem` contents, or session tokens into agent chats or markdown; redact account IDs in student-facing docs if desired.
5. **STM budgeting**: for Canvas errors, paste the error trace only; point the agent at `doc/docker/developing_with_docker.md` instead of re-describing the whole stack each turn.

## Purge / refresh / last verified

| Artifact | Refresh when |
|----------|----------------|
| `agents/aws-canvas-runbook.md` | EC2 stop/start, compose changes, failed health check |
| `.repo-analysis/*` | Major repo pull or new feature area (per `analyze-repo` refresh policy) |
| Chat context | New session after infra repair; summarize prior outcome in one bullet, not full logs |

**Last verified (memory-practice):** 2026-05-14 — runbook verification block updated after login page returned HTTP 200.

## Failure modes and mitigations

| Failure mode | Mitigation |
|--------------|------------|
| **Stale context** (old public IP, wrong instance type) | Re-ground from runbook; run `aws ec2 describe-instances` before SSH URLs |
| **Over-retention** (agent “remembers” fixed errors) | Mark fixes in runbook; start new session for unrelated tasks |
| **Wrong trust boundary** (secrets in chat or committed docs) | Keys only in `~/.aws/credentials` locally; never commit; redact in evidence excerpts |

## Evidence excerpt (no secrets)

**User prompt (Cursor):** *“CAN U MAKE AN EC2? … copy this whole repo on it … install Docker and get Canvas running”*

**Agent actions (summarized):** Created EC2, cloned fork from GitHub, installed Docker/Compose/buildx, upgraded instance to `t3.large`, ran `docker compose` bootstrap, fixed missing `vendor/`, `brandable_css.yml`, `browsers.yml`, ran `yarn run build:css`, completed `db:initial_setup` with `CANVAS_LMS_ADMIN_EMAIL` / `CANVAS_LMS_ADMIN_PASSWORD` env vars.

**Re-grounding example:** After `browsers.yml` 500 error, user pasted Rails trace; agent did not reuse earlier “Canvas is up” claim—it checked logs, copied missing config from local fork, ran `build:css`, re-verified `/login/canvas` → **200**.

