#!/usr/bin/env bash
# Remove all ~/.claude/ symlinks pointing into this repo, then relink.
# Usage: sync.sh                    link every agent and skill
#        sync.sh --config [file]    link only what config.json (or file) lists
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$REPO_DIR/config.json"
CLAUDE_DIR="$HOME/.claude"
MODE=all

case "${1:-}" in
  "") ;;
  --config)
    MODE=config
    [[ -n "${2:-}" ]] && CONFIG="$2"
    ;;
  *)
    echo "usage: $0 [--config [file]]" >&2
    exit 1
    ;;
esac

if [[ $MODE == config ]]; then
  command -v jq >/dev/null || { echo "error: jq is required" >&2; exit 1; }
  [[ -f "$CONFIG" ]] || { echo "error: $CONFIG not found (copy config.example.json)" >&2; exit 1; }
fi

mkdir -p "$CLAUDE_DIR/agents" "$CLAUDE_DIR/skills"

# unlink_repo_links <kind>: remove symlinks in ~/.claude/<kind>/ pointing into this repo,
# including names no longer in config.json
unlink_repo_links() {
  local kind="$1" dest count=0
  for dest in "$CLAUDE_DIR/$kind"/*; do
    [[ -L "$dest" ]] || continue
    case "$(readlink "$dest")" in
      "$REPO_DIR/$kind"/*)
        rm "$dest"
        echo "removed: $dest"
        count=$((count + 1))
        ;;
    esac
  done
  (( count > 0 )) && echo
  return 0
}

unlink_repo_links agents
unlink_repo_links skills

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

# Print agent/skill names to link, from config.json or from the repo itself
list_agents() {
  if [[ $MODE == config ]]; then
    jq -r '.agents[]? // empty' "$CONFIG"
  else
    for f in "$REPO_DIR"/agents/*.md; do
      [[ -e "$f" ]] && basename "$f" .md
    done
  fi
}

list_skills() {
  if [[ $MODE == config ]]; then
    jq -r '.skills[]? // empty' "$CONFIG"
  else
    for f in "$REPO_DIR"/skills/*/SKILL.md; do
      [[ -e "$f" ]] && basename "$(dirname "$f")"
    done
  fi
}

agent_count=0
while IFS= read -r agent; do
  link "$REPO_DIR/agents/$agent.md" "$CLAUDE_DIR/agents/$agent.md"
  agent_count=$((agent_count + 1))
done < <(list_agents)
(( agent_count > 0 )) && echo

while IFS= read -r skill; do
  link "$REPO_DIR/skills/$skill" "$CLAUDE_DIR/skills/$skill"
done < <(list_skills)
