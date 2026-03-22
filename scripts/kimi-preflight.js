#!/usr/bin/env node
/**
 * kimi-preflight.js — Verify all dependencies before running Kimi delegation
 * Cross-platform: Windows, macOS, Linux
 * 
 * Checks: kimi CLI, git, jq, kimi credentials
 * Note: timeout/tac (GNU coreutils) only needed for bash scripts on Unix.
 * On Windows, the Node.js versions of scripts are used instead.
 * 
 * Exit codes:
 *   0 — All checks passed
 *   1 — One or more dependency checks failed
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

const errors = [];
const warnings = [];

// Common installation paths on Windows
const windowsPythonPaths = [
  path.join(os.homedir(), 'AppData', 'Local', 'Packages', 'PythonSoftwareFoundation.Python.3.12_qbz5n2kfra8p0', 'LocalCache', 'local-packages', 'Python312', 'Scripts'),
  path.join(os.homedir(), 'AppData', 'Roaming', 'Python', 'Python312', 'Scripts'),
  path.join(os.homedir(), 'AppData', 'Local', 'Programs', 'Python', 'Python312', 'Scripts'),
  'C:\\Python312\\Scripts',
];

function findExecutable(name) {
  const isWindows = os.platform() === 'win32';
  const exeName = isWindows ? `${name}.exe` : name;
  
  // Check PATH first
  try {
    const whichCmd = isWindows ? 'where' : 'which';
    const result = execSync(`${whichCmd} ${exeName}`, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'ignore'] });
    return result.trim().split('\n')[0];
  } catch (e) {
    // Not in PATH, search common locations on Windows
    if (isWindows) {
      for (const basePath of windowsPythonPaths) {
        const fullPath = path.join(basePath, exeName);
        if (fs.existsSync(fullPath)) {
          return fullPath;
        }
      }
    }
    return null;
  }
}

function checkCommand(cmd) {
  const executablePath = findExecutable(cmd);
  if (!executablePath) {
    return { found: false, path: null, output: '' };
  }
  
  try {
    const result = execSync(`"${executablePath}" --version`, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'ignore'] });
    return { found: true, path: executablePath, output: result.trim() };
  } catch (e) {
    return { found: true, path: executablePath, output: '' };
  }
}

function parseVersion(output) {
  const match = output.match(/(\d+\.\d+(?:\.\d+)?)/);
  return match ? match[1] : null;
}

function compareVersions(v1, v2) {
  const parts1 = v1.split('.').map(Number);
  const parts2 = v2.split('.').map(Number);
  for (let i = 0; i < Math.max(parts1.length, parts2.length); i++) {
    const a = parts1[i] || 0;
    const b = parts2[i] || 0;
    if (a < b) return -1;
    if (a > b) return 1;
  }
  return 0;
}

// Check kimi CLI
const kimiCheck = checkCommand('kimi');
if (!kimiCheck.found) {
  errors.push('kimi CLI not found. Install: pip install kimi-cli');
} else {
  const version = parseVersion(kimiCheck.output);
  if (version && compareVersions(version, '1.19') < 0) {
    errors.push(`kimi CLI version ${version} < required 1.19. Run: pip install --upgrade kimi-cli`);
  } else {
    console.error(`✓ kimi CLI: ${version || 'found'} at ${kimiCheck.path}`);
  }
}

// Check git
const gitCheck = checkCommand('git');
if (!gitCheck.found) {
  errors.push('git not found in PATH');
} else {
  console.error(`✓ git: found at ${gitCheck.path}`);
}

// Check jq
const jqCheck = checkCommand('jq');
if (!jqCheck.found) {
  const installCmd = os.platform() === 'darwin' ? 'brew install jq' : 
                     os.platform() === 'linux' ? 'apt install jq' :
                     'Download from https://jqlang.github.io/jq/ or run: scoop install jq';
  errors.push(`jq not found. ${installCmd}`);
} else {
  console.error(`✓ jq: found at ${jqCheck.path}`);
}

// Check kimi credentials
const homedir = os.homedir();
const kimiCredsDir = path.join(homedir, '.kimi', 'credentials');
if (!fs.existsSync(kimiCredsDir)) {
  errors.push('Kimi not logged in. Run: kimi login');
} else {
  console.error(`✓ Kimi credentials: found at ${kimiCredsDir}`);
}

// Note about GNU coreutils (timeout/tac)
// These are only needed for the legacy bash scripts
// The Node.js versions don't require them
if (os.platform() !== 'win32') {
  const timeoutCheck = checkCommand('timeout') || checkCommand('gtimeout');
  const tacCheck = checkCommand('tac') || checkCommand('gtac');
  if (!timeoutCheck.found || !tacCheck.found) {
    warnings.push('GNU coreutils (timeout, tac) not found. Some legacy bash scripts may require them.');
    warnings.push('  Install: brew install coreutils (macOS) or apt install coreutils (Linux)');
  }
}

// Report results
if (warnings.length > 0) {
  for (const warning of warnings) {
    console.warn(`⚠ ${warning}`);
  }
}

if (errors.length > 0) {
  console.error(`\nkimi-preflight: ${errors.length} error(s) found:`);
  for (const err of errors) {
    console.error(`  ✗ ${err}`);
  }
  process.exit(1);
}

console.error('\nkimi-preflight: all checks passed ✓');
process.exit(0);
