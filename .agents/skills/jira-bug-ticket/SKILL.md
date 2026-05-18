---
name: jira-bug-ticket
description: >
  Compose a Jira Bug ticket draft from structured inputs and emit a
  copy-paste handoff that a human pastes into the Jira Create dialog.
  The skill NEVER calls any Jira write tool — it is purely a composer.
  Used by Crash Surveyor (standalone) and the Orchestrator (pipeline);
  both surface the same handoff format to the human who actually files
  the ticket.
---

# Jira Bug Ticket — Composer Skill

## What this skill is

A **stateless composer**. The caller passes structured crash/bug data;
this skill returns a formatted handoff block that a human pastes into
the Jira Create dialog. The skill's contract is:

- **In:** structured inputs (exception, stack, affected, RUM links, steps to reproduce, etc.)
- **Out:** a markdown handoff block — the canonical Bug ticket format, with explicit field placements.
- **Never:** call `createJiraIssue`, `editJiraIssue`, `addCommentToJiraIssue`, `transitionJiraIssue`, or any Jira write tool.

Every Jira mutation is the human's decision. This skill exists so the
**format** is the same whether the caller is Crash Surveyor surfacing a
finding to stdout or an Orchestrator surfacing one to Slack — and so
every caller doesn't re-invent the ticket schema.

For Jira **read** patterns / JQL / overflow handling, see
[`.agents/skills/jira/SKILL.md`](../jira/SKILL.md). This skill is the
focused composer; that one is the broader Jira query reference.

---

## Scope — what this skill does NOT do

- **Does not write to Jira.** No `createJiraIssue` call ever. Output is text.
- **Does not propose updates to existing tickets.** Evidence-section
  updates on an existing Jira (e.g. Crash Surveyor Step 5.2) are a
  different shape — they live in the caller, not here.
- **Does not poll Datadog / Confluence / etc.** Inputs come from the caller.
- **Does not dedup.** The caller is responsible for confirming the
  signature is genuinely new before invoking this skill.

---

## Inputs

The caller passes a single object. All fields except those marked
optional are required; missing required fields → the skill emits a
warning paragraph in place of that section rather than fabricating data.

| Field | Type | Description |
|---|---|---|
| `exception_class` | string | e.g. `IllegalStateException`. Used in the auto-generated title. |
| `top_frame` | string | e.g. `MediaRecorder._start` or `SummaryDemographicsActivity.onKeyUp:142`. |
| `stack_trace` | string | Full long stack, verbatim. Never hash / fingerprint. |
| `affected_users` | int | Unique users in the observation window. |
| `affected_versions` | string[] | App versions where the crash appeared. |
| `os_versions` | string[] | OS versions where the crash appeared. |
| `sessions_count` | int | Total session count in the window. |
| `steps_to_reproduce` | string[] | Numbered actions reconstructed from session replay (or `[]` if unknown). |
| `summary` | string (optional) | Pre-composed title. If omitted, the skill generates `[Auto-detected crash] <exception_class> in <top_frame>`. |
| `rum_session_urls` | string[] (optional) | Session-replay deep-links. **Capped at 3 entries** — if the caller passes more, the skill takes the 3 most recent and drops the rest. |
| `recent_deploys` | object[] (optional) | `{ name, timestamp, url }` entries. **`url` is required per entry** — it must point to the corresponding release ticket / PR / commit. Entries without a `url` are dropped. If no entries remain after the drop, the whole section is omitted. |
| `suspected_cause` | string (optional) | 1-paragraph hypothesis from light code reading + recent diffs. |
| `epic_link` | string (optional) | Parent epic key (e.g. `RAD-ZBP`). Overrides the `epicLinkValue` constant. If neither this input nor the constant is set, the handoff emits a placeholder + warning — see § Missing required values. |
| `team` | `{ value, display }` (optional) | Team override. `value` = team UUID; `display` = human-readable name. Overrides `teamValue` / `teamValueDisplay` constants. Same missing-value fallback as `epic_link`. |
| `qa_checklist` | object[] (optional) | Per-item Smart Checklist data. See § Smart Checklist for shape. If not provided, the skill auto-generates 2–4 default TCs from `steps_to_reproduce` + `affected_versions` + `os_versions`. Caller can pass an empty array `[]` to suppress auto-generation. |
| `acceptance_criteria` | string[] (optional) | List of acceptance-criteria bullet strings. Goes into the **dedicated Acceptance Criteria custom field** (`acceptanceCriteriaFieldKey`, default `customfield_10209`), NOT the description body. If not provided, the skill auto-generates 2–3 defaults from `exception_class` + `affected_versions` + crash-count data. Caller can pass `[]` to suppress auto-generation. |
| `labels` | string[] (optional) | Extra labels to add on top of `defaultLabels`. Deduplicated. |

