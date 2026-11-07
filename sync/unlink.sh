#!/usr/bin/env bash
# Remove symlinks in ~/.claude/ for agents and skills listed in links.json
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG="$SCRIPT_DIR/links.json"
CLAUDE_DIR="$HOME/.claude"

command -v jq >/dev/null || { echo "error: jq is required" >&2; exit 1; }
[[ -f "$CONFIG" ]] || { echo "error: $CONFIG not found" >&2; exit 1; }

# unlink_one <expected source> <target>
unlink_one() {
  local src="$1" dest="$2"

  if [[ ! -L "$dest" ]]; then
    if [[ -e "$dest" ]]; then
      echo "skip:    $dest is not a symlink" >&2
    else
      echo "skip:    $dest does not exist" >&2
    fi
    return
  fi

  # Only remove links that point back into this repo
  if [[ "$(readlink "$dest")" != "$src" ]]; then
    echo "skip:    $dest points to $(readlink "$dest"), not $src" >&2
    return
  fi

  rm "$dest"
  echo "removed: $dest"
}

while IFS= read -r agent; do
  unlink_one "$REPO_DIR/agents/$agent.md" "$CLAUDE_DIR/agents/$agent.md"
done < <(jq -r '.agents[]? // empty' "$CONFIG")

while IFS= read -r skill; do
  unlink_one "$REPO_DIR/skills/$skill" "$CLAUDE_DIR/skills/$skill"
done < <(jq -r '.skills[]? // empty' "$CONFIG")
