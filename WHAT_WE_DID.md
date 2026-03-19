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
| Phase 13 | Post-release | Memory & Safety | 14 bugs fixed |
| Phase 14 | Post-release | TUI Layer | Replaced libvaxis with custom POSIX terminal layer |
| Phase 15-15b | Post-release | Fixes | 8 more bugs |
| Phase 16 | Post-release | TUI Bugs | 5 parser/exporter fixes, 25 expect tests |
| Phase 17 | Post-release | Make It Work | App starts, renders, navigates, quits cleanly |
| **Phase 18** | Post-release | **Rendering Quality** | **Code blocks, help overlay, status bar, unicode/emoji** |

---

## Phase 18: Rendering Quality

### What was broken
- Code blocks rendered without whitespace between tokens ("constx=42" instead of "const x = 42")
- Help overlay (`?`) didn't render (HelpWidget.visible never synced with nav.show_help)
- Status bar showed garbled characters (entire strings written to single cells)
- No unicode/emoji support (byte-by-byte iteration missed multi-byte sequences)
- Transitions enabled by default caused off-by-one slide rendering

### What we fixed

**Highlighter whitespace preservation**
- Changed `Highlighter.nextToken()` to emit whitespace as tokens instead of skipping it
- Added `.whitespace` to `TokenKind` enum with appropriate color/index mappings
- Code blocks now render with proper spacing between tokens

**Help overlay rendering**
- Removed redundant `if (help.visible)` check in Renderer — the caller already gates via `nav.show_help`
- Removed `if (!self.visible) return` guard in HelpWidget.draw()
- Help overlay now renders keyboard shortcuts when `?` is pressed

**Status bar char-by-char rendering**
- Rewrote `renderStatusBar()` and `renderDebug()` in Renderer.zig to iterate character-by-character
- Uses `tui.Cell.grapheme(ch)` for each byte instead of writing entire strings to single cells
- Status bar now shows clean "Slide N/M" and title text

**Full unicode and emoji support**
- Updated `drawText()` and `drawTextWrapped()` in Widget.zig to iterate by UTF-8 codepoints
- Uses `std.unicode.utf8ByteSequenceLength()` to detect multi-byte sequences
- Writes multi-byte grapheme slices directly to cells (stable memory from source text)
- Updated `drawHighlightedCode()` and `drawPlainCode()` in CodeWidget.zig for UTF-8
- Japanese, CJK, math symbols, and emoji all render correctly

**Transitions disabled**
- Set `TransitionConfig.enabled` default to `false`
- Fixed transition manager tests for new default

### Verified via tmux screenshots
- All text renders correctly (headings, paragraphs, lists, blockquotes)
- Code blocks show syntax-highlighted code with proper spacing (single-slide)
- Status bar shows "Slide N/M" and title cleanly
- Help overlay shows keyboard shortcuts
- Theme picker works (dark/light switching)
- Unicode (こんにちは, ∑∫∂√π, →←↑↓) and emoji (🎉🚀📝) render correctly

---

*Last updated: 2026-03-20 (Phase 18 complete)*
