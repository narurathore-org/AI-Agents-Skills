# android-sdd

Spec-Driven Development (SDD) skill for Kotlin/Android projects. Covers two
modes: **SPEC** (write organised spec files for user review) and **IMPLEMENT**
(take an approved spec and implement it phase-by-phase with TDD, full test
coverage, and plan/progress tracking).

Called by an orchestrator agent — not invoked directly by the user or the
main Claude Code session.

`CONTEXT_ROOT = /Users/nsingh/Documents/local-claude-agents/projects/`

---

## Invocation contract

The orchestrator calls this skill with one of:

```
MODE: SPEC
feature: <feature name or description>
ticket: <TICKET-ID>          # optional — Jira ticket if available
figma: <url>                 # optional
project_root: <abs path>
```

```
MODE: IMPLEMENT
spec_slug: <slug>            # e.g. "user-profile-edit"
spec_type: feature | bug
project_root: <abs path>
```

---

## Shared prerequisites (both modes)

### P1 — Load architecture context

Read `.agents/skills/android-context/SKILL.md` and follow it exactly.
This loads architecture, modules, components, extensions for this project.
If the knowledge base does not exist it is created first via `@android-architect`.
Record the loaded context — it governs every architectural decision below.

### P2 — Check android-cli

```bash
command -v android && android --version 2>/dev/null || echo "MISSING"
```

If missing, fall back to web search for Android API / docs lookups.
If present, prefer:
```bash
android docs search "<keywords>"
android docs fetch "<url>"
```

### P3 — Verify project structure

Check that `specs/`, `plan/`, and `Progress.md` exist at the project root.
If any are missing the project was not set up with `android-new-project`.
Surface this to the orchestrator:

> "Project is missing `specs/`, `plan/`, or `Progress.md`. Run
> `@android-architect` in INDEX mode (it triggers Mode C for new projects)
> before calling this skill."

Stop and do not proceed until the orchestrator confirms the structure exists.

---

## Mode A — SPEC

### Goal

Produce an organised, multi-file spec under `specs/features/<slug>/` or
`specs/bugs/<slug>/` and present it to the user for review. Nothing is
implemented yet.

---

### A1 — Derive the spec slug

- Lowercase, hyphenated, max 40 chars, no stopwords.
- From `feature:` input or Jira ticket title.
- Example: `user-profile-edit`, `fix-crash-on-logout`.
- Check `specs/features/` (or `specs/bugs/`) — if a folder with this slug
  already exists, ask the orchestrator whether to overwrite or pick a new slug.

### A2 — Gather requirements

Collect all available inputs:

- Feature description or Jira ticket body (use the `jira` skill if a ticket
  ID is provided: read `.agents/skills/jira/SKILL.md`)
- Figma links — if provided, use `get_design_context` and `get_screenshot`
  to pull design context, component names, states, spacing, and copy
- Confluence links — if present in the ticket, use the `confluence` skill
- Existing code — search the codebase for related screens, ViewModels, repos,
  and data classes that this feature touches (use the loaded architecture
  context to narrow the search)

If requirements are too thin to write a meaningful spec, emit a structured
question block to the orchestrator:

```
SPEC_CLARIFICATION_NEEDED
  missing: [list of items]
  questions:
    - Q1: <question>
    - Q2: <question>
```

Stop and wait for the orchestrator to relay answers before continuing.

### A3 — Identify spec scope

Decide which optional spec files to create:

| File | Create when |
|------|-------------|
| `spec.md` | Always |
| `ux.md` | Feature has UI changes (screens, states, navigation) |
| `api.md` | Feature touches data layer, API, or DB schema |
| `edge-cases.md` | Always (even simple features have edge cases) |
| `open-questions.md` | There are unresolved decisions |

### A4 — Write spec files

Create `specs/<type>/<slug>/` and write each file.

---

#### `spec.md` (always)

