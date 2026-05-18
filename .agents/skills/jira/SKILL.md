---
name: jira
description: >
  Query Jira (UserTesting RAD project) via the Atlassian MCP. Covers JQL
  search templates, the default minimal `fields` whitelist that prevents
  MCP response overflow, pagination, and recovery steps when a response
  still exceeds the token limit and the MCP dumps it to a local file.
---

# Jira — UserTesting RAD Query Skill

## Access

- **Use the connected Atlassian MCP tools** — do NOT use the Jira REST API directly.
- Primary tool: `searchJiraIssuesUsingJql` (search). Also: `getJiraIssue` (single issue), `createJiraIssue`, `editJiraIssue`, `transitionJiraIssue`.
- **cloudId:** `user-testing.atlassian.net`
- **Project key:** `RAD`
- **Tool names are dynamic** — the MCP server UUID varies per environment. Resolve the full name with `ToolSearch query: "select:mcp__atlassian__searchJiraIssuesUsingJql"` (or keyword search) before calling.

---

## ⚠️ Overflow Prevention — Read This First

The Atlassian MCP's `searchJiraIssuesUsingJql` has a response token limit. When exceeded, the response is dumped to a **user-specific local file** (`~/.claude/projects/<dir>/<uuid>/tool-results/...`) and the tool call returns an error. Any workflow that depends on reading that file produces **different results on different machines** — the path, the file's existence, and the agent's ability to recover all vary per user. **Do not design around recovery; design around prevention.**

**Verified MCP behavior:** the `fields` parameter does **not** exclude `description` from responses. Passing `fields` without `"description"` still returns descriptions. A typical RAD bug description is ~3 KB of markdown, so ~30 issues is enough to overflow.

### What actually works (verified 2026-04-17)

1. **Start with `maxResults: 8`** for broad searches against `RAD` bugs. This is empirically safe on the current dataset. But description sizes vary across environments and grow over time, so treat `8` as a **starting value, not a fixed cap** — see the Adaptive Retry section below.

2. **Do NOT rely on `nextPageToken`.** The MCP accepts it as an input parameter but does **not** return it in the response — so there is no portable way to page through results. `totalCount` in the response reflects the returned count, not the matching count.

3. **Split broad queries into narrower filters** when you need a complete picture. Instead of "all recently updated Android bugs", issue separate queries by priority, status, or label. Each narrow query stays under the limit and together they cover the space.

### Adaptive Retry — halve and retry on overflow

Bug descriptions on some machines or at some points in time may be large enough that `maxResults: 8` still overflows. Use this retry strategy automatically, without asking the user:

```
attempt 1:  maxResults: 8
  on overflow → attempt 2: maxResults: 4
    on overflow → attempt 3: maxResults: 2
      on overflow → attempt 4: maxResults: 1
        on overflow → narrow the JQL (priority/status/date split) and restart at 8
```

Each halving step strictly lowers the response size; if `maxResults: 1` still overflows, a single issue's description exceeds the MCP limit and the right move is to tighten the JQL filter (not to read the saved file). Do **not** stop at the first overflow — keep halving until a call succeeds or you've reached `1`.

### `fields` whitelist — best practice, but not a size guard

Pass it for intent clarity and to trim custom fields/attachments. Do **not** rely on it to prevent overflow.

**Default minimal set:**

```json
["summary", "status", "issuetype", "priority", "created", "updated", "labels", "assignee"]
```

**When to add more:**

| Field | Add when |
| --- | --- |
| `description` | Accept the size cost, and drop `maxResults` to 5. Better: fetch single-issue detail via `getJiraIssue`. |
| `parent` | You need the epic/parent. |
| `customfield_13646` | You need the Smart Checklist (Railsware). |
| `customfield_10001` | You need the team assignment. |
| `issuelinks` | Cluster analysis. |

---

## Common Parameters

| Parameter | Value |
| --- | --- |
| `cloudId` | `"user-testing.atlassian.net"` |
| `responseContentFormat` | `"markdown"` for human reports, `"adf"` for full-fidelity content or writes. |
| `maxResults` | **Start at `8`** for broad RAD bug searches. On overflow, halve and retry (8 → 4 → 2 → 1). Only raise above 8 when filters narrow results to <5 issues. |
| `nextPageToken` | Accepted as input but **not returned by this MCP** — cannot be used to page through a broad result set. |

