# AWS + Canvas runbook

**Goal:** Brownfield Canvas LMS dev stack on AWS EC2, verifiable via HTTP and Docker, using AI (Cursor) as primary executor for infra and setup.

**Last verified:** 2026-05-14 — `curl` to `/login/canvas` returned **200**; login form rendered (Email field present).

## AI prompts used (summary)

| Step | Prompt (paraphrased) |
|------|----------------------|
| AWS CLI | Where to paste credentials; install AWS CLI via `winget` |
| EC2 | “CAN U MAKE AN EC2?” |
| Repo on instance | Copy whole repo to EC2 (clone from GitHub + SCP untracked `vendor/`, `.cursor/`, `agents/`) |
| Canvas on EC2 | “install Docker and get Canvas running” |
| Repair | Pasted Rails error for missing `config/browsers.yml`; agent copied config and ran `yarn run build:css` |

**Executor:** Cursor agent with local AWS CLI (`~/.aws/credentials` on student machine—not committed).

## Learner Lab + EC2 checklist

- [x] AWS Academy Learner Lab / account credentials configured locally (`aws sts get-caller-identity` succeeds)
- [x] EC2 instance running (`cursor-test-ec2`, Amazon Linux 2023)
- [x] SSH: security group allows port 22 from student IP; access via EC2 Instance Connect when `.pem` not on laptop
- [x] HTTP: ports 80 and 443 open on security group
- [x] Instance sized for Canvas Docker: upgraded **t3.micro → t3.large**, disk **8 GB → 60 GB**
- [ ] **Elastic IP** (optional): not attached—public IP changes on stop/start

**Instance (redacted pattern):** `i-0e1c3eb4b30f20a01` — verify current IP with AWS console or CLI before SSH/browser.

**Current public IP at last verification:** `3.92.206.160`

## Canvas LMS: clone + doc path followed

| Item | Detail |
|------|--------|
| Fork remote | `https://github.com/isaac-c-edwards/canvas-lms-master.git` |
| Path on EC2 | `/home/ec2-user/canvas-lms-master` |
| Upstream docs | [`doc/docker/developing_with_docker.md`](../doc/docker/developing_with_docker.md), [`AGENTS.md`](../AGENTS.md) |
| Config copy | `cp docker-compose/config/*.yml config/` |
| Override | `config/docker-compose.override.yml.example` → `docker-compose.override.yml` |
| EC2 access | Custom `docker-compose.ec2.yml` maps **80:80**; `config/domain.yml` uses instance public IP |
| Docker images | `docker compose build --build-arg USER_ID=1000` (Linux UID match) |
| DB | `docker compose run --rm web bundle exec rake db:create db:initial_setup` with non-interactive admin env vars |
| Extra local files not on GitHub | `vendor/gems/bundler-multilock`, `config/brandable_css.yml`, `config/browsers.yml` (SCP from dev machine) |
| CSS | `docker compose run --rm web yarn run build:css` |

**Admin login (dev only):** `admin@example.com` / `password` — change after grading if instance stays up.

## Verification commands and signals

Run on EC2 (or SSH session):

```bash
cd ~/canvas-lms-master
docker ps --format 'table {{.Names}}\t{{.Status}}'
# Expect: web, webpack, jobs, postgres, redis Up

curl -s -o /dev/null -w '%{http_code}\n' http://localhost/login/canvas
# Expect: 200

curl -s http://localhost/login/canvas | grep -i Email
# Expect: login form markup
```

From laptop browser:

```
http://<EC2_PUBLIC_IP>/login/canvas
```

**Signals observed (2026-05-14):**

- `docker ps`: `canvas-lms-master-web-1`, `webpack-1`, `jobs-1`, `postgres-1`, `redis-1` running
- `/login/canvas` → **200** (after `browsers.yml` + `build:css` fixes)
- Earlier `/` → **302** redirect to login (acceptable)

**Known gaps (honest):**

- Full `canvas:compile_assets` / Rspack reported 263 errors; dev mode relies on **webpack** container for JS
- First page loads may be slow; not production-hardened

## Out of scope: feature implementation (next lab)

- No scoped Canvas feature code in this lab
- Next lab: implement course feature per `agents/tasks/feature-1/` planning artifacts

## Handoff for next lab

| Ready | Not started |
|-------|-------------|
| EC2 + Docker + DB + login page | Feature implementation |
| Fork cloned; compose stack documented | Full production asset compile |
| Agent memory pattern in `agents/memory-practice.md` | Elastic IP / permanent DNS |
