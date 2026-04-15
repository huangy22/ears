# EARS — Experience And Reasoning System

**Automatic knowledge capture for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).**

EARS monitors your development sessions and captures moments of insight — errors fixed, decisions made, patterns discovered — then distills them into reusable knowledge that persists across sessions.

## Install

```bash
git clone https://github.com/tianhanz/ears.git
cd ears
bash install.sh
```

That's it. Start a new Claude Code session and EARS activates automatically.

## What it does

EARS is a PostToolUse hook that fires at six meaningful transition points during development:

| Trigger | When | Why |
|---------|------|-----|
| **Session Start** | First tool call | Capture task context and intent |
| **Error→Fix** | Command fails, then you fix it | Most valuable learning moment — fires *after* the fix |
| **Stuck** | Same file edited 4+ times | Thrashing signal — prompts reflection on approach |
| **Commit Digest** | Every `git commit` | Post-commit reflection with diff summary |
| **Session End** | `git merge` or wrap-up | Nudges writing lessons to persistent memory |
| **Activity Pulse** | 30+ min active without commit | Captures in-flight decisions before forgotten |

All triggers are rate-limited (at most once per 10 minutes, except Commit Digest). The hook is state-machine based — it tracks pending errors in `/tmp/ears_*/` and only fires on meaningful transitions.

## Skills

EARS ships with 8 slash commands for Claude Code:

| Command | Purpose |
|---------|---------|
| `/checkpoint` | Save session progress to structured YAML before context runs out |
| `/resume` | Restore state from a checkpoint in a new session |
| `/reflect` | Extract lessons learned into persistent `.claude/memory/` files |
| `/distill` | Distill recurring patterns from traces into reusable knowledge |
| `/orchestrate` | Coordinate multiple Claude Code sessions as parallel workers |
| `/sync-and-plan` | Sync across git worktrees and plan next steps |
| `/wrap-up` | Finalize branch: update docs, commit, merge to main |
| `/brainstorm` | Multi-model review using GPT, Gemini, Qwen, and Kimi in parallel |

## Architecture

```
Session work → [EARS hook] → trace.md (raw, with concept tags)
                                ↓
              trace.md → [/distill] → knowledge entries (structured)
                                        ↓
                    strong patterns → [human review] → CLAUDE.md (principles)
```

Three components, each more refined than the last:

1. **Moment Capture** (automatic) — the PostToolUse hook writes to `trace.md`
2. **Pattern Distillation** (on-demand) — `/distill` extracts recurring patterns
3. **Principle Surfacing** (human-gated) — strong patterns are candidates for CLAUDE.md

## What gets installed

```
~/.local/bin/
  ears-trace              ← PostToolUse hook (v7, state-machine)
  ears-state              ← State management helper

~/.claude/skills/
  checkpoint/SKILL.md     ← /checkpoint
  resume/SKILL.md         ← /resume
  reflect/SKILL.md        ← /reflect
  distill/SKILL.md        ← /distill
  orchestrate/SKILL.md    ← /orchestrate
  sync-and-plan/SKILL.md  ← /sync-and-plan
  wrap-up/SKILL.md        ← /wrap-up
  brainstorm/SKILL.md     ← /brainstorm

~/.claude/settings.json   ← PostToolUse hook config (non-destructive merge)
~/.claude/CLAUDE.md       ← Session Protocol appendix (appended if not present)
```

## Memory system

EARS encourages writing distilled knowledge to `.claude/memory/` — structured YAML files that persist across sessions:

- **`pitfalls.yaml`** — things that broke and how to avoid them (expires in 3 months)
- **`patterns.yaml`** — confirmed multi-step workflows
- **`decisions.yaml`** — architectural choices with rationale (expires in 6 months)

The Session End trigger explicitly nudges writing to memory, so critical findings survive even if `/reflect` never runs.

## Trace files

When EARS fires, the agent appends an entry to the nearest `trace.md`:

```markdown
### EARS — Error→Fix (2026-04-15 14:30)
<!-- concepts: deployment, rsync, dependency-management -->
rsync --delete nuked the remote venv. Missing `requests` package broke SSO login.
Root cause: `requests` was a transitive dep never in requirements.txt.
Fix: added to requirements.txt, installed on remote.
```

Each entry includes:
- Trigger type and timestamp
- `<!-- concepts: ... -->` tag for knowledge graph ingestion
- Brief description of what happened and why it matters

## Verify installation

```bash
# Check hook
ls -la ~/.local/bin/ears-trace

# Check skills
ls ~/.claude/skills/{checkpoint,resume,reflect,distill,orchestrate,sync-and-plan,wrap-up,brainstorm}/SKILL.md

# Check hook config
grep ears-trace ~/.claude/settings.json
```

## Uninstall

```bash
# Remove hooks
rm ~/.local/bin/ears-trace ~/.local/bin/ears-state

# Remove skills
rm -rf ~/.claude/skills/{checkpoint,resume,reflect,distill,orchestrate,sync-and-plan,wrap-up,brainstorm}

# Remove hook config from settings.json (manual: delete the PostToolUse entry)
# Remove protocol from CLAUDE.md (manual: delete the EARS section)
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed (`~/.claude/` directory exists)
- Python 3 (for settings.json manipulation during install)
- Bash

## License

MIT

## Related

- [Playground for Agentic Science](https://github.com/tianhanz/playground-for-agentic-science) — the platform where EARS was born, featuring collaborative paper reproduction, skill marketplace, and knowledge graph
