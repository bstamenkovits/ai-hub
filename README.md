# AI Hub

A repo to keep useful scripts and tools for development work with AI Tooling.

## Sync Agents & Skills
You can sync all or some of the agents and skills defined in this repo with the actual `~/.claude` directory. The actual claude directory remains untouched, only a symlink is created between files in this repo and the claude directory.

This keeps the .claude directory clean, and makes sure skills and agents are defined (and git versioned) in this repo.

To sync **every** agent and skill in the repo:

```bash
bash sync.sh
```

To sync only a **subset**:

1. Copy `config.example.json` to `config.json` (gitignored) and add the names you want to sync:

   ```json
   {
       "agents": ["python-test-writer"],
       "skills": ["test-python"]
   }
   ```

2. Run the script with `--config` (requires `jq`):

   ```bash
   bash sync.sh --config               # uses config.json
   bash sync.sh --config other.json    # or any other list
   ```

Either way, the script first removes every symlink in `~/.claude/agents/` and `~/.claude/skills/` pointing into this repo, then relinks: everything (every `agents/*.md` and every `skills/*/` with a `SKILL.md`), or only what the config lists. Switching modes therefore drops links the new mode doesn't include. Real files and dirs at a target path are skipped.

Since these are symlinks, edits in this repo take effect immediately. Re-run the script only after adding, removing, or renaming agents or skills.
