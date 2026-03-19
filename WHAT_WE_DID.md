# What We Did

> Development history of TUIA

---

## Project Timeline

| Phase | Dates | Focus | Key Deliverables |
|-------|-------|-------|------------------|
| M0 | Week 1 | Specification | Architecture, API design, requirements |
| M1 | Weeks 2-4 | Foundation | Build system, CI/CD, TUI loop |
| M2 | Weeks 5-10 | Core | Parser, widgets, themes, navigation |
| M3 | Weeks 11-16 | Features | Images, code execution, export, config |
| M4 | Weeks 17-20 | Polish | Documentation, v1.0.0 release |
| Security | Post-release | Hardening | Semgrep, ziglint, fuzzing, CI checks |
| Phases 1-12 | Post-release | Bug Fixes | 27 bugs fixed (17 critical, 10 high/med/low) |
| Phase 13 | Post-release | Memory & Safety | 14 bugs fixed (3 critical, 4 high, 5 medium, 2 compile) |
| Phase 14 | Post-release | TUI Layer | Replaced libvaxis with custom POSIX terminal layer |
| Phase 15-15b | Post-release | Fixes | 8 more bugs (compile, URL escaping, render crashes) |
| Phase 16 | Post-release | TUI Bugs | 5 parser/exporter fixes, 25 expect tests, pre-commit hooks |
| **Phase 17** | Post-release | **Make It Work** | **App starts, renders, navigates, quits. Text rendering fixed.** |

---

## Phase 17: Make tuia Actually Work

### What was broken
- App crashed or hung when started from a terminal
- 57 bugs "fixed" across 16 phases but the app was never tested as a running program
- Text content was invisible (use-after-free in grapheme storage)
- Transitions caused off-by-one slide rendering
- `TUIA_TTY_FD=0` hack in tests masked real terminal issues

### What we fixed

**Terminal init (fd fallback chain)**
- Prefer stdin when it's a tty (works in real terminals and pty contexts)
- Fall back to `/dev/tty` via raw syscall (avoids Zig's `unexpectedErrno` stack trace on ENXIO)
- Clean "tuia requires a terminal" error message for non-tty contexts

**Event loop reliability**
- Added `tryPopTimeout` to the event queue (500ms timeout, prevents infinite blocking)
- Added `readloop_alive` flag so main thread detects reader thread death
- `nextEvent` returns `?Event` — main loop exits if reader dies or quit is signaled

**Text rendering (critical fix)**
- Found and fixed use-after-free: `&[_]u8{char}` created stack-allocated graphemes that became dangling pointers
- Added `Cell.grapheme()` static lookup table — 256 pre-allocated single-byte strings
- Fixed 10 call sites across 6 widget files (Widget, StatusBar, NoteWidget, ImageWidget, HelpWidget, CodeWidget)

**Navigation**
- Added null navigation guard in `handleKey()` — prevents panic when no presentation loaded
- Disabled transitions by default (broken — pre-navigation render caused off-by-one display)

**Other fixes**
- Fixed macOS fd leak in `deinit()` (removed `builtin.os.tag != .macos` guard on close)
- Added `render_failed` flag for detecting write errors during rendering
- Wrapped `App.init` and `app.run()` in catch blocks for human-readable errors

**Tests**
- Removed `TUIA_TTY_FD=0` hack from expect tests
- Added rendering validation (escape sequence detection)
- Added navigation validation (re-render detection after keypress)
- Added welcome screen test (no-file mode)
- 30 expect tests pass through real pty, 120 unit/integration tests pass

### Lessons Learned
- 57 "bug fixes" across 16 phases, but the app was never started and used
- Unit tests and integration tests don't prove the app works — they prove individual components work in isolation
- `&[_]u8{char}` is a classic Zig footgun — the temporary lives only as long as the expression
- Fake interfaces (`TUIA_TTY_FD`) mask real problems instead of exposing them
- A program that can't be started by a user is not a program

---

*Last updated: 2026-03-19 (Phase 17 complete)*