**Note on event-id / tracker IDs:** the skill does NOT take an `external_event_id` input or write any tracker-id footer in the description. Tracker IDs (e.g. Datadog `issue_id`) are kept in the caller's triage surfaces (e.g. Crash Surveyor's Pending Triage Queue Notes section) — not in the Jira ticket the human creates. Reasoning: pasting tracker IDs into Jira descriptions creates a maintenance surface ("which IDs need updating when the tracker rotates?") and visual noise; the dedup it enables is replaceable with exception-class + top-frame substring matching on the Jira summary, which the caller does anyway.

---

## Constants (overridable at call time)

Defaults below match the **UserTesting `RAD` project**. A different
project (or a different Jira instance) overrides any of these at call
time. The skill reads them from a `constants` object passed by the
caller; missing keys fall back to these defaults.

| Constant | Default (RAD) | Used for |
|---|---|---|
| `projectKey` | `RAD` | Project on Jira Create dialog |
| `issueTypeId` | `10004` | Bug |
| `stepsFieldKey` | `customfield_10330` | Steps to Reproduce custom field |
| `epicLinkFieldKey` | `customfield_10008` | Epic Link custom field |
| `epicLinkValue` | `RAD-ZBP` | Zero-Crash Policy umbrella epic (default; overridable per call via input `epic_link`) |
| `teamFieldKey` | `customfield_10001` | Team custom field |
| `teamValue` | `65250fdf-279c-4345-8acd-9fbc64ed85ac` | PX Mobile team UUID (default; overridable per call via input `team.value`) |
| `teamValueDisplay` | `PX Mobile` | Human-readable team name for the handoff (default; overridable via input `team.display`) |
| `smartChecklistFieldKey` | `customfield_13646` | Smart Checklist (Railsware) — ADF custom field. See § Smart Checklist for the ADF format. |
| `acceptanceCriteriaFieldKey` | `customfield_10209` | Acceptance Criteria — ADF custom field (textarea schema). See § Acceptance Criteria for the format. |
| `defaultLabels` | `["crash-surveyor"]` | Auto-applied labels |
| `createIssueUrl` | `https://user-testing.atlassian.net/secure/CreateIssue!default.jspa` | Deep-link in the handoff |

**Override precedence:** per-call input > `constants` override > default in this table.

A different project drops in their own values by passing `constants`:

```yaml
constants:
  projectKey: ACME
  issueTypeId: "10001"
  stepsFieldKey: customfield_99001
  epicLinkValue: ACME-PLATFORM-CRASH
  teamValueDisplay: Platform
  smartChecklistFieldKey: customfield_88888    # if a different Smart Checklist plugin is installed
  acceptanceCriteriaFieldKey: customfield_99209
  defaultLabels: [auto-crash, p2-mobile]
  createIssueUrl: https://acme.atlassian.net/secure/CreateIssue!default.jspa
```

---

## Field map — which Jira field ID gets which value

The most-asked question when filing a ticket from this skill's handoff:
*"Which field do I paste this into?"* This table answers exactly that.
Field IDs come from the constants above; a different project's instance
may use different field IDs — change them in `constants`.

