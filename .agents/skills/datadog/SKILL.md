---
name: datadog
description: >
  Query Datadog RUM data for the Android Recorder app. Covers crashes
  (use the CRASHES section, @error.is_crash:true), non-crash errors (use the
  ERRORS section, @error.is_crash:false), sessions, user behavior, screens,
  actions, network requests, and raw event search.
---

# Datadog — Android Recorder RUM Query Skill

## Access

- **Use the connected Datadog MCP tools** — do NOT use curl with API keys.
- Primary tools: `aggregate_rum_events` (counts, grouping, timeseries) and `search_datadog_rum_events` (raw events)
- **App name filter:** `@application.name:"Android Recorder"`
- **Dashboard:** https://app.datadoghq.com/dashboard/2dm-pbt-nqg/android-dashboard-v2

---

## RUM Event Types

Use `@type:TYPE` in the query filter. Available types:

| Type | Description | Use For |
|------|-------------|---------|
| `session` | User sessions | Active users, session counts, version adoption, retention |
| `view` | Screen/page views | Screen usage, navigation flows, load times |
| `action` | User interactions (taps, clicks, scrolls, swipes) | Feature usage, button taps, user behavior patterns |
| `error` | All errors | Use `@error.is_crash:true` for crashes only, `@error.is_crash:false` for non-crash errors |
| `resource` | Network requests | API latency, failure rates, slow endpoints |
| `long_task` | Long tasks (>100ms) | UI jank, ANRs, performance bottlenecks |

---

## Common Facets for group_by / filtering

| Facet | Description |
|-------|-------------|
| `version` | App version (e.g., 10.12) |
| `@os.version` | Android OS version |
| `@device.model` | Device model |
| `@geo.country` | User country |
| `@usr.id` | User ID |
| `@session.id` | Session ID |
| `@view.name` | Screen/view name |
| `@action.type` | Action type (tap, scroll, swipe, back, click) |
| `@action.name` | Action target name |
| `@error.message` | Error/crash message |
| `@error.is_crash` | `true` = crash, `false` = non-crash error |
| `@error.source` | Error source (source, network, logger, agent) |
| `@resource.url` | Network request URL |
| `@resource.status_code` | HTTP status code |
| `@resource.method` | HTTP method |
| `@context.*` | Any custom attributes sent via RUM |

---

## Query Templates

All queries use `aggregate_rum_events` or `search_datadog_rum_events`. Base filter: `@os.name:Android @application.name:"Android Recorder"`

**Default time window:** `from: "now-30d"`, `to: "now"` — always include this. The MCP defaults to `now-15m` if omitted, which returns misleading short-range data.

---

### CRASHES
> Use these when you need **true app crashes only** (`@error.is_crash:true`). Excludes non-crash errors, logger errors, network errors, and ANRs.

#### Search for a specific crash by keyword
`aggregate_rum_events`:
- query: `@type:error @error.is_crash:true @os.name:Android @application.name:"Android Recorder" @error.message:*KEYWORD*`
- computes: `[{"field": "*", "aggregation": "COUNT", "output": "count", "sort": "desc"}]`
- group_by: `{"fields": ["version"], "limit": 15}`
- from: `"now-30d"`, to: `"now"`

#### Top crashes ranked by count
`aggregate_rum_events`:
- query: `@type:error @error.is_crash:true @os.name:Android @application.name:"Android Recorder"`
- computes: `[{"field": "*", "aggregation": "COUNT", "output": "count", "sort": "desc"}]`
- group_by: `{"fields": ["@error.message"], "limit": 25}`
- from: `"now-30d"`, to: `"now"`

#### Crashes by Android OS version
`aggregate_rum_events`:
- query: `@type:error @error.is_crash:true @os.name:Android @application.name:"Android Recorder"`
- computes: `[{"field": "*", "aggregation": "COUNT", "output": "count", "sort": "desc"}]`
- group_by: `{"fields": ["@os.version"], "limit": 10}`
- from: `"now-30d"`, to: `"now"`

#### Crashes by app version
`aggregate_rum_events`:
- query: `@type:error @error.is_crash:true @os.name:Android @application.name:"Android Recorder"`
- computes: `[{"field": "*", "aggregation": "COUNT", "output": "count", "sort": "desc"}]`
- group_by: `{"fields": ["version"], "limit": 10}`
- from: `"now-30d"`, to: `"now"`

#### Crashes by device model
`aggregate_rum_events`:
- query: `@type:error @error.is_crash:true @os.name:Android @application.name:"Android Recorder"`
- computes: `[{"field": "*", "aggregation": "COUNT", "output": "count", "sort": "desc"}]`
- group_by: `{"fields": ["@device.model"], "limit": 15}`
- from: `"now-30d"`, to: `"now"`

