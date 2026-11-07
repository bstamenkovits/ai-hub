# AI Hub

A repo to keep useful scripts and tools for development work with AI Tooling.

## Sync Agents & Skills
You can sync specific agents and skills defined in this repo with the actual `~/.claude` directory. The actual claude directory remains untouched, only a symlink is created between files in this repo and the claude directory.

This keeps the .claude directory clean, and makes sure skills and agents are defined (and git versioned) in this repo. For more detailed info see [sync/how-to-sync.md](sync/how-to-sync.md)

1. Add the names you want to sync to `sync/links.json`:

   ```json
   {
       "agents": ["python-test-writer"],
       "skills": ["test-python"]
   }
   ```

2. Run the script (requires `jq`):

   ```bash
   bash sync/sync.sh
   ```
