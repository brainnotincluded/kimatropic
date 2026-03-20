# Reverse Engineering

**Invoke:** `/kimi reverse <target-codebase-or-url>`
**Patterns:** LENS ARRAY
**Agents used:** kimi-researcher (6 instances, read-only) + kimi-vision (for URL targets)
**Desktop control required:** Only for URL/app targets
**Browser tools required:** Only for URL targets

## Input

Codebase path or URL to analyze.

## Stage 1: Capture (Claude)

- If URL: navigate entire site, record video, screenshot every unique page
- If codebase: identify entry points, list files, build dependency graph overview
- If native app: record video of using all features via desktop control

## Stage 2: Parallel Analysis (LENS ARRAY — 6 instances)

| Lens | Focus | Agent Type |
|------|-------|-----------|
| Data Model | Entity relationships, schemas, data flow | kimi-researcher |
| Auth & Security | Auth flow, session handling, security model | kimi-researcher |
| API Surface | Routes, endpoints, request/response formats | kimi-researcher |
| Error Handling | Catch blocks, error states, recovery strategies | kimi-researcher |
| State Management | State stores, data flow, side effects | kimi-researcher |
| UI/UX Mapper | Sitemap, component hierarchy, user flows | kimi-vision (if URL/app) or kimi-researcher |

## Output

Comprehensive architecture document with diagrams and entry points.
