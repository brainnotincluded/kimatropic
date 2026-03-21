# Kimatropic Setup Guide for AI Agents

This file tells you — an AI coding agent (Claude Code, Cursor, Cline, etc.) — how to install and configure the kimatropic plugin for a user. Follow these instructions exactly.

## Prerequisites Check

Before starting, verify these dependencies are installed. Run each command and check the output:

```bash
# Required
claude --version          # Claude Code CLI (any version)
kimi --version            # Kimi CLI >= 1.19 (install: pip install kimi-cli)
git --version             # Git (any version)
jq --version              # jq (install: brew install jq / apt install jq)

# Required on macOS (GNU coreutils)
timeout --version 2>/dev/null || gtimeout --version   # brew install coreutils
tac --version 2>/dev/null || gtac --version           # included in coreutils

# Optional (for desktop control / visual features)
python3 -c "import pyautogui; print('pyautogui OK')"  # pip install pyautogui
ffmpeg -version                                        # brew install ffmpeg / apt install ffmpeg
```

If `kimi` is not installed:
```bash
pip install kimi-cli
kimi login    # Follow the prompts to authenticate
```

If `kimi` version is below 1.19:
```bash
pip install --upgrade kimi-cli
```

## Installation

### Step 1: Set up local plugins directory

Check if a local plugins marketplace already exists:

```bash
ls ~/claude-local-plugins/.claude-plugin/marketplace.json 2>/dev/null
```

**If it exists:** Skip to Step 2.

**If it does NOT exist:** Create the marketplace structure:

```bash
mkdir -p ~/claude-local-plugins/.claude-plugin
mkdir -p ~/claude-local-plugins/plugins

cat > ~/claude-local-plugins/.claude-plugin/marketplace.json << 'EOF'
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "local-plugins",
  "description": "Local plugin collection",
  "owner": {
    "name": "User"
  },
  "plugins": []
}
EOF
```

Then register the marketplace in Claude Code settings. Read `~/.claude/settings.json` and ensure it contains:

```json
{
  "pluginMarketplaces": ["~/claude-local-plugins"]
}
```

If `pluginMarketplaces` doesn't exist, add it. If it exists with other marketplaces, append `"~/claude-local-plugins"` to the array.

### Step 2: Clone kimatropic

```bash
git clone https://github.com/brainnotincluded/kimatropic.git ~/claude-local-plugins/plugins/kimatropic
```

If the directory already exists (previous install):
```bash
cd ~/claude-local-plugins/plugins/kimatropic && git pull
```

### Step 3: Register in marketplace

Read `~/claude-local-plugins/.claude-plugin/marketplace.json` and add kimatropic to the `plugins` array if not already present:

```json
{
  "name": "kimatropic",
  "description": "Delegate tasks to Kimi K2.5 via subagents with lossy summary compression.",
  "version": "0.2.0",
  "author": { "name": "Daniil" },
  "source": "./plugins/kimatropic",
  "category": "development"
}
```

**Important:** Do NOT duplicate the entry. Check if `"name": "kimatropic"` already exists in the array before adding.

### Step 4: Enable the plugin

Read `~/.claude/settings.json` and add to `enabledPlugins`:

```json
{
  "enabledPlugins": {
    "kimatropic@local-plugins": true
  }
}
```

Merge with existing `enabledPlugins` — do NOT overwrite other plugins.

### Step 5: Make scripts executable

```bash
chmod +x ~/claude-local-plugins/plugins/kimatropic/scripts/kimi-preflight.sh
chmod +x ~/claude-local-plugins/plugins/kimatropic/scripts/kimi-run.sh
chmod +x ~/claude-local-plugins/plugins/kimatropic/scripts/desktop-preflight.sh
chmod +x ~/claude-local-plugins/plugins/kimatropic/scripts/screen-capture.sh
chmod +x ~/claude-local-plugins/plugins/kimatropic/hooks/session-start
```

### Step 6: Run preflight checks

```bash
# Core check (must pass)
~/claude-local-plugins/plugins/kimatropic/scripts/kimi-preflight.sh

# Desktop control check (optional — only needed for visual features)
~/claude-local-plugins/plugins/kimatropic/scripts/desktop-preflight.sh
```

Both should output "OK". If kimi-preflight fails, the plugin won't work — fix the missing dependency before continuing.

### Step 7: Verify installation

```bash
# Check hook outputs valid JSON
~/claude-local-plugins/plugins/kimatropic/hooks/session-start | python3 -c "import sys,json; d=json.load(sys.stdin); print('Hook OK, context:', len(d['hook_response']['additional_context']), 'chars')"

# Count files
echo "Agents: $(ls ~/claude-local-plugins/plugins/kimatropic/agents/ | wc -l | tr -d ' ')"
echo "Applications: $(ls ~/claude-local-plugins/plugins/kimatropic/applications/ | wc -l | tr -d ' ')"
echo "Orchestration: $(ls ~/claude-local-plugins/plugins/kimatropic/orchestration/ | wc -l | tr -d ' ')"
echo "Scripts: $(ls ~/claude-local-plugins/plugins/kimatropic/scripts/ | wc -l | tr -d ' ')"
```

Expected output:
```
Hook OK, context: ~2100 chars
Agents: 5
Applications: 13
Orchestration: 6
Scripts: 5
```

### Step 8: Reload plugins

Tell the user to run `/reload-plugins` in their Claude Code session, or restart Claude Code.

## Post-Installation: Add CLAUDE.md Auto-Routing (Recommended)

Copy the auto-routing rules into the user's project. This makes Claude automatically use kimatropic without being asked:

```bash
# Append to existing CLAUDE.md or create new one
cat ~/claude-local-plugins/plugins/kimatropic/CLAUDE.md.example >> CLAUDE.md
```