---

## Query Templates

All templates use `searchJiraIssuesUsingJql` with `cloudId: "user-testing.atlassian.net"` and `fields` = the default whitelist above unless noted.

All broad templates use `maxResults: 15` and must be paginated via `nextPageToken`.

### ⚠️ Android-scope filter — use the full OR clause

Many Android crash bugs are filed **without** the `Android` / `mobile` label — the recent convention is to encode the platform in the summary (`Android - ...`, `[Android] ...`, `Crash - Android - ...`). A label-only filter misses them. The canonical Android scope for this project is:

```
(labels = "Android" OR labels = "mobile" OR summary ~ "Android" OR summary ~ "Crash - Android")
```

Use this clause in **every** Android-scoped template below. Do not substitute a narrower label-only filter.

### New Android bugs since a date
- `jql`: `project = RAD AND issuetype = Bug AND (labels = "Android" OR labels = "mobile" OR summary ~ "Android" OR summary ~ "Crash - Android") AND created >= "YYYY-MM-DD" ORDER BY created DESC`
- `maxResults`: `8`
- `responseContentFormat`: `"markdown"`
- Returns the top-N by the `ORDER BY` — for complete coverage, split by priority/status.

### Open Android bugs
- `jql`: `project = RAD AND issuetype = Bug AND (labels = "Android" OR labels = "mobile" OR summary ~ "Android" OR summary ~ "Crash - Android") AND statusCategory != Done ORDER BY priority ASC, created DESC`
- `maxResults`: `8`
- `responseContentFormat`: `"markdown"`
- Returns the top-N by the `ORDER BY` — for complete coverage, split by priority/status.

### Recently updated Android bugs
- `jql`: `project = RAD AND issuetype = Bug AND (labels = "Android" OR labels = "mobile" OR summary ~ "Android" OR summary ~ "Crash - Android") AND updated >= "YYYY-MM-DD" ORDER BY updated DESC`
- `maxResults`: `8`
- `responseContentFormat`: `"markdown"`
- This query matches 30+ issues. To cover the full set, split by priority: one call with `AND priority in ("Immediate","High")`, one with `AND priority in (Medium, Low, "N/A")`.

### Release tickets (Android)
- `jql`: `project = RAD AND issuetype in (Bug, Task) AND summary ~ "release" AND (labels = "Android" OR summary ~ "Android") AND created >= "YYYY-MM-DD" ORDER BY created DESC`
- `maxResults`: `8`
- `responseContentFormat`: `"markdown"`
- Returns the top-N by the `ORDER BY` — for complete coverage, split by priority/status.

### Bugs mapped to a specific crash keyword
- `jql`: `project = RAD AND issuetype = Bug AND (summary ~ "KEYWORD" OR description ~ "KEYWORD") ORDER BY created DESC`
- `maxResults`: `8`
- `responseContentFormat`: `"markdown"`
- Returns the top-N by the `ORDER BY` — for complete coverage, split by priority/status.
- **Note:** `description ~ ` only searches; it does not return the description body unless `"description"` is in `fields`.

### Single issue with full detail
Use `getJiraIssue` (not search) when you need the description:
- `cloudId`: `"user-testing.atlassian.net"`
- `issueIdOrKey`: e.g. `"RAD-73724"`
- `fields`: include `"description"` as needed

---

## Covering a Broad Result Set

Because the MCP does not return `nextPageToken`, you cannot walk through every matching issue. Use one of these portable strategies:

### 1. Accept top-N by sort order
`maxResults: 8` with a good `ORDER BY` (e.g. `priority ASC, updated DESC`) gives the 8 most important issues. For a QA insights report, that's usually what you want — the oldest low-priority backlog bugs don't change the analysis.

### 2. Split by filter
When you need broader coverage, split the query by a partitioning filter and run each slice in parallel:

