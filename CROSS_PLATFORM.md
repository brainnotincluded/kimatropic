# Cross-Platform Compatibility Changes

## Summary

Made kimatropic compatible with **Windows, macOS, and Linux** by replacing bash-only scripts with cross-platform Node.js alternatives.

## Changes Made

### 1. Session Start Hook (`hooks/`)
- **New:** `session-start.js` — Cross-platform Node.js hook
- **Updated:** `hooks.json` — Now calls `node session-start.js` instead of bash
- **Why:** The bash script wouldn't execute on Windows without Git Bash

### 2. Preflight Script (`scripts/`)
- **New:** `kimi-preflight.js` — Cross-platform dependency checker
- **Features:**
  - Auto-detects executables on Windows (including in Python Scripts folders)
  - Provides platform-specific installation instructions
  - Shows detailed success/failure for each check
  - Handles Windows `.exe` extensions automatically

### 3. Documentation (`skills/kimi/SKILL.md`)
- Updated to reference cross-platform scripts

## Verification

Test the preflight script:
```bash
# On any platform:
node ~/claude-local-plugins/plugins/kimatropic/scripts/kimi-preflight.js

# Should output:
# ✓ kimi CLI: 1.24.0 at [path]
# ✓ git: found at [path]
# ✓ jq: found at [path]
# ✓ Kimi credentials: found at [path]
# 
# kimi-preflight: all checks passed ✓
```

## Platform-Specific Notes

### Windows
- Node.js scripts work natively
- Executables auto-detected in common Python installation paths
- No Git Bash required for basic functionality

### macOS
- Works with standard Node.js installation
- GNU coreutils (`timeout`, `tac`) only needed for legacy bash scripts
- Install with: `brew install coreutils`

### Linux
- Works with standard Node.js installation
- GNU coreutils usually pre-installed

## Legacy Scripts

The original bash scripts are preserved for backward compatibility:
- `hooks/session-start` (bash)
- `scripts/kimi-preflight.sh` (bash)
- `scripts/desktop-preflight.sh` (bash)

These can still be used on Unix systems if preferred.
