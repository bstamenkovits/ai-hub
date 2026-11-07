#!/usr/bin/env bash
# Symlink agents and skills listed in links.json into ~/.claude/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG="$SCRIPT_DIR/links.json"
CLAUDE_DIR="$HOME/.claude"

command -v jq >/dev/null || { echo "error: jq is required" >&2; exit 1; }
[[ -f "$CONFIG" ]] || { echo "error: $CONFIG not found" >&2; exit 1; }

# link <source> <target>
link() {
  local src="$1" dest="$2"

  if [[ ! -e "$src" ]]; then
    echo "skip:    $src does not exist" >&2
    return
  fi

  # Never clobber a real file/directory; only replace existing symlinks
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    echo "skip:    $dest exists and is not a symlink" >&2
    return
  fi

  ln -sfn "$src" "$dest"
  echo "linked:  $dest -> $src"
}

mkdir -p "$CLAUDE_DIR/agents" "$CLAUDE_DIR/skills"

while IFS= read -r agent; do
  link "$REPO_DIR/agents/$agent.md" "$CLAUDE_DIR/agents/$agent.md"
done < <(jq -r '.agents[]? // empty' "$CONFIG")

while IFS= read -r skill; do
  link "$REPO_DIR/skills/$skill" "$CLAUDE_DIR/skills/$skill"
done < <(jq -r '.skills[]? // empty' "$CONFIG")