Or if the project has no CLAUDE.md yet:

```bash
cp ~/claude-local-plugins/plugins/kimatropic/CLAUDE.md.example CLAUDE.md
```

## Verification Test

After installation, run this test to verify the full pipeline works:

```bash
# Create a temp project
mkdir -p /tmp/kimi-test && cd /tmp/kimi-test && git init -q
echo "console.log('hello')" > test.js && git add -A && git commit -q -m "init"

# Test kimi-run.sh directly
~/claude-local-plugins/plugins/kimatropic/scripts/kimi-run.sh \
  --task "List all files in the current directory and describe what you see" \
  --workdir /tmp/kimi-test \
  --thinking \
  --timeout 60

# Clean up
rm -rf /tmp/kimi-test
```

This should return valid JSON with `"status": "success"` and a summary.

## Troubleshooting

### "kimi: command not found"
```bash
pip install kimi-cli
# Or if using pipx:
pipx install kimi-cli
```

### "kimi version too old"
```bash
pip install --upgrade kimi-cli
kimi --version  # Should be >= 1.19
```

### "Kimi not logged in"
```bash
kimi login
# Check credentials exist:
ls ~/.kimi/credentials/
```

### "jq: command not found"
```bash
# macOS
brew install jq
# Linux
sudo apt install jq
# Windows
choco install jq
```

### "timeout/tac: command not found" (macOS)
```bash
brew install coreutils
# This installs gtimeout and gtac; the scripts auto-detect both names
```

### "pyautogui: ModuleNotFoundError"
```bash
pip install pyautogui
# On macOS, also grant Screen Recording permission:
# System Settings > Privacy & Security > Screen Recording > Terminal (or your IDE)
```

### "Hook output is not valid JSON"
Check that the session-start script is executable and has correct line endings:
```bash
chmod +x ~/claude-local-plugins/plugins/kimatropic/hooks/session-start
# Fix line endings if cloned on Windows:
sed -i 's/\r$//' ~/claude-local-plugins/plugins/kimatropic/hooks/session-start
```

### "Plugin not showing up after install"
1. Verify `~/.claude/settings.json` has `"kimatropic@local-plugins": true` in `enabledPlugins`
2. Verify marketplace.json has the kimatropic entry
3. Run `/reload-plugins` in Claude Code
4. If still not showing, restart Claude Code completely

### "kimi-run.sh times out"
Default timeouts: 300s (single mode), 600s (swarm mode). For complex tasks:
```bash
# Increase timeout
kimi-run.sh --task "..." --timeout 900
```

## File Structure Reference

```
~/claude-local-plugins/plugins/kimatropic/
├── .claude-plugin/plugin.json     # Plugin metadata
├── agents/                        # 5 subagent definitions
│   ├── kimi-implementer.md        # Well-specified feature tasks
│   ├── kimi-researcher.md         # Codebase analysis (read-only capable)
│   ├── kimi-vision.md             # Image/video analysis
│   ├── kimi-swarm.md              # Parallel decomposition (Ralph mode)
│   └── kimi-council.md            # Multi-agent debate
├── applications/                  # 13 swarm application workflows
│   ├── design-intelligence.md     # /kimi design
│   ├── mega-debug.md              # /kimi debug
│   ├── war-room.md                # /kimi war-room
│   ├── test-storm.md              # /kimi test-storm
│   ├── code-gauntlet.md           # /kimi gauntlet
│   ├── migration-blitz.md         # /kimi migrate
│   ├── reverse-engineering.md     # /kimi reverse
│   ├── visual-regression.md       # /kimi visual-diff
│   ├── responsive-gauntlet.md     # /kimi responsive
│   ├── animation-debugger.md      # /kimi animation
│   ├── cross-app-flow.md          # /kimi flow-test
│   ├── accessibility-auditor.md   # /kimi a11y
│   └── ux-flow.md                 # /kimi ux
├── orchestration/                 # 5 composable patterns
│   ├── README.md                  # Pattern selection guide
│   ├── lens-array.md              # N parallel expert analyses
│   ├── arena.md                   # N competing implementations
│   ├── gauntlet.md                # Adversarial build/attack/fix
│   ├── assembly-line.md           # Sequential pipeline stages
│   └── hivemind.md                # Independent consensus
├── scripts/
│   ├── kimi-preflight.sh          # Dependency checker (core)
│   ├── kimi-run.sh                # Kimi CLI wrapper + summary extraction
│   ├── desktop-preflight.sh       # Dependency checker (desktop control)
│   ├── desktop-control.py         # Cross-platform desktop automation
│   └── screen-capture.sh          # Viewport screenshots + video recording
├── skills/kimi/SKILL.md           # /kimi skill definition
├── hooks/
│   ├── hooks.json                 # SessionStart hook config
│   └── session-start              # Auto-routing table injection
├── tests/                         # Test scripts
├── CLAUDE.md.example              # Auto-routing rules for user projects
├── README.md                      # Project documentation
├── CONTRIBUTING.md                # How to add patterns/applications
└── LICENSE                        # MIT
```

## Platform-Specific Notes

### macOS
- Install coreutils for `timeout` and `tac`: `brew install coreutils`
- Grant Screen Recording permission for desktop control features
- pyautogui requires Accessibility permission for click/type actions

### Linux
- Install `xdotool` for desktop control fallback (optional)
- Ensure `python3` is in PATH (not just `python`)
- X11 display must be available for pyautogui (`$DISPLAY` set)

### Windows
- Use Git Bash or WSL for shell scripts
- pyautogui works natively on Windows
- ffmpeg can be installed via `choco install ffmpeg` or `winget install ffmpeg`