```markdown
# Spec: <Feature name>

**Date:** <YYYY-MM-DD>
**Status:** draft
**Type:** feature | bug
**Ticket:** <TICKET-ID or "—">
**Slug:** <slug>
**Plan:** [plan/features/<slug>.md](../../../plan/features/<slug>.md)

---

## Overview
One paragraph: what problem this solves and what the outcome looks like.

## User stories
- As a <user>, I want <action> so that <value>.

## Acceptance criteria
- AC-1: Given <context>, when <action>, then <outcome>.
- AC-2: ...
- AC-3: ...

## Non-goals
What this spec explicitly does NOT cover.
```

---

#### `ux.md` (UI features only)

```markdown
# UX: <Feature name>

**Figma:** <url or "—">

## Screens & states
| Screen | States | Notes |
|--------|--------|-------|
| <ScreenName> | Loading / Content / Error | ... |

## Navigation
- Entry point: <screen / deep link>
- Exit: <back / result>
- Back stack behaviour: <pop / replace / none>

## Copy decisions
- Button labels, error messages, empty states.

## Accessibility notes
- Content descriptions for icon-only buttons.
- Focus order for complex layouts.
```

---

#### `api.md` (data layer / API features)

```markdown
# Data model & API: <Feature name>

## Data classes
```kotlin
// key domain models
```

## API contract
| Endpoint | Method | Request | Response | Errors |
|----------|--------|---------|----------|--------|

## Persistence
- Room entities / DAOs affected (if any).
- Cache strategy: <none / TTL / invalidate-on-write>.

## Error codes
| Code | Meaning | UI behaviour |
|------|---------|-------------|
```

---

#### `edge-cases.md` (always)

```markdown
# Edge cases & error states: <Feature name>

| Scenario | Expected behaviour | AC ref |
|----------|--------------------|--------|
| Network error | Show error state with retry button | AC-3 |
| Empty response | Show empty state with illustration | AC-2 |
| ... | ... | ... |
```

---

#### `open-questions.md` (when unresolved decisions exist)

```markdown
# Open questions: <Feature name>

| # | Question | Owner | Due | Answer |
|---|----------|-------|-----|--------|
| OQ-1 | <question> | <name or "—"> | <date or "—"> | — |
```

---

### A5 — Update plan/index.md

Add a row to `plan/index.md`:

```markdown
| feature | <Feature name> | draft | [specs/features/<slug>/spec.md](specs/features/<slug>/spec.md) |
```

### A6 — Update Progress.md

Add to the **In progress** section:

```markdown
- Spec `<slug>` written — awaiting review (`specs/features/<slug>/spec.md`)
```

### A7 — Present to user

Emit to the orchestrator:

```
SPEC_READY
  slug: <slug>
  files:
    - specs/features/<slug>/spec.md
    - specs/features/<slug>/ux.md         (if created)
    - specs/features/<slug>/api.md        (if created)
    - specs/features/<slug>/edge-cases.md
    - specs/features/<slug>/open-questions.md (if created)
  summary: <2-sentence description of what the spec covers>
  awaiting: user review and approval
```

The orchestrator surfaces the spec to the user.

**Do not proceed to IMPLEMENT mode until the user explicitly approves the spec.**
Approval means the user has replied with "approved", "looks good", "proceed",
or equivalent — AND the `spec.md` status field has been updated to `approved`.

The orchestrator is responsible for relaying the approval signal.

---

## Mode B — IMPLEMENT

### Goal

Take an approved spec and implement it phase-by-phase with TDD, full test
coverage, and continuous plan/progress tracking.

---

### B1 — Load and validate the spec

Read `specs/<type>/<spec_slug>/spec.md`.

- Confirm `**Status:** approved`. If still `draft`, emit:
  ```
  SPEC_NOT_APPROVED
    spec: specs/<type>/<spec_slug>/spec.md
    action: update status to "approved" before calling IMPLEMENT
  ```
  Stop.

- Read all other spec files in the folder (`ux.md`, `api.md`,
  `edge-cases.md`, `open-questions.md`).

