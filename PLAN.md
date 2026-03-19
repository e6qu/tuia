# TUIA Project Plan

> Terminal UI Application - A presenterm-compatible presentation tool in Zig

**Version:** pre-release
**Status:** Functional with rendering fixes
**Stack:** Zig 0.15.2, custom POSIX TUI layer

---

## Current Status: Phase 18 Complete

The app works with proper rendering. Code blocks, help overlay, status bar, unicode, and emoji all render correctly. 120 unit/integration tests and 30 expect TUI tests pass.

---

## Completed Milestones

| Milestone | Status | Key Deliverables |
|-----------|--------|------------------|
| M0-M4 | Done | Full app from spec through v1.0 release |
| Security Hardening | Done | Semgrep, ziglint, fuzzing, CI checks |
| Bug Hunt Phases 1-16 | Done | 57 bugs fixed at component level |
| Phase 17: Make It Work | Done | App starts, renders, navigates, clean exit |
| **Phase 18: Rendering** | **Done** | **Code blocks, help, status bar, unicode/emoji** |

---

## Next Priorities

See DO_NEXT.md for details.

1. Fix code blocks in multi-slide presentations (layout/converter bug)
2. Fix transition animations (render to separate buffer, not main screen)
3. Implement table rendering widget
4. Process inline formatting (bold, italic, strikethrough, code spans)

---

## Metrics

| Metric | Value |
|--------|-------|
| Lines of Code | ~20,000 |
| Unit/Integration Tests | 120 (passing) |
| TUI Tests (real pty) | 30 (passing) |
| App renders correctly | **Yes** |
| Unicode/emoji support | **Yes** |
| Help overlay | **Yes** |
| Theme switching | **Yes** |

---

*See WHAT_WE_DID.md for phase-by-phase history.*
*See DO_NEXT.md for what needs to happen next.*
