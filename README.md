# AI Hub

A repo to keep useful scripts and tools for development work with AI Tooling.

## Sync Agents & Skills
You can sync specific agents and skills defined in this repo with the actual `~/.claude` directory. The actual claude directory remains untouched, only a symlink is created between files in this repo and the claude directory.

This keeps the .claude directory clean, and makes sure skills and agents are defined (and git versioned) in this repo.

1. Copy `config.example.json` to `config.json` (gitignored) and add the names you want to sync:

   ```json
   {
       "agents": ["python-test-writer"],
       "skills": ["test-python"]
   }
   ```

2. Run the script (requires `jq`):

   ```bash
   bash sync.sh
   ```

   This removes every symlink in `~/.claude/agents/` and `~/.claude/skills/` pointing into this repo, then relinks everything in `config.json`. Real files and dirs at a target path are skipped.