- Check `open-questions.md` for unanswered OQs that block implementation.
  If any are blocking, surface them to the orchestrator with:
  ```
  BLOCKING_OPEN_QUESTIONS
    items: [OQ-1, OQ-2]
  ```
  Stop until answered.

### B2 — Create the plan file

Create `plan/features/<slug>.md` (or `plan/bugs/<slug>.md`) using the
template below. Each phase maps to one or more acceptance criteria from the
spec. Reference AC items explicitly.

```markdown
# Plan: <Feature name>

**Spec:** [specs/features/<slug>/spec.md](../../specs/features/<slug>/spec.md)
**Status:** in-progress
**Ticket:** <TICKET-ID or "—">
**Branch:** <branch-name>

## Goal
<one sentence from spec overview>

## Phases overview
| Phase | Description | AC refs | Status |
|-------|-------------|---------|--------|
| 1 | Data layer | AC-1, AC-2 | pending |
| 2 | Domain / use cases | AC-1, AC-2 | pending |
| 3 | ViewModel + state | AC-1, AC-3 | pending |
| 4 | Compose UI | AC-2, AC-3 | pending |
| 5 | DI wiring + integration | all | pending |

## Phase 1 — Data layer
**Goal:** <one sentence>
**AC refs:** AC-1, AC-2
**Files:**
- add: `path/to/File.kt` — purpose
- edit: `path/to/Other.kt` — what changes

**Tests:**
- `path/to/Test.kt` — what it asserts [unit]

**Commits:**
1. `test(data): add failing tests for <X>`
2. `feat(data): implement <X>`

**Definition of done:** <observable outcome>

---
_(Repeat block for each phase)_
```

Update `plan/index.md` — change status from `draft` to `in-progress`.

### B3 — Prepare the branch

```bash
git stash push --keep-index=false -m "android-sdd auto-stash"
git checkout main && git pull origin main
git checkout -b <slug>-sdd
```

Do NOT pass `-u` / `--include-untracked` to `git stash`.
Record the branch name in the plan file.

### B4 — Present the phased commit plan

Show the orchestrator/user:

```
## Implementation plan: <Feature name>

**Spec:** specs/features/<slug>/spec.md
**Plan:** plan/features/<slug>.md
**Branch:** <branch>
**Phases:** <N>
**Total commits:** <N> (TDD: failing test → fix for each phase)

### Phase 1 — <title> (AC-1, AC-2)
  Commit 1: test(data): add failing tests for <X>
  Commit 2: feat(data): implement <X>
  Tests: <test file paths>

### Phase 2 — ...

### Open questions resolved: <list or "none">
```

**MANDATORY GATE — stop and wait for explicit approval from the user.**
Do not proceed until the orchestrator relays "approved" / "go" / "proceed".
If the user requests changes to the phase breakdown, revise the plan file,
show the revised plan, and ask again.

---

### SPEC_SYNC — Mid-implementation spec update cycle

This cycle can be triggered at any point during B5. When triggered, it takes
priority over everything — the current phase is paused until the spec is
updated and approved.

**The rule:** the spec is always the source of truth. If code and spec diverge,
update the spec first, get approval, then continue coding. Never silently
handle something the spec doesn't know about.

#### Trigger conditions

Stop the current phase immediately and enter SPEC_SYNC when you encounter any
of the following:

| Trigger | Example |
|---------|---------|
| **Technical constraint** | An AC is impossible as written — platform API doesn't work that way, dependency doesn't support it, architecture layer rule blocks the approach |
| **New edge case** | Coding reveals a failure mode not listed in `edge-cases.md` — e.g. concurrent requests, stale cache, partial data |
| **API contract drift** | Actual backend response differs from `api.md` — different field name, nullable where it wasn't, extra error code |
| **Open question answered** | An OQ from `open-questions.md` gets resolved and the answer changes the approach |
| **AC needs rewording** | An AC is ambiguous and implementation revealed two valid interpretations — need to lock in which one |
| **Scope change** | User or new discovery reveals the feature needs more or less than what the spec says |

