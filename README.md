# AI-Agents-Skills

Central git storage for all my AI agents and skills. Clone once, sync everywhere via a single script.

Currently Claude Code only. Codex support to be added later.

## Structure

```
.claude/agents/              # Claude agent wrappers — synced to ~/.claude/agents/
  android-dev.md
  android-qa-insights.md
  android-qa-test-creator.md
  crash-orchestrator.md
  kotlin-architect-developer.md

.agents/                     # Shared prompts and skills (used by Claude + Codex)
  android-dev/PROMPT.md
  crash-orchestrator/PROMPT.md
  skills/
    confluence/SKILL.md
    datadog/SKILL.md
    github-pr/SKILL.md
    jira/SKILL.md
    jira-bug-ticket/SKILL.md

scripts/
  setup-agents.sh            # Setup script
```

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/narurathore/AI-Agents-Skills.git ~/Documents/AI-Agents-Skills
```

### 2. Sync Claude agents globally

Copies all Claude agent wrappers to `~/.claude/agents/` so they are available in every project:

```bash
./scripts/setup-agents.sh
```

### 3. Set up shared prompts and skills in a project

Copies `.agents/` (prompts + skills) into a target project so Claude agents can reference them:

```bash
# into current directory
./scripts/setup-agents.sh --project

# into a specific project
./scripts/setup-agents.sh --project ~/path/to/repo
```

## Keeping agents up to date

When agents change in this repo, re-run the script to sync:

```bash
cd ~/Documents/AI-Agents-Skills && git pull && ./scripts/setup-agents.sh
```

## Adding new agents

1. Add the Claude wrapper under `.claude/agents/<name>.md`
2. If it references a shared prompt, add it under `.agents/<name>/PROMPT.md`
3. If it uses skills, add them under `.agents/skills/<name>/SKILL.md`
4. Commit, push, and run `setup-agents.sh` to sync globally