| Value in handoff | Jira field | Field ID / location | Value format |
|---|---|---|---|
| **Summary** | Summary | (top of Create dialog, no custom-field ID) | Plain text, ≤ 240 chars |
| **Issue Type** | Issue Type | (dropdown, no custom-field ID) | `Bug` (id `<issueTypeId>`) |
| **Project** | Project | (dropdown, no custom-field ID) | `<projectKey>` |
| **Description** | Description | (rich-text body, no custom-field ID) | Markdown — Jira's converter renders `<details>` / hyperlinks / code blocks |
| **Steps to Reproduce** | Steps to Reproduce | `<stepsFieldKey>` (e.g. `customfield_10330`) | Plain text — one step per line, prefixed `1. `, `2. `, etc. |
| **Epic Link** | Epic Link | `<epicLinkFieldKey>` (e.g. `customfield_10008`) | Epic issue key (e.g. `RAD-ZBP`). Value comes from input `epic_link` OR constant `epicLinkValue`. |
| **Team** | Team | `<teamFieldKey>` (e.g. `customfield_10001`) | Team UUID (e.g. `65250fdf-279c-4345-8acd-9fbc64ed85ac`). Value from input `team.value` OR constant `teamValue`. Display name from `team.display` OR `teamValueDisplay`. |
| **Labels** | Labels | (labels field, no custom-field ID) | Comma-separated list. Defaults from `defaultLabels`; caller's `labels` input is appended (de-duplicated). |
| **Smart Checklist** | Smart Checklist (Railsware) | `<smartChecklistFieldKey>` (e.g. `customfield_13646`) | ADF document (JSON) — see § Smart Checklist for the format. Cannot be pasted via markdown — Jira's Smart Checklist plugin requires you to add items individually in the UI OR send the ADF via API. |
| **Acceptance Criteria** | Acceptance Criteria | `<acceptanceCriteriaFieldKey>` (e.g. `customfield_10209`) | ADF document — bullet list of criteria. **Lives in a dedicated field**, NOT inside the description body. Verified empirically on the UserTesting instance 2026-05-12: pasting AC content into the description as a `## Acceptance criteria` heading clutters the description AND fails to populate Jira's native AC widget that the team uses to filter by completeness. Always put AC content in this field. |

**Read me first:** the Smart Checklist field is special. Pasting markdown checklist syntax into the description does NOT populate this field. The Railsware plugin reads from its own custom field (`customfield_13646`). To fill it from this skill's handoff: either (a) the human copies each TC line into the plugin's UI manually, or (b) the orchestrator (when built) calls `editJiraIssue` with the ADF JSON after the ticket is created.

---

## Missing required values — caller responsibility

The skill resolves each field using this chain:

1. Per-call input (e.g. `epic_link`, `team`, `qa_checklist`)
2. `constants` override passed by the caller
3. Default from the constants table above

If none of those produce a value for **Epic Link** or **Team**, the handoff emits a `⚠️ ASK USER` placeholder in the action checklist for that field. The caller is expected to either:

- **(a)** Prompt the user before invoking the skill (preferred — the user types the value, caller passes it in as `epic_link` / `team`, skill emits the value cleanly).
- **(b)** Surface the placeholder as-is and let the human fill it in by hand at the Create dialog.

The skill ALWAYS produces a complete handoff — it does not stop on missing epic / team. The missing-value warning is informational; the caller decides whether to pause or proceed.

For **Smart Checklist** (`qa_checklist`), the skill auto-generates a 2–4 item default from the bug data if no input is provided — see § Smart Checklist. The caller never needs to ask the user for this; the user can edit the auto-generated items in the Jira UI after filing.

**Example handoff snippet when `epic_link` is missing:**

```markdown
7. **Epic Link** (field `customfield_10008`): ⚠️ **ASK USER** — paste the parent epic key here (e.g. `RAD-ZBP`).
```

**Example handoff snippet when `team` is missing:**

```markdown
8. **Team** (field `customfield_10001`): ⚠️ **ASK USER** — paste the team UUID here (the human-readable team name in the dropdown).
```

When the caller is Crash Surveyor for the RAD project: both have defaults (`RAD-ZBP` / `PX Mobile`) so the warning never fires. When the caller is a different project (or wants to override per ticket): pass the values explicitly.

---

## Bug ticket format spec (the contract this skill owns)

