---
name: github-pr
description: Draft and (optionally) create/update GitHub pull requests with repo PR template enforcement. Jira titles are required by default, but can be explicitly opted out only when the user states no Jira ticket is linked. Uses `gh` CLI only after user confirmation and only when command execution is available.
---

# GitHub PR (Template-first, Jira-by-default with explicit opt-out)

## Purpose
Use this skill when the user asks to create, update, or summarize a GitHub PR, or wants a PR title/body derived from local changes.

Primary goals:
- Always follow the repository PR template when present
- Produce high-signal PR content (purpose + reviewer guidance)
- Enforce Jira-linked titles **by default**
- Allow Jira opt-out **only** when user explicitly says no ticket is linked
- Automate PR creation/update only after explicit confirmation

---

## Jira policy (default + explicit opt-out)

### Default (Jira required)
PR title must be:
`[JIRA-KEY] Jira issue summary`

Jira key regex:
`[A-Z][A-Z0-9]+-[0-9]+`

### Explicit opt-out (allowed only if user says so)
If the user explicitly states one of:
- “no Jira”
- “no Jira card is linked”
- “no ticket”
- “no JIRA ticket”
- “N/A ticket”

Then Jira is not required, and:
- PR title becomes a concise descriptive title (<= 72 chars)
- Ticket section in PR template must be: `N/A (no Jira ticket linked)`

**Do not assume opt-out.** Ask once if Jira is missing:
- “What’s the Jira key for this PR? If there is no Jira ticket, tell me ‘no Jira ticket linked’.”

---

## Template discovery (required)
Use the first existing file in this order:
1. `.github/PULL_REQUEST_TEMPLATE.md`
2. `.github/PULL_REQUEST_TEMPLATE`
3. `.github/pull_request_template.md`
4. First file in `.github/PULL_REQUEST_TEMPLATE/`

If a template exists:
- Preserve section headings exactly
- Do not add new top-level headings
- If template lacks “Testing/Risks”, include them as bullets under **Implementation**

If no template exists, use fallback body at the end.

---

## Workflow

### 1) Gather context (best effort)
If shell execution is available:
- Repo root:
    - `cd "$(git rev-parse --show-toplevel)"`
- Branch + status:
    - `git rev-parse --abbrev-ref HEAD`
    - `git status -sb`
- Fetch (safe):
    - `git fetch --all --prune`
- Commits:
    - `git log --oneline -n 20`
- Base branch:
    - Prefer:
        - `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`
    - If unavailable, ask user for base branch.
- Diff:
    - `git diff --stat <base>...HEAD`
    - `git diff <base>...HEAD` (when needed)

If shell execution is not available, ask the user to paste:
- branch name
- `git status -sb`
- `git diff --stat <base>...HEAD` (or a short summary)

### 2) Resolve Jira (default) or opt-out
- Try to detect Jira key from branch/commits/user input.
- If missing:
    - Ask for Jira key or explicit opt-out phrase.
- If Atlassian tooling exists and Jira key provided:
    - Validate key and fetch canonical Jira summary for the title.
- If Atlassian tooling is not available:
    - Ask user for the Jira task name (exact).

### 3) Draft PR title
- If Jira key is in scope: `[JIRA-KEY] Jira task name`
- If user opted out: concise descriptive title (<= 72 chars)

### 4) Draft PR body (template-first)
Fill repo template sections.

For your repo template, populate:
- **Purpose**: why
- **Implementation**: what changed + reviewer guidance
    - Include:
        - Testing: Not run (not requested) / commands run
        - Risks/Notes: only if meaningful
- **Ticket**:
    - If Jira: link/key
    - If opt-out: `N/A (no Jira ticket linked)`
- **Demo**: link/screenshots or N/A
- **Notifications**: `@usertesting/mobile` (unless user requests otherwise)

### 5) Confirm before running `gh`
Present final:
- base / head
- title
- body preview

Require the user to reply with exactly:
- `CONFIRM CREATE PR` or `CONFIRM UPDATE PR`

### 6) Execute (only after confirmation and only if possible)
If confirmed and tools available:

- Resolve base:
    - `BASE_BRANCH="$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')"`
- Write body:
    - `PR_BODY_FILE="$(mktemp)"`
    - write the drafted body to `$PR_BODY_FILE`
- Detect existing PR:
    - `EXISTING_PR_NUMBER="$(gh pr list --head "$(git rev-parse --abbrev-ref HEAD)" --json number --jq '.[0].number' 2>/dev/null)"`
- Create or update:
    - If exists:
        - `gh pr edit "$EXISTING_PR_NUMBER" --title "$PR_TITLE" --body-file "$PR_BODY_FILE"`
    - Else:
        - `gh pr create --base "$BASE_BRANCH" --head "$(git rev-parse --abbrev-ref HEAD)" --title "$PR_TITLE" --body-file "$PR_BODY_FILE"`
- Validate:
    - `gh pr view --json number,title,body,url,baseRefName,headRefName`

If tools not available:
- Output the exact `gh` commands the user can run locally.

---

## Fallback PR body (only if NO template exists)
```md
# Purpose
…

# Implementation
- …
- Testing: Not run (not requested)

# Ticket
N/A

# Demo
N/A

# Notifications
@usertesting/mobile