# TUIA Project Plan

> Terminal UI Application - A presenterm-compatible presentation tool in Zig

**Version:** pre-release
**Status:** Functional — app starts, renders, navigates, exits cleanly
**Stack:** Zig 0.15.2, custom POSIX TUI layer

---

## Current Status: Phase 17 Complete

The app works. `tuia examples/demo.md` starts, renders slides with visible text, responds to navigation input, and exits cleanly. All 120 unit/integration tests and 30 expect-based TUI tests pass.

---

## Completed Milestones

| Milestone | Status | Key Deliverables |
|-----------|--------|------------------|
| M0: Specification | Done | Requirements, architecture, API design |
| M1: Foundation | Done | Build system, CI/CD, testing framework |
| M2: Core Presentation | Done | Parser, widgets, themes, navigation |
| M3: Advanced Features | Done | Images, code execution, export, config |
| M4: Polish & Release | Done | Documentation, v1.0.0 release |
| Security Hardening | Done | Semgrep, ziglint, fuzzing, CI checks |
| Bug Hunt Phases 1-16 | Done | 57 bugs fixed at component level |
| **Phase 17: Make It Work** | **Done** | **App starts, text renders, navigation works, clean exit** |

---

## Next Priorities

See DO_NEXT.md for details.

1. Fix remaining rendering issues (help overlay, code block spacing, tables)
2. Fix transition animations (currently disabled due to off-by-one bug)
3. Improve differential rendering (handle edge cases with style-only changes)
4. Add more content validation in expect tests

---

## Metrics

| Metric | Value |
|--------|-------|
| Lines of Code | ~20,000 |
| Unit/Integration Tests | 120 (passing) |
| TUI Tests (real pty) | 30 (passing) |
| App starts and renders | **Yes** |
| User can present slides | **Yes** |

---

*See WHAT_WE_DID.md for phase-by-phase history.*
*See DO_NEXT.md for what needs to happen next.*