### Summary (title)

- If `summary` provided → use as-is.
- Otherwise → `[Auto-detected crash] <exception_class> in <top_frame>`.

Cap at 240 chars (Jira summary limit on the UserTesting instance). If
the auto-generated title exceeds, truncate the `top_frame` portion from
the left with an ellipsis prefix.

### Description (markdown body)

Sections in fixed order. Sections backed by missing optional inputs are
omitted (not stubbed with placeholders).

**Stack trace** and **Suspected cause** are wrapped in nested `<details>`
blocks (default-closed) so the description scans short by default — the
human expands the heavy content on demand. The other sections render
inline since they're short.

```markdown
<details>
<summary><strong>Stack trace</strong></summary>

```
<stack_trace verbatim>
```

</details>

## Affected
- App versions: <affected_versions joined with ", ">
- OS versions: <os_versions joined with ", ">
- Affected users: <affected_users>
- Sessions: <sessions_count>

## RUM session replays    (omit section if rum_session_urls empty)
1. <url 1>
2. <url 2>
3. <url 3>
(Max 3 entries. If the caller passes more, the skill keeps the 3 most recent.)

## Recent deploys (correlation)    (omit section if all entries lack a url)
- [<deploy.name>](<deploy.url>) at <deploy.timestamp>
- [<deploy.name>](<deploy.url>) at <deploy.timestamp>
...

<details>
<summary><strong>Suspected cause</strong></summary>

<paragraph>

</details>
```

### Steps to Reproduce (separate field)

A separate string, NOT part of the description body. It goes into the
Jira custom field identified by `stepsFieldKey`. Format:

```
1. <action 1>
2. <action 2>
...
(Last action triggered the crash.)
```

If `steps_to_reproduce` is empty: emit the literal string
`Not reconstructible from available session data.` Do not omit — the
field is expected to be non-empty on the UserTesting instance.

### Smart Checklist (separate ADF field)

Goes into `<smartChecklistFieldKey>` (default `customfield_13646`). See
the dedicated § Smart Checklist section below for the ADF format and
the default items the skill auto-generates from the bug data.

### Other fields set by the handoff

- **Issue Type:** Bug (id `<issueTypeId>`)
- **Epic Link:** `<epicLinkValue>` (field key `<epicLinkFieldKey>`) — or `⚠️ ASK USER` placeholder if unset
- **Team:** `<teamValueDisplay>` (field key `<teamFieldKey>`, value `<teamValue>`) — or `⚠️ ASK USER` placeholder if unset
- **Labels:** `<defaultLabels>` (+ any `labels` input)

---

## Output — the handoff block

The skill emits this markdown block, which the caller surfaces directly
(crash-surveyor → stdout under each NEW row; orchestrator → wherever it
posts surfaces). Verbatim template:

````markdown
**Action — create a new <projectKey> Bug from this draft:**

⚠️ **Heads up about Description collapsibles:** the `<details>` blocks in the Description below render fine in this stdout view, but Jira's editor will NOT convert them to expand panels when you paste — they'll show as literal text. Two ways to get native expand panels: (a) paste the markdown, then manually wrap Stack trace + Suspected cause sections using **Insert > Expand** in the toolbar; or (b) skip the UI and use `editJiraIssue` API with the ADF form (template in SKILL.md § ADF skeleton).

1. Open <createIssueUrl> (or click "Create" in the Jira top bar).
2. **Project:** `<projectKey>`
3. **Issue Type:** `Bug` (id `<issueTypeId>`)
4. **Summary:** paste from "Summary" below.
5. **Description:** paste from "Description" below (markdown).
6. **Steps to Reproduce** (field `<stepsFieldKey>`): paste from "Steps to Reproduce" below.
7. **Epic Link** (field `<epicLinkFieldKey>`): `<epicLinkValue>`
   <!-- OR, if epic_link is missing — emit instead: -->
   <!-- ⚠️ **ASK USER** — paste the parent epic key here (e.g. `RAD-ZBP`). -->