- **By priority:** `AND priority in ("Immediate","High")` + `AND priority in (Medium, Low, "N/A")`
- **By status:** `AND status in ("Open","In Progress","Ready To Start")` + `AND status in (Done, Closed, "Ready To Deploy")`
- **By label:** `AND labels = "Android"` + `AND labels = "mobile"` + `AND summary ~ "Android"` + `AND summary ~ "Crash - Android"` (for bugs without any label)
- **By date:** halve the date window

Each slice stays under the limit. Concatenate the returned issue lists before analysis.

---

## Overflow Recovery — Last Resort Only

If a call overflows, the Adaptive Retry ladder (8 → 4 → 2 → 1) is the first response. If `maxResults: 1` still overflows, narrow the JQL (see "Covering a Broad Result Set" above).

Do **NOT** fall back to reading the MCP's saved local file as part of any agent or skill workflow — **that path is user-specific (`/Users/<username>/.claude/projects/.../tool-results/...`) and the recovery produces different results on different machines**, which is the exact reproducibility bug this skill was rewritten to prevent.

Saved-file inspection via `jq` is fine for one-off local debugging, but never bake it into an agent prompt or skill instruction.

---

## Writing (create / edit / transition)

- `createJiraIssue`: `cloudId`, `projectKey`, `issueTypeName`, `summary`. Set `contentFormat: "markdown"` when passing a markdown `description`.
- `editJiraIssue`: supply `fields` with the fields you want to change. ADF fields (e.g. Smart Checklist `customfield_13646`) must be passed as ADF JSON, not markdown.
- `transitionJiraIssue`: list available transitions first with `getTransitionsForJiraIssue`.
- **Two-step write pattern** for ADF custom fields (Smart Checklist, etc.): create with `createJiraIssue`, then set the ADF field via `editJiraIssue`. Writing ADF during create is less reliable.

---

## Custom Fields Reference (RAD project)

| Field ID | Name | Format | Notes |
| --- | --- | --- | --- |
| `customfield_13646` | Smart Checklist (Railsware) | ADF | See "Smart Checklist" below. |
| `customfield_10001` | Team | string (team ID) | PX Mobile team = `"65250fdf-279c-4345-8acd-9fbc64ed85ac"`. |

---

## Smart Checklist (`customfield_13646`)

The Smart Checklist is rendered by the Railsware plugin from ADF (Atlassian Document Format) content. Write it via `editJiraIssue` with `customfield_13646` in the `fields` object.

### Item format rules

- Each checklist item's text **MUST start with `[] `** (square brackets + space) to render as an unchecked checkbox.
- **Each item is exactly:** one `listItem` → one `paragraph` → one `text` node. No nested structure inside an item.
- **Do NOT use** headings, nested `bulletList`s, or `hardBreak` nodes anywhere in the checklist — Smart Checklist turns each of these into a separate (broken) checkbox.
- Keep all per-item detail on a **single line**, pipe-separated: name, covers, pre, steps, expected.

**Canonical per-item format:**
```
[] TC-XX: [Name] [OPTIONAL-PRIORITY] | Covers: [Jira IDs or crash counts] | Pre: [preconditions] | Steps: (1)... (2)... (3)... | Expected: [result]
```

Priority tags like `[CRITICAL]` / `[HIGH]` / `[MEDIUM]` are optional — include them when the caller is grouping items by priority (e.g. the QA insights agent).

### No self-references in `Covers:` (verified 2026-05-12)

**The `Covers:` segment must NOT reference the ticket the checklist is on.** Writing `Covers: RAD-12345` inside RAD-12345's own Smart Checklist via API causes the Railsware plugin to convert the key into a smart-link `inlineCard` widget, which breaks the visual layout of the pipe-separated line and adds zero information. Apply this rule when composing or accepting checklist items:

| `Covers:` content | Action |
|---|---|
| Only the current ticket key (e.g. just `RAD-12345`) | **Omit the `Covers:` segment entirely** from the item. |
| Current ticket key alongside other values (e.g. `RAD-12345 / Datadog issue X / 47 events`) | **Strip the current-ticket-key reference**, keep the rest. |
| No current-ticket-key (e.g. `Datadog issue X`, component names, or a different ticket `RAD-99`) | **Keep as-is** — cross-ticket / external references are useful. |

