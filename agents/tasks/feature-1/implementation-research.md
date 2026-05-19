# Implementation Research: What-If Grade Calculator

## 1. Design Considerations
* **Calculation Strategy:** To solve the "infinite combinations" problem of achieving a target grade, the tool uses a **uniform percentage strategy**. It calculates the single baseline percentage required across all remaining work, rather than suggesting varying scores.
* **Data Boundaries:** The feature must interact heavily with the `Course`, `AssignmentGroup` (for weights), and `Submission` concepts in Canvas. It must pull the student's current grades and the total possible points/weights for future assignments via the backend Rails controllers.
* **UX Risks:** Grade anxiety is a primary concern. To mitigate this, the UI will use positive framing ("Path to your goal") rather than absolute verdicts. Furthermore, if a target grade is mathematically impossible (e.g., requiring a 105%), the UI will gracefully handle the edge case by informing the user the goal is out of reach, preventing nonsensical data.
* **Project tracking:** Milestones on the GitHub Project: 
    1. Grade calculation logic implementation (Ruby backend).
    2. Frontend UI input/slider state management (React/TS).
    3. Edge-case handling for weighted groups.

## 2. Functional Requirements
1.  **Uniform Calculation:** Given a student inputs a valid target overall percentage, the system shall return the uniform minimum percentage required across all ungraded assignments to achieve that target.
2.  **Point-Based Support:** Given a course uses a total-points grading system, the system shall accurately sum the remaining points available to determine the required scores.
3.  **Weighting Support:** Given a course uses weighted assignment groups, the system shall factor the remaining points according to their respective group weights.
4.  **Error Handling:** Given a student inputs a target grade that is mathematically impossible to reach, the system shall display a graceful error message ("Target unreachable with remaining assignments") and clear the calculation output.
5.  **Scope Boundaries:** * **In Scope:** Calculating required grades for weighted and unweighted courses.
    * **Out of Scope:** The v1 calculation will *not* account for "drop lowest score" rules, as this introduces exponential complexity to the math. The UI will include a disclaimer stating drop rules are omitted.

## 3. Non-Functional Requirements
* **Security & Privacy:** The tool will operate entirely within the student's existing session permissions, strictly adhering to FERPA standards. No student data is modified in the database or shared externally; calculations are strictly read-only and localized to the user's view.
* **Performance:** Grade calculations should execute in <500ms to ensure the React UI feels responsive during real-time "What-if" slider/input adjustments.
* **Accessibility:** The input field and result display must follow WCAG 2.1 standards, ensuring full compatibility with screen readers for students relying on assistive technologies.

## 4. Codebase Analysis
**Instructions for using the analyze-repo agent:**
1. Ensure the Python environment is active on the EC2 instance.
2. Navigate to the root of the `canvas-lms` repository fork.
3. Run the indexing script: `python3 agents/scripts/analyze_repo_index.py`
4. Review the resulting `.repo-analysis/` artifacts (like `manifest.json` and `folder-summaries.md`) for architectural mapping.

**Agent Findings & Hypotheses:**
* **Backend Models:** The agent identified `app/models/assignment.rb` and `app/models/submission.rb` as the core domain objects for the grading/submission flow. The required math logic will likely need to aggregate data from these models, potentially interacting with an existing grade calculator service.
* **Frontend UI:** The agent identified `ui/featureBundles.ts` as the map for frontend feature bundles. The new UI component will likely be registered here and built inside the `ui/features/` directory using TypeScript and React.
* **Open Questions:** 1. Does an existing Ruby service handle "What-If" mock calculations that we can hook into, or do we need to write the aggregation logic from scratch?
    2. How does the current Gradebook API expose "muted" or "unposted" assignments to students in these calculations?

## 5. Testing and Verification Plan
We will verify the feature is safe and accurate before merging using the following plan:

* **What will be tested:** The math calculation logic for both weighted and unweighted courses, and the frontend input validation (handling impossible targets).
* **How it will be tested:**
    * **Unit Tests (Ruby/RSpec):** Create isolated tests for the calculation module. Supply mock student scores (e.g., 800/1000 points) and a target (90%), asserting the output correctly identifies the remaining points needed.
    * **Unit Tests (JS/Vitest):** Test the React component to ensure it successfully displays the error state when an impossible percentage (e.g., 105%) is required.
    * **Manual/Exploratory Testing:** Log in as a test Student. Use the UI to input a target grade of 90% in a heavily weighted course. Manually verify the output against a spreadsheet calculation.
* **Success vs. Failure:**
    * **Success:** The tool's calculated "Required Score" matches a manual spreadsheet calculation within a 0.1% margin of error, and UI states (success, error, loading) render correctly.
    * **Failure:** The tool crashes, calculates incorrect percentages, fails to account for category weights, or allows the student to submit impossible target requests.