8. **Team** (field `<teamFieldKey>`): `<teamValueDisplay>` (value `<teamValue>`)
   <!-- OR, if team is missing — emit instead: -->
   <!-- ⚠️ **ASK USER** — paste the team UUID here. -->
9. **Labels:** <defaultLabels joined with ", ">
10. **Smart Checklist** (field `<smartChecklistFieldKey>`): paste each item from "Smart Checklist" below into the plugin's UI (one row per item). The handoff lists the items as plain text; the ADF payload (in case you want to push via API) is in the "Smart Checklist ADF" expandable below.
11. **Acceptance Criteria** (field `<acceptanceCriteriaFieldKey>`): paste from "Acceptance Criteria" below into the dedicated AC field — NOT into the description body. The team uses this field for completion-tracking filters.

After creating, copy the new ticket key (e.g. `<projectKey>-XXXXX`) and
update the upstream surface (Triage Queue row, Slack thread, etc.) to
reflect it.

**Summary:** <the composed title>

<details><summary>Description (markdown)</summary>

<the composed description body>

</details>

**Steps to Reproduce:**

<the composed steps body>

**Acceptance Criteria:**

- <criterion 1>
- <criterion 2>
- <criterion 3>

<details><summary>Smart Checklist (paste each item into the Railsware plugin UI)</summary>

- [] TC-01: <name> | Covers: <crash issue_id or RAD-XXXXX> | Pre: <preconditions> | Steps: (1)... (2)... | Expected: <result>
- [] TC-02: ...
- [] TC-03: ...

</details>

<details><summary>Smart Checklist ADF (for editJiraIssue API call — orchestrator path)</summary>

```json
{
  "customfield_13646": {
    "type": "doc",
    "version": 1,
    "content": [
      {"type": "bulletList", "content": [
        {"type": "listItem", "content": [{"type": "paragraph", "content": [
          {"type": "text", "text": "[] TC-01: <name> | Covers: <id> | Pre: <pre> | Steps: (1)... | Expected: <result>"}
        ]}]}
      ]}
    ]
  }
}
```

</details>
````

(If the fallback path applies — `stepsFieldKey` is null and steps are
inside the description body instead of a dedicated field — the steps
block is omitted at the top level, since it's already part of the
Description.)

**Collapsibility rules** (so the handoff scans short by default but the heavy bits stay one click away):

| Section | Default in handoff |
|---|---|
| Summary | **Inline** — it's one line, collapsing adds friction. |
| Description | `<details>` (collapsed by default) — heavy content. |
| ↳ Stack trace (nested inside Description) | `<details>` (collapsed). |
| ↳ Suspected cause (nested inside Description) | `<details>` (collapsed). |
| Steps to Reproduce | **Inline** when going into the dedicated `stepsFieldKey` custom field (default case). Wrapped in `<details>` only when the fallback path applies (i.e. `stepsFieldKey` is null and steps end up inside the description body). |

---

## ⚠️ Critical: collapsibles render differently in stdout vs Jira

This is the most painful gotcha in this skill — verified empirically against the live Jira instance on 2026-05-12.

**Markdown `<details><summary>...</summary>...</details>` HTML does NOT render as expand panels when pasted into a Jira description.** Atlassian's markdown→ADF converter doesn't translate `<details>` to ADF `expand` nodes — it renders them as literal text or flattens them inline. Two paths exist:

| Path | Description format | Collapsibles |
|---|---|---|
| **Human paste from stdout into Jira Create dialog** | The skill's markdown handoff (with `<details>` blocks) renders fine in a markdown viewer / IDE / chat. When the human pastes it into Jira, the `<details>` blocks become literal text. The human must manually wrap Stack trace + Suspected cause with the **Insert > Expand** macro in Jira's editor to get expand panels. | **No native collapsibles after paste.** Human adds them manually. |
| **API / orchestrator writes the description as ADF** | The description is built as an ADF document with `{type: "expand", attrs: {title: "..."}, content: [...]}` nodes. Sent via `editJiraIssue` with `contentFormat: "adf"`. | **Native expand panels render automatically.** No human action needed. |

**For the API path, the description ADF skeleton looks like this:**

