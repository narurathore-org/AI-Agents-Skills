---
name: confluence
description: >
  Read Confluence pages via the Atlassian MCP. Covers page ID references
  for the mobile regression checklists, content format choice, and
  recovery steps when a page is too large and the MCP dumps it to a
  local file.
---

# Confluence — UserTesting Mobile Pages Skill

## Access

- **Use the connected Atlassian MCP tools** — do NOT use the Confluence REST API directly.
- Primary tools: `getConfluencePage` (read), `getPagesInConfluenceSpace`, `searchConfluenceUsingCql`, `updateConfluencePage` (write).
- **cloudId:** `user-testing.atlassian.net`
- **Tool names are dynamic** — resolve with `ToolSearch query: "select:mcp__atlassian__getConfluencePage"` before calling.

---

## Common Parameters

| Parameter | Value |
| --- | --- |
| `cloudId` | `"user-testing.atlassian.net"` |
| `pageId` | Numeric page ID (preferred) or tiny-link ID (the encoded part after `/wiki/x/`, e.g. `Fc1bBw`). |
| `contentFormat` | `"markdown"` for reading and summarizing. `"adf"` only when you need full fidelity (panels, mentions, Smart Links) or are preparing to write the page back. |
| `contentType` | `"page"` (default) or `"blog"`. |

**Default choice:** pass `contentFormat: "markdown"` for all read operations unless you explicitly need ADF.

---

## Known Pages — Mobile QA

### Android regression checklists (Confluence space `QE1` — Quality Engineering)

| Page | ID | What's in it |
| --- | --- | --- |
| Mobile Test Automation — Current State & Planning | `4829118517` | Android & iOS regression checklists (Full Mobile Flow, TOL/NTOL/Survey/Classic UT), automation pipelines, short-term & long-term plans. |
| Mobile Testing — Release Checks | `4490428719` | Release-level manual checks (login, test selection, upload, history, decline flow, logout) plus UTZ & Classic UT creation steps. |
| UserTesting Mobile Test Strategy & Process (v1.0) | `4482695243` | Testing levels (story/epic/multi-epic), RACI matrix, automation ownership, hotfix process. |

### Supporting pages (referenced by the three above)

| Page | ID | What's in it |
| --- | --- | --- |
| Mobile Testing — Manual Regression Checks | `4387799110` | Detailed per-scenario question-type checklists (deep-linked from the release checks page). |
| How to test UZ Live app | `3416391708` | UZ Live-specific smoke test guide. |

Fetch these only when the primary checklist references them and you need the deeper detail.

---

## Large Page Recovery

Confluence page bodies can exceed the MCP response token limit — especially pages with embedded tables, diagrams, or heavy formatting. When that happens, the MCP saves the full response to a **local file path that varies per user** (`~/.claude/projects/<project-dir>/<uuid>/tool-results/<tool>-<timestamp>.txt`). The exact path is in the error message — never hardcode it.

Recovery steps:

1. **Retry with `contentFormat: "markdown"`.** Markdown is typically 30–60% smaller than ADF. If the failing call used ADF, switching to markdown is usually enough.
2. **Narrow the fetch** — if you only need a section, use `searchConfluenceUsingCql` to locate it, or link to a child page (use `getConfluencePageDescendants`) which may have the subset you need.
3. **Fall back to the saved file** — read it with `jq` or delegate to a subagent:
   ```
   jq 'type, (.content.nodes | length), (.content.nodes[0] | keys)' "<path-from-error>"
   jq -r '.content.nodes[0].body' "<path-from-error>" | head -200
   ```
   When delegating to a subagent via the `Agent` tool, be explicit about what it must return — a vague "summarize this" loses detail on large pages.

---

## Instructions

1. **Pick the page by ID** from the table above, or discover via `searchConfluenceUsingCql` / `getPagesInConfluenceSpace`.
2. **Default to `contentFormat: "markdown"`** for all reads.
3. **If the response overflows**, retry with markdown (if not already), then narrow the fetch, then read the saved file as a last resort.
4. **Write operations** (`updateConfluencePage`) require ADF — fetch the current page in ADF before composing the edit.