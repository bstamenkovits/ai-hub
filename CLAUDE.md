# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A version-controlled home for personal Claude Code **agents** and **skills**. There is no build, lint, or test step. The "code" is Markdown prompt files plus one shell script that symlinks them into `~/.claude`.

## Layout and conventions

- `agents/<name>.md`: one file per subagent. YAML frontmatter (`name`, `description`, `tools`), then the system prompt. `name` must match the filename.
- `skills/<name>/SKILL.md`: one directory per skill. Frontmatter (`name`, `description`, optional `allowed-tools`, `argument-hint`), then instructions. Longer reference material goes in `skills/<name>/references/*.md` and is linked from `SKILL.md` with relative paths, so it loads only when needed.
- The `description` field drives auto-triggering, so it lists explicit trigger phrases (e.g. `/ask`, "walk me through").

Skills and agents reference each other by name, so syncing one may require syncing its dependencies too:
- `jira-refine` uses the `repo-investigator` agent and the `grilling` skill.
- `repo-investigator` can spawn copies of itself (`Agent(repo-investigator)` in its tools) to fan out.
- `python-test-writer` (agent) and `test-python` (skill) cover the same pytest conventions.

## Syncing to ~/.claude

```bash
bash sync.sh                         # link every agent and skill in the repo

cp config.example.json config.json   # gitignored; list the agent/skill names to link
bash sync.sh --config                # link only what config.json lists (requires jq)
bash sync.sh --config other.json     # or use a different list
```

`sync.sh` first removes **every** symlink in `~/.claude/agents/` and `~/.claude/skills/` that points into this repo, then relinks either everything (every `agents/*.md` and every `skills/*/` containing a `SKILL.md`) or only what the config lists. Agents link as files (`agents/<name>.md`), skills link as whole directories (`skills/<name>`). It never overwrites a real file or directory at the target. Since these are symlinks, edits to files here take effect in Claude Code right away without re-running the script. Re-run it only after adding, removing, or renaming entries.
