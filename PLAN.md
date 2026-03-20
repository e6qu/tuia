# TUIA Project Plan

> Terminal UI Application - A presenterm-compatible presentation tool in Zig

**Version:** pre-release
**Status:** Functional, polished, 1 known deferred issue
**Stack:** Zig 0.15.2, custom POSIX TUI layer

---

## Current Status: Phase 25 — Execution & Transition Fixes (Complete)

Execution overlay is slide-specific, properly cleans up on navigation. Transitions disabled by default due to grapheme corruption (dangling pointers in cell buffers).

---

## Completed Milestones

| Milestone | Status | Key Deliverables |
|-----------|--------|------------------|
| M0-M4 | Done | Full app from spec through v1.0 release |
| Security Hardening | Done | Semgrep, ziglint, fuzzing, CI checks |
| Bug Hunt Phases 1-16 | Done | 57 bugs fixed at component level |
| Phase 17-20 | Done | Working TUI, rendering, formatting, tables |
| Phase 21: Bug Sweep | Done | All 12 tmux-found bugs fixed (PR #59) |
| Phase 22: Visual Debug | Done | 4 more bugs (PR #60) |
| Phase 23: Visual Polish | Done | Theme switching, libvaxis cleanup (PR #61) |
| Phase 24: Continued Polish | Done | Theme syntax, scanner fix, emoji width (PR #62) |
| **Phase 25: Execution Fixes** | **Done** | **Slide-specific execution, char-by-char rendering, transitions disabled** |

---

## Metrics

| Metric | Value |
|--------|-------|
| Unit/Integration Tests | 126 (passing) |
| Open Bugs | 1 (transitions, deferred) |
| Total Bugs Fixed | 77 |

---

*See BUGS.md for bug history. See DO_NEXT.md for future work.*
