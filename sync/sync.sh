#!/usr/bin/env bash
# Remove all ~/.claude/ symlinks pointing into this repo, then relink from links.json
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$HOME/.claude"

# Unlink everything from this repo, including names no longer in links.json
for dest in "$CLAUDE_DIR"/agents/* "$CLAUDE_DIR"/skills/*; do
  [[ -L "$dest" ]] || continue
  case "$(readlink "$dest")" in
    "$REPO_DIR"/agents/* | "$REPO_DIR"/skills/*)
      rm "$dest"
      echo "removed: $dest"
      ;;
  esac
done

bash "$SCRIPT_DIR/link.sh"