```jsonc
{
  "type": "doc",
  "version": 1,
  "content": [
    // 1. Intro paragraph
    {"type": "paragraph", "content": [/* mixed text + marks */]},

    // 2. Stack trace — ADF expand (not <details>)
    {
      "type": "expand",
      "attrs": {"title": "Stack trace (Firebase, deobfuscated)"},
      "content": [
        {"type": "codeBlock", "content": [{"type": "text", "text": "<full stack>"}]},
        {"type": "paragraph", "content": [/* throw-site annotation */]}
      ]
    },

    // 3. heading "Affected" + bulletList for the bullets
    {"type": "heading", "attrs": {"level": 2}, "content": [{"type": "text", "text": "Affected"}]},
    {"type": "bulletList", "content": [/* listItem nodes */]},

    // 4-5. RUM heading + orderedList, Recent deploys heading + bulletList
    /* ... */

    // 6. Suspected cause — ADF expand
    {
      "type": "expand",
      "attrs": {"title": "Suspected cause"},
      "content": [
        {"type": "paragraph", "content": [/* intro */]},
        {"type": "codeBlock", "attrs": {"language": "kotlin"}, "content": [{"type": "text", "text": "<code>"}]},
        {"type": "paragraph", "content": [/* trigger lead-in */]},
        {"type": "bulletList", "content": [/* 3 trigger items */]},
        {"type": "paragraph", "content": [/* propagation note */]},
        {"type": "paragraph", "content": [/* prior-fix reference with links */]}
      ]
    }
  ]
}
```