#### Raw crash event search
`search_datadog_rum_events`:
- query: `@type:error @error.is_crash:true @os.name:Android @application.name:"Android Recorder" @error.message:*KEYWORD*`
- from: `"now-30d"`, to: `"now"`
- detailed_output: `true`

---

### ERRORS (non-crash)
> Use these when you need **non-crash errors** (`@error.is_crash:false`): logger errors, handled exceptions, network-layer errors reported as RUM errors, etc.

#### Top non-crash errors ranked by count
`aggregate_rum_events`:
- query: `@type:error @error.is_crash:false @os.name:Android @application.name:"Android Recorder"`
- computes: `[{"field": "*", "aggregation": "COUNT", "output": "count", "sort": "desc"}]`
- group_by: `{"fields": ["@error.message"], "limit": 25}`
- from: `"now-30d"`, to: `"now"`

#### Non-crash errors by source
`aggregate_rum_events`:
- query: `@type:error @error.is_crash:false @os.name:Android @application.name:"Android Recorder"`
- computes: `[{"field": "*", "aggregation": "COUNT", "output": "count", "sort": "desc"}]`
- group_by: `{"fields": ["@error.source"], "limit": 10}`
- from: `"now-30d"`, to: `"now"`

#### Search for a specific non-crash error by keyword
`aggregate_rum_events`:
- query: `@type:error @error.is_crash:false @os.name:Android @application.name:"Android Recorder" @error.message:*KEYWORD*`
- computes: `[{"field": "*", "aggregation": "COUNT", "output": "count", "sort": "desc"}]`
- group_by: `{"fields": ["version"], "limit": 15}`
- from: `"now-30d"`, to: `"now"`

#### Raw non-crash error event search
`search_datadog_rum_events`:
- query: `@type:error @error.is_crash:false @os.name:Android @application.name:"Android Recorder" @error.message:*KEYWORD*`
- from: `"now-30d"`, to: `"now"`
- detailed_output: `true`

---

### USER BEHAVIOR & SESSIONS

#### Active users (unique) by version
`aggregate_rum_events`:
- query: `@type:session @os.name:Android @application.name:"Android Recorder"`
- computes: `[{"field": "@usr.id", "aggregation": "CARDINALITY", "output": "unique_users", "sort": "desc"}]`
- group_by: `{"fields": ["version"], "limit": 15}`
- from: `"now-30d"`, to: `"now"`

#### Session count by version (version adoption)
`aggregate_rum_events`:
- query: `@type:session @os.name:Android @application.name:"Android Recorder"`
- computes: `[{"field": "*", "aggregation": "COUNT", "output": "sessions", "sort": "desc"}]`
- group_by: `{"fields": ["version"], "limit": 15}`
- from: `"now-30d"`, to: `"now"`

---

### USER ACTIONS

#### Most tapped/clicked actions
`aggregate_rum_events`:
- query: `@type:action @os.name:Android @application.name:"Android Recorder"`
- computes: `[{"field": "*", "aggregation": "COUNT", "output": "count", "sort": "desc"}]`
- group_by: `{"fields": ["@action.name"], "limit": 25}`
- from: `"now-30d"`, to: `"now"`

---

### VIEWS & SCREENS

#### Most visited screens
`aggregate_rum_events`:
- query: `@type:view @os.name:Android @application.name:"Android Recorder"`
- computes: `[{"field": "*", "aggregation": "COUNT", "output": "count", "sort": "desc"}]`
- group_by: `{"fields": ["@view.name"], "limit": 25}`
- from: `"now-30d"`, to: `"now"`

---

### NETWORK / RESOURCES

#### Failed network requests (4xx/5xx)
`aggregate_rum_events`:
- query: `@type:resource @os.name:Android @application.name:"Android Recorder" @resource.status_code:>=400`
- computes: `[{"field": "*", "aggregation": "COUNT", "output": "count", "sort": "desc"}]`
- group_by: `{"fields": ["@resource.url", "@resource.status_code"], "limit": 15}`
- from: `"now-30d"`, to: `"now"`

---

### RAW EVENT SEARCH

#### All events for a specific user
`search_datadog_rum_events`:
- query: `@os.name:Android @application.name:"Android Recorder" @usr.id:USER_ID`
- from: `"now-30d"`, to: `"now"`
- detailed_output: `true`

---

## Instructions

1. **Identify the query type** — crash, non-crash error, user behavior, feature usage, performance, network, or ad-hoc
2. **Pick the right section** — CRASHES for `@error.is_crash:true`, ERRORS for `@error.is_crash:false`
3. **Set the time window** — default 30 days unless specified
4. **Run the query** using the Datadog MCP tools (discover tool names via ToolSearch if needed)
5. **Parse & summarize** — present results in clear tables
6. **Provide actionable insight** — say what the data means, not just the numbers