Do **not** enter SPEC_SYNC for minor implementation details (variable names,
file locations, minor refactors) — only when the spec itself would be wrong or
incomplete if not updated.

#### SPEC_SYNC steps

**S1 — Stop and emit**

Immediately stop writing code. Do not commit any partial work. Emit to the
orchestrator:

```
SPEC_SYNC_TRIGGERED
  phase: <current phase number and title>
  trigger: <one of: technical_constraint | new_edge_case | api_drift |
            oq_answered | ac_ambiguity | scope_change>
  description: <1–2 sentences: what was discovered and why the spec needs updating>
  affected_files: [spec.md | ux.md | api.md | edge-cases.md | open-questions.md]
  impact_on_plan: <none | add_phase | remove_phase | revise_phase_N>
```

**S2 — Classify the spec change**

Based on the trigger, identify exactly which spec file(s) need updating:

| Trigger | Files to update |
|---------|----------------|
| Technical constraint that changes an AC | `spec.md` (revise AC) + optionally `edge-cases.md` |
| New edge case | `edge-cases.md` (add row) |
| API contract drift | `api.md` (update contract) + `edge-cases.md` if new error code |
| OQ answered | `open-questions.md` (fill Answer column) + whichever file the answer affects |
| AC ambiguity | `spec.md` (clarify AC wording) |
| Scope shrinks | `spec.md` (add to Non-goals) |
| Scope grows | `spec.md` (add AC) + possibly `ux.md` / `api.md` + new plan phase |

**S3 — Propose the spec change**

Show the exact proposed edits to the spec file(s) as fenced diffs in chat.
Do not write any file yet. Format:

```
## Spec update proposal — <slug>

### Trigger
<what was discovered>

### Proposed changes

#### EDIT: specs/features/<slug>/edge-cases.md
```diff
+ | Concurrent request while loading | Cancel in-flight request, show latest result | AC-2 |
```

#### EDIT: specs/features/<slug>/spec.md  (if AC wording changes)
```diff
- AC-2: Given valid user data, when loaded, then show profile.
+ AC-2: Given valid user data, when loaded (cancelling any in-flight request), then show latest profile.
```

### Impact on plan
<none | "Phase 3 needs an extra commit for request cancellation logic">

Apply this spec update? (yes / revise: <feedback> / reject: use different approach)
```

Wait for the orchestrator to relay the user's reply.

- **`yes`** → proceed to S4.
- **`revise: <feedback>`** → incorporate feedback, re-show the proposal, ask again.
- **`reject`** → the spec stays unchanged. Find an implementation approach that
  satisfies the existing spec without adding the triggering behaviour. Resume B5
  from where it stopped.

**S4 — Apply and commit the spec update**

Write the approved spec file changes. Then commit:

```bash
git add specs/<type>/<slug>/<file>.md
git commit -m "docs(spec): update <slug> — <trigger summary>"
```

Use specific file paths — never `git add .`.

**S5 — Update the plan if needed**

If the spec change adds a new AC:
- Add a new phase to `plan/features/<slug>.md` for that AC.
- Update the phases overview table.
- Update `plan/index.md` if the feature's scope label changed.

If the spec change removes or narrows an AC:
- Mark the affected phase in the plan as `cancelled` and note why.
- Do not delete the phase row — keep history.

If the plan changes, show the revised plan to the user and get confirmation
before proceeding.

**S6 — Update tests if existing tests are now wrong**

If the spec change makes a previously written test assert the wrong behaviour
(e.g. an AC was reworded), update the test in the same commit as the spec
update (S4) or as an immediate follow-up commit:

```bash
git commit -m "test(<scope>): update AC tests to match revised spec"
```

Do not leave a passing test that asserts something the spec no longer says.

**S7 — Resume the phase**

Return to the step in B5 where SPEC_SYNC was triggered. Continue as if
the spec always said what it now says. The TDD loop (B5.2) resumes from
whichever commit (A or B) was in progress.

---

### B5 — Implement phase-by-phase

For each phase, follow this loop:

#### B5.1 — Mark phase in-progress

