#!/usr/bin/env node
/**
 * stop — Summarize this session's Kimi usage on Stop event.
 *
 * Reads ~/.claude/kimatropic-usage.jsonl, filters records for the current
 * session_id, and writes a one-line summary to stderr (visible in transcript).
 * If KIMATROPIC_USAGE_SUMMARY=0 in env, runs silently.
 *
 * Cross-platform: Windows, macOS, Linux.
 */

const fs = require('fs');
const os = require('os');
const path = require('path');

if (process.env.KIMATROPIC_USAGE_SUMMARY === '0') process.exit(0);

let raw = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (chunk) => { raw += chunk; });
process.stdin.on('end', () => {
  try {
    const input = raw ? JSON.parse(raw) : {};
    const sessionId = input.session_id;
    if (!sessionId) return;

    const file = path.join(os.homedir(), '.claude', 'kimatropic-usage.jsonl');
    if (!fs.existsSync(file)) return;

    const lines = fs.readFileSync(file, 'utf8').split('\n').filter(Boolean);
    let count = 0;
    let totalTokens = 0;
    let totalMs = 0;
    const byType = {};
    for (const line of lines) {
      try {
        const r = JSON.parse(line);
        if (r.session_id !== sessionId) continue;
        count++;
        totalTokens += r.total_tokens || 0;
        totalMs += r.duration_ms || 0;
        byType[r.subagent_type] = (byType[r.subagent_type] || 0) + 1;
      } catch { /* skip malformed line */ }
    }

    if (count === 0) return;

    const breakdown = Object.entries(byType)
      .map(([k, v]) => `${k}=${v}`)
      .join(', ');
    const seconds = Math.round(totalMs / 100) / 10;
    process.stderr.write(
      `[kimatropic] ${count} delegation${count === 1 ? '' : 's'} this session ` +
      `(${breakdown}) — ${totalTokens} tokens, ${seconds}s wall\n`
    );
  } catch {
    // silent
  }
});
