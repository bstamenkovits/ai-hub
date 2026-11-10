#!/usr/bin/env bash
# Remove all ~/.claude/ symlinks pointing into this repo, then relink from config.json
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$REPO_DIR/config.json"
CLAUDE_DIR="$HOME/.claude"

command -v jq >/dev/null || { echo "error: jq is required" >&2; exit 1; }
[[ -f "$CONFIG" ]] || { echo "error: $CONFIG not found (copy config.example.json)" >&2; exit 1; }

mkdir -p "$CLAUDE_DIR/agents" "$CLAUDE_DIR/skills"

# Unlink everything from this repo, including names no longer in config.json
for dest in "$CLAUDE_DIR"/agents/* "$CLAUDE_DIR"/skills/*; do
  [[ -L "$dest" ]] || continue
  case "$(readlink "$dest")" in
    "$REPO_DIR"/agents/* | "$REPO_DIR"/skills/*)
      rm "$dest"
      echo "removed: $dest"
      ;;
  esac
done

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

while IFS= read -r agent; do
  link "$REPO_DIR/agents/$agent.md" "$CLAUDE_DIR/agents/$agent.md"
done < <(jq -r '.agents[]? // empty' "$CONFIG")

while IFS= read -r skill; do
  link "$REPO_DIR/skills/$skill" "$CLAUDE_DIR/skills/$skill"
done < <(jq -r '.skills[]? // empty' "$CONFIG")