Update the phase status in `plan/features/<slug>.md` to `in-progress`.
Update `Progress.md` — move the feature from **In progress** to show the
current phase:

```markdown
- `<slug>` — Phase <N>/<total>: <phase title>
```

#### B5.2 — TDD loop (mandatory for every commit pair)

**Commit A — failing test:**

1. Show the exact proposed test file content as a fenced code block in chat.
   Wait for explicit approval before writing any file.
2. Write ONLY the test file.
3. Run:
   ```bash
   ./gradlew :<module>:testDebugUnitTest --tests "<FQN>"
   ```
4. The test MUST fail **at runtime with an assertion failure** — NOT a compile
   error. If it fails with `Unresolved reference`, introduce a minimal no-op
   stub in this same commit so the assertion runs against the real (missing)
   behaviour.
5. Paste the FULL raw gradle output verbatim as a fenced code block — never
   summarise ("4 tests, 1 failure" is not acceptable). Include: the exact
   command, all `> Task :...` lines, test class FQN, every method
   PASSED/FAILED/SKIPPED with stack trace for failures, and the final
   `BUILD FAILED` line.
6. Commit: `git add <specific files> && git commit -m "test(<scope>): add failing tests for <X>"`
7. **STOP** — emit to orchestrator:
   ```
   FAILING_TEST_CONFIRMED
     commit: <sha>
     output: <paste of gradle output already shown>
     awaiting: approval to proceed to fix commit
   ```
   Do NOT write the fix until the orchestrator relays user approval.

**Commit B — implementation:**

1. Show the exact proposed changes (new files as full content, edits as unified
   diffs) in chat. Wait for explicit approval before writing any file.
2. Apply approved changes. If during implementation you discover the approved
   diff is wrong (missing import, wrong signature), STOP — re-emit a revised
   preview and wait for approval again. Never silently patch.
   **If you encounter a SPEC_SYNC trigger condition while writing code** (new
   edge case, API drift, technical constraint, etc.) — STOP here, enter the
   SPEC_SYNC cycle above, and resume this step only after the spec update is
   approved and committed.
3. Run:
   ```bash
   ./gradlew :<module>:assembleDebug
   ./gradlew :<module>:testDebugUnitTest --tests "<FQN>"
   ```
4. Paste FULL raw output verbatim for both commands.
5. The test MUST pass. All prior tests MUST still pass.
6. Commit: `git add <specific files> && git commit -m "feat(<scope>): implement <X>"`

**Compose UI phases — additional test commit:**

For phases that include Compose UI (screens, components), add a third commit:

```
Commit C — Compose UI tests
```

Cover all `UiState` branches (Loading, Content, Error) and the corner cases
listed in `edge-cases.md`. One test method per branch/scenario. Use test tags
from the `<FeatureName>TestTags` constants object (never inline strings).

```kotlin
// example shape
@Test fun showsLoadingState() { ... }
@Test fun showsContentState_withItems() { ... }
@Test fun showsErrorState_withRetryButton() { ... }
@Test fun emptyContent_showsEmptyState() { ... }
```

Run with:
```bash
./gradlew :<module>:connectedAndroidTest
```

If a connected device/emulator is unavailable, note it and run
`createDebugAndroidTestApk` as a compile check instead — flag the gap to
the user.

**Unit-toolkit component phases:**

Every new `:ui-toolkit` component requires:
- `@Preview` in the component file
- A Compose UI test covering: renders correctly, disabled state (if applicable),
  click callback fires (if applicable)

#### B5.3 — Build check after each phase

After both commits in a phase land, run assembleDebug per module:

```bash
./gradlew :<module>:assembleDebug
```

Discover modules via `cat settings.gradle.kts` or `./gradlew projects`.
Never run root-level `assembleDebug` — always per module so failures attribute
cleanly.

Paste FULL raw output verbatim. Fix any failures caused by your changes before
proceeding to the next phase.

#### B5.4 — Mark phase done

Update `plan/features/<slug>.md` — change phase status to `done`.
Update `Progress.md` to reflect the next phase.

