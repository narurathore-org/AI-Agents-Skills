# android-context

Loads the persistent architecture knowledge base for the current Kotlin/Android
project. If the knowledge base does not exist or is incomplete, creates it first
by invoking `@android-architect` in INDEX mode, then loads it.

Use this skill at the start of any task that requires understanding the project's
architecture, modules, components, or extensions.

`CONTEXT_ROOT = /Users/nsingh/Documents/local-claude-agents/projects/`

---

## Steps

### 1. Derive project slug

- Use the current working directory's folder name, lowercased and hyphenated.
- Cross-check against `git remote get-url origin` — if the remote repo name
  differs from the folder name, prefer the remote repo name.
- If ambiguous, list existing slugs under `CONTEXT_ROOT` and ask the user to
  confirm or provide one.

### 2. Check if the knowledge base exists

Check whether `CONTEXT_ROOT/<slug>/` exists and contains all required files:
`architecture.md`, `modules.md`, `components.md`, `extensions.md`, `index.md`.

**If complete → go to Step 3.**

**If missing or incomplete:**
- Tell the user: "No architecture context found for `<slug>`. Indexing project
  first via @android-architect…"
- Dispatch `@android-architect`: *"Index the project at `<project-root>` with
  slug `<slug>`."*
- Wait for `@android-architect` to complete before continuing.
- Then proceed to Step 3.

### 3. Load the knowledge base

Read all files under `CONTEXT_ROOT/<slug>/`:
- `index.md`
- `architecture.md`
- `modules.md`
- `components.md`
- `extensions.md`
- `spec-config.md` (if present)

### 4. Staleness check

From `index.md`, read the `last-indexed commit`. Run:
```
git -C <project-root> rev-parse HEAD
```
If the commits differ, surface a warning:
> "Architecture context was indexed at `<old-commit>` but HEAD is now
> `<new-commit>`. Context may be stale — consider running
> `@android-architect` to re-index before proceeding."

Do not block on this — let the caller decide whether to re-index.

### 5. Return context summary

Output a short summary so the caller knows what was loaded:

```
## Project context loaded: <slug>
- Root: <project-root>
- Last indexed: <commit> (<date>)
- Modules: <count>
- Components: <count>
- Extensions: <count>
- SDD: enabled | disabled
```

The full file contents are now in context and available for the rest of the workflow.
