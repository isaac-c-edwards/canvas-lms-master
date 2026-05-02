# Repository Analysis Report

## Repository Summary
`canvas-lms` is a large, monorepo-style Learning Management System (Canvas LMS) with a Ruby on Rails backend and a substantial TypeScript/React frontend. It combines core LMS domain logic (courses, enrollments, assignments, submissions, users), UI feature bundles, and plugin/gem extension points to support multi-tenant, highly configurable deployments.

## Architecture Map
- `app/` - Rails application code (controllers/models/views/services); this is the core backend request lifecycle and domain logic.
- `config/` - Rails boot/runtime config, environments, routes, feature flags, and app wiring; very large because it includes operational/config artifacts.
- `ui/` - frontend app and module registry; `ui/features` (feature-level bundles) and `ui/shared` (reusable UI/runtime packages) dominate JS/TS code.
- `packages/` - workspace packages shared across frontend/runtime concerns.
- `gems/` and `gems/plugins/` - modular Ruby components and plugin system used to extend Canvas functionality.
- `lib/` - backend supporting libraries and cross-cutting Ruby infrastructure.
- `spec/` - test suite (Ruby + JS test harness glue).
- `doc/` and `docker-compose*` - developer docs and local containerized dev environment setup.

Index-derived scale snapshot:
- Total indexed files: `22,479`
- Total indexed symbols: `140,704`
- Largest subtrees by files: `ui` (`10,099`), `spec` (`3,423`), `app` (`2,991`), `gems` (`1,580`), `packages` (`1,379`)
- Dominant languages: Ruby, TypeScript React, JavaScript/React mix

## Technology Stack
- **Backend:** Ruby on Rails (`CanvasRails::Application`), Rack (`config.ru`), ActiveRecord/PostgreSQL.
- **Frontend:** TypeScript + React, workspace-based package structure, dynamic feature bundle loading.
- **JS build/dev:** Yarn workspaces, Rspack, GraphQL codegen, Brandable CSS pipeline.
- **Testing:** `vitest` (JS/TS), `rspec` (Ruby), additional jspec scripts.
- **Lint/type checks:** ESLint, Biome, TypeScript (`tsc`), stylelint.
- **Runtime/dev infra:** Docker Compose (`web`, `jobs`, `postgres`, `redis`).

## Key Files To Open Next
- `config/routes.rb` - central HTTP surface area and routing topology; fastest way to see product capabilities.
- `config/application.rb` - Rails app initialization, middleware, logging, and global behavior.
- `app/controllers/application_controller.rb` - shared request lifecycle hooks/auth/session/context behavior.
- `app/models/course.rb` - core LMS domain aggregate around courses.
- `app/models/enrollment.rb` - user-course relationship model and role/state behavior.
- `app/models/assignment.rb` and `app/models/submission.rb` - assignment and grading/submission flow.
- `ui/index.ts` - frontend startup path and runtime bundle loading mechanics.
- `ui/featureBundles.ts` - map of feature bundle entry points (frontend capability inventory).
- `package.json` - authoritative frontend build/test/lint commands and dependency tooling.

## Important Symbols Or Entry Points
- `CanvasRails::Application` in `config/application.rb` - Rails application root and lifecycle configuration (**high**).
- `CanvasRails::Application.initialize!` in `config/environment.rb` - backend boot boundary (**high**).
- `CanvasRails::Application.routes.draw` in `config/routes.rb` - app route topology (**high**).
- `ApplicationController` in `app/controllers/application_controller.rb` - global controller behavior/auth/hooks (**high**).
- `ApplicationRecord` in `app/models/application_record.rb` - base ORM model abstraction (**high**).
- `Course` in `app/models/course.rb` - primary LMS context object (**high**).
- `User` in `app/models/user.rb` - identity/account domain root (**high**).
- `Enrollment` in `app/models/enrollment.rb` - user-to-course role/state relationship (**high**).
- `Assignment` in `app/models/assignment.rb` - assessment domain object (**high**).
- `Submission` in `app/models/submission.rb` - grading/submission lifecycle object (**high**).
- `featureBundles` in `ui/featureBundles.ts` - frontend feature entry-point registry (**high**).
- `loadReactRouter()` and bundle boot flow in `ui/index.ts` - frontend app initialization path (**high**).

## How The Analysis Was Bounded
- Context target used: `128000` usable tokens, `51200` max (40%) from `.repo-analysis/context-budget.json`.
- I refreshed indexes first via `agents/scripts/analyze_repo_index.py`, then used index artifacts:
  - `.repo-analysis/manifest.json`
  - `.repo-analysis/key-files.json`
  - `.repo-analysis/symbols.jsonl` (filtered queries only)
  - `.repo-analysis/folder-summaries.md`
  - `.repo-analysis/context-budget.json`
- I opened only targeted files for verification (README, build configs, Rails entry files, core controller/model anchors, frontend entry/feature registry, Docker/gems docs).
- I intentionally skipped bulk source ingestion, lock/vendor trees, and full `symbols.jsonl` loading; conclusions are based on indexed evidence + focused validation reads.

## Open Questions
- Which functional area is your immediate goal (e.g., grading, LTI, authentication, analytics, accessibility)? That will narrow the next-read set dramatically.
- Do you want a backend-first map (controllers/models/services) or frontend-first map (`ui/features` bundle pathways)?
- Are you targeting local development setup, feature implementation, debugging, or architecture onboarding?
- Should I generate a follow-up "deep slice" analysis for one subsystem (for example: enrollments + permissions flow, or assignment/submission grading flow)?
