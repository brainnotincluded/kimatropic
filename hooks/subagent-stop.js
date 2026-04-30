#!/usr/bin/env node
/**
 * subagent-stop — Log Kimi delegations to ~/.claude/kimatropic-usage.jsonl
 *
 * Reads hook input from stdin (JSON). Looks for kimi-* subagent terminations
 * and appends a usage record. Silent on non-kimi subagents.
 *
 * Cross-platform: Windows, macOS, Linux.
 */

const fs = require('fs');
const os = require('os');
const path = require('path');

let raw = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (chunk) => { raw += chunk; });
process.stdin.on('end', () => {
  try {
    const input = raw ? JSON.parse(raw) : {};
    const subagentType = input.subagent_type || input.agent_type || '';
    if (!subagentType.startsWith('kimi-') && !subagentType.startsWith('kimatropic:')) {
      return;
    }

    const record = {
      ts: new Date().toISOString(),
      session_id: input.session_id || null,
      subagent_type: subagentType,
      duration_ms: input.duration_ms || null,
      total_tokens: input.total_tokens || null,
      cwd: input.cwd || process.cwd()
    };

    const dir = path.join(os.homedir(), '.claude');
    fs.mkdirSync(dir, { recursive: true });
    fs.appendFileSync(path.join(dir, 'kimatropic-usage.jsonl'), JSON.stringify(record) + '\n');
  } catch (e) {
    // Hook errors must not break the session — fail silently.
  }
});
