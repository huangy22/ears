#!/usr/bin/env bash
# EARS Installer — Experience And Reasoning System v7
#
# Install:
#   git clone https://github.com/tianhanz/ears.git && cd ears && bash install.sh
#
# What it installs:
#   1. ears-trace hook      → ~/.local/bin/ears-trace
#   2. ears-state helper    → ~/.local/bin/ears-state
#   3. 8 Claude Code skills → ~/.claude/skills/{checkpoint,resume,reflect,...}
#   4. Hook config          → ~/.claude/settings.json (PostToolUse)
#   5. Session Protocol     → ~/.claude/CLAUDE.md (appended if not present)
#
# Idempotent: safe to run multiple times. Does not overwrite existing
# customizations in settings.json or CLAUDE.md.

set -euo pipefail

EARS_VERSION="7.0.0"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd 2>/dev/null || echo ".")"

# Colors (disable if not a terminal)
if [ -t 1 ]; then
  GREEN='\033[0;32m'; DIM='\033[0;90m'; BOLD='\033[1m'; NC='\033[0m'
  RED='\033[0;31m'
else
  GREEN=''; DIM=''; BOLD=''; NC=''; RED=''
fi

info()  { echo -e "${GREEN}[EARS]${NC} $*"; }
dim()   { echo -e "${DIM}  $*${NC}"; }
err()   { echo -e "${RED}[EARS] ERROR:${NC} $*" >&2; }

# -------------------------------------------------------------------
# Step 0: Detect environment
# -------------------------------------------------------------------
info "EARS v${EARS_VERSION} installer"

if ! command -v claude &>/dev/null && [ ! -d "$HOME/.claude" ]; then
  err "Claude Code not detected (~/.claude/ does not exist)."
  err "Install Claude Code first: https://docs.anthropic.com/en/docs/claude-code"
  exit 1
fi

# Verify repo structure
if [ ! -f "$REPO_DIR/hooks/ears-trace" ]; then
  err "Cannot find hooks/ears-trace in $REPO_DIR"
  err "Run this script from the ears repo root: cd ears && bash install.sh"
  exit 1
fi

mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.claude/skills"

# -------------------------------------------------------------------
# Step 1: Install hooks
# -------------------------------------------------------------------
info "Installing hooks..."

cp "$REPO_DIR/hooks/ears-trace" "$HOME/.local/bin/ears-trace"
cp "$REPO_DIR/hooks/ears-state" "$HOME/.local/bin/ears-state"
chmod +x "$HOME/.local/bin/ears-trace" "$HOME/.local/bin/ears-state"
dim "ears-trace → ~/.local/bin/ears-trace"
dim "ears-state → ~/.local/bin/ears-state"

# -------------------------------------------------------------------
# Step 2: Install skills
# -------------------------------------------------------------------
SKILLS="checkpoint resume reflect distill orchestrate sync-and-plan wrap-up brainstorm"
info "Installing skills..."

for skill in $SKILLS; do
  target="$HOME/.claude/skills/$skill"
  mkdir -p "$target"

  if [ -f "$REPO_DIR/skills/${skill}/SKILL.md" ]; then
    cp "$REPO_DIR/skills/${skill}/SKILL.md" "${target}/SKILL.md"
  else
    err "Cannot find skill: $skill"
    continue
  fi
  dim "$skill → ~/.claude/skills/$skill/"
done

# -------------------------------------------------------------------
# Step 3: Configure PostToolUse hook in settings.json
# -------------------------------------------------------------------
info "Configuring PostToolUse hook..."

SETTINGS="$HOME/.claude/settings.json"
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

# Check if ears-trace hook already configured
if python3 -c "
import json, sys
with open('$SETTINGS') as f:
    d = json.load(f)
hooks = d.get('hooks', {}).get('PostToolUse', [])
for h in hooks:
    for hh in h.get('hooks', []):
        if 'ears-trace' in hh.get('command', ''):
            sys.exit(0)
sys.exit(1)
" 2>/dev/null; then
  dim "Hook already configured (skipped)"
else
  python3 -c "
import json
with open('$SETTINGS') as f:
    d = json.load(f)
hooks = d.setdefault('hooks', {})
ptu = hooks.setdefault('PostToolUse', [])
ptu.append({
    'matcher': 'Write|Edit|Bash',
    'hooks': [{'type': 'command', 'command': '~/.local/bin/ears-trace'}]
})
with open('$SETTINGS', 'w') as f:
    json.dump(d, f, indent=2)
"
  dim "Added PostToolUse hook to ~/.claude/settings.json"
fi

# -------------------------------------------------------------------
# Step 4: Append Session Protocol to CLAUDE.md (if not present)
# -------------------------------------------------------------------
info "Checking ~/.claude/CLAUDE.md..."

CLAUDE_MD="$HOME/.claude/CLAUDE.md"
if [ ! -f "$CLAUDE_MD" ]; then
  touch "$CLAUDE_MD"
fi

if grep -q "EARS.*Experience And Reasoning System" "$CLAUDE_MD" 2>/dev/null; then
  dim "EARS protocol already in CLAUDE.md (skipped)"
else
  if [ -f "$REPO_DIR/protocol/CLAUDE.md.append" ]; then
    cat "$REPO_DIR/protocol/CLAUDE.md.append" >> "$CLAUDE_MD"
  else
    cat >> "$CLAUDE_MD" << 'PROTOCOL'

## EARS — Experience And Reasoning System

A PostToolUse hook (`~/.local/bin/ears-trace`) monitors your work and sends
`[EARS]` prompts at six transition points: Session Start, Error→Fix, Stuck,
Commit Digest, Session End (with memory nudge), and Activity Pulse.

When you receive an `[EARS]` prompt, respond to it before continuing.
Append to the nearest `trace.md`. Always include `<!-- concepts: ... -->` tags.

### Session End Protocol

Before ending a session, run `/reflect` to extract lessons. If `/reflect`
cannot run, write critical findings to `.claude/memory/` directly.

### Checkpoint / Resume

Use `/checkpoint` before ending long sessions. Use `/resume` to recover.

For full documentation: https://github.com/tianhanz/ears
PROTOCOL
  fi
  dim "Appended EARS protocol to ~/.claude/CLAUDE.md"
fi

# -------------------------------------------------------------------
# Step 5: Summary
# -------------------------------------------------------------------
echo ""
info "Installation complete!"
echo ""
echo "  Components installed:"
echo "    hooks      ~/.local/bin/ears-trace (v7)"
echo "    skills     ~/.claude/skills/{checkpoint,resume,reflect,distill,"
echo "               orchestrate,sync-and-plan,wrap-up,brainstorm}"
echo "    config     ~/.claude/settings.json (PostToolUse hook)"
echo "    protocol   ~/.claude/CLAUDE.md (Session Protocol)"
echo ""
echo "  Available commands in Claude Code:"
echo "    /checkpoint    Save session progress"
echo "    /resume        Restore from checkpoint"
echo "    /reflect       Extract lessons to memory"
echo "    /distill       Distill patterns from traces"
echo "    /orchestrate   Multi-agent coordination"
echo "    /sync-and-plan Orient across worktrees"
echo "    /wrap-up       Finalize and merge branch"
echo "    /brainstorm    Multi-model review"
echo ""
echo "  EARS hooks fire automatically — no manual setup needed."
echo "  Start a new Claude Code session to activate."
echo ""