This applies to BOTH new-ticket composition (where the caller knows the ticket key in advance) AND the append-to-existing workflow below (where the caller knows the ticket key by definition).

### ADF structure (minimal example)

```json
{"customfield_13646": {"type": "doc", "version": 1, "content": [
  {"type": "bulletList", "content": [
    {"type": "listItem", "content": [{"type": "paragraph", "content": [
      {"type": "text", "text": "[] TC-01: App kill during upload [CRITICAL] | Covers: RAD-71160 | Pre: TOL 5+ tasks | Steps: (1) Reach upload (2) Force-kill (3) Relaunch | Expected: Upload resumes, responses in order"}
    ]}]},
    {"type": "listItem", "content": [{"type": "paragraph", "content": [
      {"type": "text", "text": "[] TC-02: Study finalization [CRITICAL] | Covers: RAD-71159 | Pre: Complete any test | Steps: (1) Complete (2) Verify server-side | Expected: Finalization called, results visible"}
    ]}]}
  ]}
]}}
```

### TC numbering

When appending to an existing checklist, continue numbering from the last existing `TC-XX`. If existing items don't use TC numbers, start new items at `TC-01`.

---

## Append-to-existing Smart Checklist workflow

Use this workflow whenever adding checklist items to an **existing** ticket (bug fix, feature story, etc.). Never erase or rewrite existing items.

### Inputs
- **Ticket ID** (e.g. `RAD-12345`)
- **Context** describing what was changed/fixed (code changes, screens, flows, APIs, UI)
- Optional: PR link, branch name

### Steps

**1) Read existing checklist** — `getJiraIssue` with `fields: ["customfield_13646", "summary"]`. Parse the ADF to extract current item texts (strip the `[] ` prefix for comparison).

**2) Build candidate new items** from the context, covering:
- Happy path — step-by-step for the primary use case
- Edge cases — empty/error states, boundaries, network failures, permission denials
- Negative testing — what should NOT happen
- Regression — related features that could break
- Device/config variations — dark mode, RTL, screen sizes, OS versions (only if relevant)
- Design verification — if UI changed: states match Figma
- Bug reproduction — for fixes: steps to confirm the original bug no longer reproduces

**3) Deduplicate** — compare each candidate against existing items (by scenario, not exact text). Drop anything already covered. If **all** candidates are duplicates, tell the caller "Existing checklist already covers these scenarios. No updates needed." and stop.

**4) APPROVAL GATE** — before writing anything, show the caller:
```
## QA Checklist Update for [TICKET-ID]

### Existing items (will be preserved):
- [list existing items, or "None — checklist is empty"]

### New items to add:
- TC-XX: [Name] — [what it covers]
- ...

Add these [N] items to the Jira checklist? (yes/no)
```
**Do not call `editJiraIssue` until the caller confirms with "yes" / "go" / "add them".**

**5) Merge + write** — build a single `bulletList` whose `content` is: all existing `listItem` nodes first (preserving their text and check state), then the new `listItem` nodes. Write via `editJiraIssue` with `customfield_13646: <merged ADF>`.

**6) Confirm** — "QA checklist updated on [TICKET-ID]. [N] new items added."

---

## Instructions

1. **Identify the query goal** — filter/list, single-issue detail, or write.
2. **Pick the right template** above and swap in date/keyword placeholders.
3. **Pass an explicit `fields` whitelist** — default minimal set unless a specific field is required.
4. **Start with `maxResults: 8`** for broad RAD bug searches. On overflow, halve and retry (8 → 4 → 2 → 1) automatically before any other recovery step. Only raise above 8 when filters narrow results to <5 issues.
5. **For complete coverage, split by filter** (priority / status / label / date) and run slices in parallel. Do not rely on `nextPageToken` — this MCP does not return it.
6. **Never depend on the saved-file recovery path in an agent workflow** — it's user-specific (`/Users/<username>/.claude/...`) and non-portable.
7. **Writes are two-step** for ADF fields — create, then edit.