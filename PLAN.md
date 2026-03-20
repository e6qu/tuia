# TUIA Project Plan

> Terminal UI Application - A presenterm-compatible presentation tool in Zig

**Version:** pre-release
**Status:** Visual debugging and polish
**Stack:** Zig 0.15.2, custom POSIX TUI layer

---

## Current Status: Phase 22 — Visual Debugging (Complete)

Phase 21 fixed 12 bugs. Phase 22 found and fixed 4 more via tmux screenshot debugging:
- Code block double-spacing (blank_line token handling in parseCodeBlock)
- Status bar duplicate (removed redundant showSlideStatus messages)
- List parsing (blank_lines broke multi-item list loop)
- Enter key (Ctrl+letter handler intercepted Enter before Enter handler in parseKey)

---

## Completed Milestones

| Milestone | Status | Key Deliverables |
|-----------|--------|------------------|
| M0-M4 | Done | Full app from spec through v1.0 release |
| Security Hardening | Done | Semgrep, ziglint, fuzzing, CI checks |
| Bug Hunt Phases 1-16 | Done | 57 bugs fixed at component level |
| Phase 17: Make It Work | Done | App starts, renders, navigates, clean exit |
| Phase 18: Rendering | Done | Code blocks, help overlay, status bar, unicode/emoji |
| Phase 19: Formatting | Done | Inline styling, multi-slide code blocks, transitions, strikethrough |
| Phase 20: Tables & Polish | Done | TableWidget, styled headings/blockquotes, help box fix |
| Phase 21: Bug Sweep | Done | All 12 tmux-found bugs fixed (PR #59) |
| **Phase 22: Visual Debug** | **Done** | **4 more bugs fixed via tmux screenshots** |

---

## Metrics

| Metric | Value |
|--------|-------|
| Lines of Code | ~20,000 |
| Unit/Integration Tests | 126 (passing) |
| TUI Tests (real pty) | 30 (passing) |
| Open Bugs | 0 |
| Total Bugs Fixed | 73 (57 + 12 + 4) |

---

*See BUGS.md for bug history.*
*See WHAT_WE_DID.md for phase-by-phase history.*
*See DO_NEXT.md for current task details.*
