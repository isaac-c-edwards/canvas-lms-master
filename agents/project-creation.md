# Lab 4 Project Creation Agent Spec (Feature 1)

## Objective
Create or update a GitHub Project plan for Feature 1 ("What-If Grade Calculator") by converting Lab 3 handoff requirements into complete, traceable GitHub issues and project items.

## Inputs and Source of Truth

1. Primary input (required): `agents/tasks/feature-1/implementation-research.md`
   - This is the source of truth for scope, milestones, dependencies, and definition of done.
   - Prioritize sections for:
     - Functional requirements
     - Project tracking milestones
     - Testing and verification
     - Scope boundaries (in scope vs out of scope)
2. Secondary input (optional): `agents/tasks/feature-1/feature-1.md`
   - Use only for one-line framing if needed.
3. Brownfield context input (required integration): evidence from Lab 2 findings captured in the implementation research (backend and frontend subsystem targets, open questions, and analysis workflow references).

## Repository Targeting (Do Not Skip)

Before creating any project or issue, confirm and lock the target repository context:

- GitHub owner: `isaac-c-edwards`
- Repository: `canvas-lms-master`
- Default branch/ref: `main`

Rules:

- Do not create projects or issues in any other owner/repository.
- If MCP context points to a different repository, stop and ask for human confirmation before proceeding.
- Include the repo context in the output summary for verification.

## MCP Orchestration Procedure (GitHub)

Tool names may vary by MCP server version. First inspect the connected GitHub tool list, then use the matching tool categories below.

1. Project selection/creation
   - Use project-management MCP tools to:
     - Find an existing Feature 1 project in the target repo context, or
     - Create a new project for Feature 1 if none exists.
   - Project title convention: `Feature 1 - What-If Grade Calculator`.

2. Story derivation from Lab 3 handoff
   - Derive the full story set needed to deliver all in-scope requirements from `implementation-research.md`.
   - Ensure each issue includes:
     - Clear user-story or engineering objective title
     - Description/body
     - Acceptance hints tied to functional requirements and definition of done
     - Notes for out-of-scope constraints where applicable (for example, drop-lowest logic excluded in v1)

3. Issue creation
   - Use issue-management MCP tools to create issues for all required stories.
   - Include explicit testing/verification stories or acceptance subtasks:
     - Ruby unit tests for grade logic
     - JS/Vitest coverage for UI/error states
     - Manual validation steps against known scenarios

4. Add issues/drafts to project
   - Use project-item MCP tools to add each issue to the selected project.
   - Set project fields if present in the template:
     - Status (for example: Backlog/Todo)
     - Priority
     - Iteration/Milestone

5. Dependency representation
   - Encode dependencies between issues when the handoff implies sequence:
     - Core grade logic before UI integration
     - Weighted edge-case handling dependent on baseline calculation behavior
     - Testing stories mapped to corresponding implementation stories
   - If native dependency linking is unavailable, add explicit "Depends on #X" text in issue bodies.

## Integration With Lab 2 (Analyze-Repo) Evidence

At least one milestone or story must explicitly anchor to Lab 2 brownfield evidence:

- Backend story references identified domain paths such as:
  - `app/models/assignment.rb`
  - `app/models/submission.rb`
- Frontend story references identified bundle integration area:
  - `ui/featureBundles.ts`
  - expected feature location in `ui/features/`

Also include one "investigation/open-question" issue if unresolved architecture questions remain from Lab 2 findings (for example, existing calculation service reuse and handling of muted/unposted assignments).

## Completeness Rules: Necessary Stories Required

The resulting project must cover all needed work to deliver the Lab 3 scope, not just coding tasks.

Required coverage checklist for story derivation:

1. Functional requirements coverage
   - Uniform required-grade calculation
   - Point-based grading support
   - Weighted assignment-group support
   - Unreachable-target error handling
   - Scope-boundary communication in UI for out-of-scope drop-rule behavior

2. Non-functional acceptance considerations
   - Performance responsiveness expectations
   - Accessibility expectations
   - Read-only/privacy constraints

3. Verification work
   - Automated tests (backend and frontend)
   - Manual validation scenario(s)

4. Execution structure
   - Milestones/phases aligned with Lab 3 handoff
   - Dependency ordering where needed

If any functional requirement in Lab 3 does not map to an issue, create the missing issue before finishing.

## Human Verification (Do Not Trust Blindly)

After MCP actions complete, provide:

1. Direct link to the GitHub Project in `isaac-c-edwards/canvas-lms-master`
2. List of created/updated issue links
3. Short traceability checklist mapping each Lab 3 functional requirement to one or more issue numbers
4. Confirmation that repository target was `isaac-c-edwards/canvas-lms-master` on `main`

## Output Format Required From Agent

Return a concise final report with:

1. Repository context used
2. Project URL
3. Issues created (number + title + URL)
4. Dependency notes
5. Requirement-to-issue traceability table/list
6. Any blockers that require human decision