**Skill output convention:**
- The skill emits the **markdown form** in the stdout handoff (it's what humans read; the `<details>` collapsibles work in stdout viewers).
- For API callers (Crash Surveyor's Pending Triage Queue "Ticket draft" cell, orchestrator's `editJiraIssue` write), the skill ALSO emits the **ADF form** as a sidecar block in the handoff (currently shown in the "Smart Checklist ADF" expandable below — extend this to cover the description body too). Callers writing to Jira programmatically pick up the ADF directly.

The plain-markdown handoff also includes a one-line warning at the top of the action checklist: *"⚠️ Description `<details>` won't render as expand panels in Jira — use Insert > Expand in the editor or apply the ADF form via API."*

---

## Smart Checklist (`qa_checklist`)

QA test cases that go into the Smart Checklist (Railsware) custom field
(default `customfield_13646`). The skill emits the checklist two ways
in the handoff:

1. **As plain bullets** — the human copies each line into the Railsware
   plugin UI one at a time (Jira doesn't render markdown checklist
   syntax into this field; it must go through the plugin).
2. **As an ADF blob** (collapsible in the handoff) — for the
   orchestrator (when built) to send via `editJiraIssue` after the
   ticket is created. Markdown-only paths skip this.

The plain-bullets format follows the canonical Railsware item format
(see [`.agents/skills/jira/SKILL.md`](../jira/SKILL.md) § Smart
Checklist for the full ADF schema and rendering rules):

```
[] TC-XX: [Name] [OPTIONAL-PRIORITY] | Covers: [Jira IDs or crash counts] | Pre: [preconditions] | Steps: (1)... (2)... (3)... | Expected: [result]
```

### No self-references in the `Covers:` segment

**The `Covers:` segment must NOT reference the ticket the checklist is on.** A self-reference (e.g. `Covers: RAD-75459` on a TC inside RAD-75459) is noise: it adds zero information AND Jira converts the key into an `inlineCard` widget, which makes the line longer and visually breaks the pipe-separated layout.

Three cases the skill handles when composing or accepting `qa_checklist[i].covers`:

| `covers` value | Rendered output |
|---|---|
| Contains the current ticket key as the ONLY value (e.g. just `RAD-75459`) | **Omit the `Covers:` segment entirely** from the item. |
| Contains the current ticket key alongside other values (e.g. `RAD-75459 / Datadog issue X / 47 events`) | **Strip the current-ticket-key reference**, keep the rest. |
| Contains no current-ticket-key (e.g. `Datadog issue X`, `PXActivityExecuteStudy`, or another ticket like `RAD-64735`) | **Keep as-is** — cross-ticket / external references are useful. |

The auto-gen defaults below already follow this rule. When the caller provides `qa_checklist`, the skill applies the rule per item at composition time.

Verified empirically on the UserTesting Jira instance 2026-05-12: applying `Covers: RAD-75459` inside RAD-75459's own Smart Checklist via API caused the plugin to convert the key into a smart-link inline card, making each TC line render with awkward inline card widgets and pushing the rest of the pipe-separated content past the visual break. After stripping the self-references the checklist became scannable.

**Item input shape** (`qa_checklist[i]`):

```yaml
- name: "Reproduce the crash under captured steps"
  priority: HIGH                       # optional — [CRITICAL]/[HIGH]/[MEDIUM]
  covers: "Datadog issue_id 1c71f002-..."   # crash id, RAD-XXXXX, or short note
  preconditions: "App version 10.13+ on Android 13"
  steps:
    - "Open the app and log in"
    - "Reach the Summary / Demographics step"
    - "Press the back button rapidly twice"
  expected: "Activity teardown completes without IllegalStateException"
```

### Default auto-generation (when `qa_checklist` is not provided)

The skill generates 2–4 default TCs from the bug data. Per the no-self-reference rule above, the auto-gen does NOT put the current ticket key in any `Covers:` segment.

1. **TC-01 — Reproduce.** Covers: `<external_event_id-source> issue <short-id> / <event count> <window>` (e.g. `Datadog issue e2987cd8 / 47 events 90d`). Pre: top affected version + device family. Steps: `steps_to_reproduce`. Expected: no crash.
2. **TC-02 — Version coverage.** **No `Covers:` segment** (the scenario itself is the coverage). Pre: each entry in `affected_versions`. Steps: same as TC-01. Expected: no crash on any version.
3. **TC-03 — OS coverage.** **No `Covers:` segment.** Pre: each entry in `os_versions`. Steps: same as TC-01. Expected: no crash on any OS.
4. **TC-04 — Module regression smoke.** Covers: surrounding component name(s) inferred from `top_frame` (e.g. `SummaryDemographicsActivity / KeyEventDispatcher`). Pre: app launched. Steps: navigate to the feature, exercise the primary flow. Expected: feature works normally.

The caller can append more items via `qa_checklist` input — defaults
are merged BEFORE caller items. To suppress the defaults entirely, pass
`qa_checklist: []` (empty array — not omission).

### Numbering rule

When appending to an EXISTING checklist on an existing ticket, continue
numbering from the last `TC-XX`. For a NEW ticket (the normal case for
this skill), start at `TC-01`.

---

## Acceptance Criteria (`acceptance_criteria`)

Goes into the **dedicated Acceptance Criteria custom field** (default
`customfield_10209`), NOT the description body. The team uses this
field for completion-tracking and filter views.

**Format:** ADF bullet list. Each criterion is one `listItem` →
`paragraph` → mixed `text` nodes (inline `code` marks fine for class /
method names / fingerprints, inline `link` marks fine for ticket /
commit references).

**Input shape** (`acceptance_criteria[i]`): a plain string per
criterion. Inline `code` and links are kept as plain text in the input
— the skill detects `backtick-wrapped` substrings and link patterns at
composition time and applies the corresponding ADF marks.

### Default auto-generation (when `acceptance_criteria` is not provided)

The skill generates 2–3 default criteria from the bug data:

1. **Crash absence.** `<exception_class>` (and broader `RuntimeException`) thrown from `<top_frame>` no longer crashes the app.
2. **Recovery path.** On failure, the path cleans up resources (close session, release recorder, etc.) and logs via the team's standard error-reporting tool (Timber + Datadog).
3. **Verification.** Verified on `<primary affected device family / OS>`. Crash count for `<external_event_id>` (or top fingerprint) drops to ~0 in subsequent release.

The caller can provide their own list to suppress defaults, OR pass
`acceptance_criteria: []` to suppress without replacement.

### Why this is a separate field, not a description section

Verified empirically on the UserTesting Jira instance on 2026-05-12 by
applying the skill format to a real ticket ([RAD-75459](https://user-testing.atlassian.net/browse/RAD-75459)).
The original draft placed Acceptance Criteria as a `## Acceptance criteria`
heading in the description body. The user pointed out that Jira has a
dedicated AC field used by the team for filtering and reporting; putting
AC content in the description body fails to populate that field. The
skill now mandates the dedicated-field placement.

---

## Composition rules

1. **Verbatim stack trace.** Never reformat, never truncate, never
   hash. The stack goes inside a fenced code block in Markdown, wrapped
   in a default-closed `<details>` block.

2. **Empty optional sections are dropped, not stubbed.** Don't emit
   `<no RUM links>` or `_pending_` — the section header disappears.

3. **No "TBD" / "to be confirmed" / "needs re-fetch" text** anywhere in
   the output. If a required field is missing, the caller is wrong to
   invoke the skill — the skill emits a single warning paragraph at the
   top of the handoff naming the missing field and stops.

4. **Title length cap is 240 chars.** Truncate `top_frame` from the
   left with `...` if the auto-generated title would exceed.

5. **Steps to Reproduce go in the dedicated custom field, never the
   description.** Some Jira projects render the field as a structured
   numbered list (e.g. via add-ons); duplicating it into the description
   would create two slightly diverging copies.

6. **No tracker IDs in the description.** Datadog `issue_id`,
   Crashlytics issue IDs, etc. live in the caller's triage surface
   (e.g. the Pending Triage Queue Notes section), never in the Jira
   ticket description.

---

## Usage — Crash Surveyor (standalone)

Crash Surveyor's Step 7 hands off to this skill once per NEW signature:

```yaml
inputs:
  exception_class: IllegalStateException
  top_frame: MediaRecorder._start (PxCameraRecorder.kt:147)
  stack_trace: |
    java.lang.IllegalStateException
        at android.media.MediaRecorder._start(Native Method)
        ...
  affected_users: 22
  affected_versions: ["10.13", "10.13.1"]
  os_versions: ["Android 13", "Android 14"]
  sessions_count: 47
  steps_to_reproduce:
    - Open the app and log in.
    - Start a TOL study from the dashboard.
    - Wait for the screen-recorder service to bind.
    - (Crash fires here.)
  rum_session_urls:                                  # max 3 — caller trims if more
    - https://app.datadoghq.com/rum/sessions/<sid1>
    - https://app.datadoghq.com/rum/sessions/<sid2>
    - https://app.datadoghq.com/rum/sessions/<sid3>
  recent_deploys:                                    # url required per entry
    - { name: "android-recorder@10.13.1", timestamp: "2026-05-10T18:22:00Z", url: "https://github.com/usertesting/mobile-android/pull/72" }
  suspected_cause: |
    PxCameraRecorder.kt:147 was changed in commit a47f5d4 to call
    _start before checking the MediaRecorder state machine — looks like
    a race with the screen-recorder unbinding when the activity is
    backgrounded during study setup.
```

→ skill emits the handoff block (above). Crash Surveyor's Step 9 prints
it under the corresponding NEW row in the run summary block.

## Usage — Orchestrator (pipeline mode, future)

The Orchestrator reads a Pending Triage Queue row → reconstructs the
same input shape from the row's stored fields → calls this skill →
posts the handoff to Slack (or wherever the human is). The human still
files the actual ticket; the orchestrator updates the queue row's
Status when the human reports the new key back.

Same skill, same output, no Jira writes ever from the skill itself.

---

## Critical rules

- **NEVER call any Jira write tool from this skill.** The skill is text
  in / text out. If the caller wants a Jira created, the caller does it
  itself after the human has reviewed the handoff (or by the human
  pasting into the Create dialog).
- **NEVER fabricate input data.** If `stack_trace` is empty, emit a
  warning paragraph and stop — do not write "stack not captured" or
  similar speculation.
- **NEVER modify constants in this file at runtime.** Project-specific
  overrides come in via the `constants` parameter at call time. A
  different project forking this skill creates its own copy with its
  own defaults.