### B6 — Lint and final build

After all phases are complete:

```bash
./gradlew :<module>:lintDebug
./gradlew :<module>:testDebugUnitTest
./gradlew :<module>:assembleDebug
```

Paste FULL raw output verbatim for all three. Fix lint warnings that are
caused by the new code. Do not fix pre-existing lint warnings in unrelated code
unless the user explicitly asks.

### B7 — Update spec status

Edit `specs/<type>/<slug>/spec.md` — change `**Status:**` from `approved` to
`in-progress`.

(It will be updated to `done` after the PR is merged — not by this skill.)

### B8 — Update plan and progress

In `plan/features/<slug>.md`: change `**Status:**` to `done`.
In `plan/index.md`: change the row status to `done`.
In `Progress.md`:
- Move the feature from **In progress** to **Completed**:
  ```markdown
  - `<slug>` — <Feature name> — all phases shipped, PR pending
  ```

### B9 — Report to orchestrator

```
IMPLEMENT_COMPLETE
  slug: <slug>
  branch: <branch>
  commits: <N>
  phases_done: <N>/<N>
  tests_added: <list of test file paths>
  plan: plan/features/<slug>.md
  spec: specs/features/<slug>/spec.md
  next: push branch and create PR (orchestrator decides)
```

The orchestrator decides whether to push and create a PR. This skill does NOT
push automatically.

---

## Architecture constraints (enforced throughout)

Derived from the loaded architecture context and `CLAUDE.md`. Abort and surface
a violation rather than silently break a rule.

- No business logic in `@Composable` functions — only in ViewModels or UseCases.
- No `GlobalScope` — use `viewModelScope`, `lifecycleScope`, or injected scope.
- No `!!` operators.
- No hardcoded strings — use string resources.
- No hardcoded colors or dimensions — use design tokens from `:ui-toolkit`.
- `shared/domain/` must have zero Android imports.
- Every new ViewModel: unit tests for every state transition.
- Every new UseCase: unit test in `commonTest`.
- Every new screen: Compose UI tests for all `UiState` branches + edge cases.
- Every new `:ui-toolkit` component: Compose UI test.
- Test tags in constants objects — never inline strings in test assertions.
- `shared/` module does NOT use Hilt — constructor injection only.
- Feature modules depend on `:ui-toolkit` via `project(":ui-toolkit")` — never
  as a published artifact.

---

## Commit message conventions

```
test(<scope>): add failing tests for <X>
feat(<scope>): implement <X>
test(<scope>): add compose UI tests for <Screen>
fix(<scope>): <fix description>
docs(spec): update spec status for <slug>
docs(spec): update <slug> — <trigger summary>        ← SPEC_SYNC update
test(<scope>): update AC tests to match revised spec  ← SPEC_SYNC test fix
```

Always use specific file paths in `git add` — never `git add .` / `-A`.
Never stage `.claude/`, `.cursor/`, `.gemini/`, or `.agents/` unless the
feature explicitly requires changes there.

---

## Rules

- Never implement before the spec is approved.
- Never start a phase before the commit plan is approved.
- Never write or edit a file without first showing the proposed change in chat
  and receiving explicit approval from the orchestrator/user.
- Never summarise gradle output — always paste verbatim.
- Never push — the orchestrator controls push and PR creation.
- Always trace commits back to acceptance criteria from the spec.
- If a requirement is ambiguous, emit a `SPEC_CLARIFICATION_NEEDED` block and
  stop rather than guessing.
- **Spec is always the source of truth.** If code and spec diverge at any
  point during implementation, enter SPEC_SYNC immediately — never patch
  around a spec gap silently.
- **Never leave a passing test that asserts something the spec no longer
  says.** If a spec update invalidates a test, fix the test in the same
  commit or the next one.
- **One SPEC_SYNC per trigger.** Do not batch multiple unrelated spec changes
  into a single SPEC_SYNC cycle — each trigger gets its own proposal,
  approval, and commit so the history is readable.
