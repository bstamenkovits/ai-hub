# Linking agents and skills to `~/.claude`

Agents live in `agents/<name>.md` and skills in `skills/<name>/`. To make them available to Claude Code, symlink them into `~/.claude/`.

## Link

1. Add the names you want to sync to `sync/links.json`:

   ```json
   {
       "agents": ["python-test-writer"],
       "skills": ["test-python"]
   }
   ```

2. Run the script (requires `jq`):

   ```bash
   bash sync/link.sh
   ```

This creates:

- `~/.claude/agents/<name>.md` → `agents/<name>.md`
- `~/.claude/skills/<name>` → `skills/<name>/`

The script is safe to re-run. Existing symlinks are replaced, but real files or directories at the target path are skipped with a warning.

## Sync

To make `~/.claude/` match `sync/links.json` exactly:

```bash
bash sync/sync.sh
```

This removes every symlink in `~/.claude/agents/` and `~/.claude/skills/` that points into this repo, including ones for names you've since removed from `links.json`, then runs `link.sh` to recreate the links. Links and files that don't point into this repo are left alone.

## Unlink

To remove the symlinks for everything listed in `sync/links.json`:

```bash
bash sync/unlink.sh
```

This deletes only the links in `~/.claude/`, never the files in this repo. A target is skipped with a warning if it isn't a symlink or if it points somewhere other than this repo.

To unlink a single agent or skill, remove its symlink by hand:

```bash
rm ~/.claude/agents/<name>.md
rm ~/.claude/skills/<name>
```

Leave off the trailing slash on skill links: `rm ~/.claude/skills/<name>/` fails because it points at the directory instead of the link.

Then remove the name from `sync/links.json` so the next run of `link.sh` doesn't link it again.
