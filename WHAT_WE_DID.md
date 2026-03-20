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
| Phase 18 | Post-release | Rendering Quality | Code blocks, help overlay, status bar, unicode/emoji |
| Phase 19 | Post-release | Formatting & Layout | Inline styling, multi-slide code blocks, transitions, strikethrough |
| Phase 20 | Post-release | Tables & Polish | TableWidget, styled headings/blockquotes, help box fix |
| Phase 21 | Post-release | Bug Sweep | All 12 tmux-found bugs fixed (PR #59) |
| Phase 22 | Post-release | Visual Debug | 4 more bugs found & fixed via tmux screenshots (PR #60) |
| **Phase 23** | Post-release | **Visual Polish** | **Theme switching fix, libvaxis cleanup, ANSI verification** |

---

## Phase 23: Visual Polish

### What we fixed

**Theme switching had no effect at runtime (Renderer.zig)**
- Root cause: `Renderer.render()` received the `theme` parameter but discarded it (`_ = theme`). The Renderer used its own `self.theme` field set at init and never updated.
- Fix: Renderer now detects theme changes by comparing `self.theme.name` with the passed theme's name. On change, it updates `self.theme` and destroys the current slide widget to force a rebuild with the new theme's colors.

**Removed all libvaxis references**
- Source: renamed `vaxis_style` → `tui_style` in InlineTextWidget and TextWidget; updated comment in `tui/root.zig`
- Docs: updated AGENTS.md, e2e/README.md
- Examples: removed libvaxis mentions from feature-showcase.md

### Verified via ANSI captures
- Dark theme: h1 bright_white bold underline, h2 bright_white bold, h3 white bold, h4 white underline, h5 gray, bullets bright_cyan, code keywords magenta/green/yellow
- Light theme: h1 black bold underline, h2 black bold, h3 gray bold, h4 gray underline, inline code light gray bg — all correctly different from dark
- Theme picker: `t` → `j` → Enter cycles between dark/light with immediate visual effect
- Transitions: rapid j/k navigation works smoothly, no blocking

---

## Phase 22: Visual Debugging via tmux Screenshots

### What we found and fixed

**Code block double-spacing (Parser.zig)**
- Root cause: Scanner produces a `text` token for each code line (no `\n` included) followed by a `blank_line` token for the `\n` character. `parseCodeBlock` was appending `\n` for BOTH the text token AND the blank_line token → double spacing.
- Fix: Only blank_line tokens emit `\n`; text tokens no longer append a trailing newline.

**Status bar duplicate (InputHandler.zig)**
- Root cause: `showSlideStatus()` set a "Slide N/M" message on every navigation, which appeared on the right side of the status bar. The left side already shows "Slide N/M" via `renderStatusBar()`. Result: duplicate.
- Fix: Removed `showSlideStatus()` calls from navigation actions.

**List parsing — blank_lines break item loop (Parser.zig)**
- Root cause: The inner content loop in `parseList()` had `self.current.type != .blank_line` as a termination condition. Since the Scanner inserts a blank_line token after every line, the loop exited after the first item's text token, producing single-item lists. Nested items and subsequent items were never reached.
- Fix: Rewritten loop: inner content loop now stops at headings, code blocks, and other block-level elements (not blank_lines). Outer loop skips blank_lines between items to find next list_item/ordered_list_item tokens. Result: multi-item lists and nesting both work.

**Enter key parsed as Ctrl+M (Terminal.zig)**
- Root cause: In `parseKey()`, the Ctrl+letter handler (`b >= 1 and b <= 26`) came BEFORE the Enter handler. Since 0x0D (Enter/CR) = 13 which is in range 1..26, it was parsed as `Ctrl+M` (codepoint='m', ctrl=true). The `m` media handler in App.zig didn't check for ctrl modifier, so pressing Enter triggered "Media: Press 'M' to toggle playback".
- Fix: Moved Enter (0x0D, 0x0A) and Tab (0x09) checks before the Ctrl+letter handler.

### Test results
- 126 unit/integration tests pass
- All expect TUI tests pass
- tmux visual verification: code blocks, tables, lists, headings, navigation, themes, number jump all working correctly

---

## Phase 21: Fix All 12 Bugs (PR #59)

### What was broken
Comprehensive tmux testing revealed 12 bugs: 3 critical, 3 high, 6 medium.

### What we fixed

**BUG-1 (critical): Transition animation blocks navigation**
- Added `Terminal.nextEventTimeout()` for non-blocking event polling
- Event loop uses 16ms timeout during transitions for ~60fps animation
- Idle state still uses blocking `nextEvent()` for zero CPU usage

**BUG-2 (critical): Wide character screen artifacts (CJK/emoji)**
- Added `Cell.charWidth()` for Unicode East Asian Width detection
- Fixed `drawText()`, `drawTextWrapped()`, `utf8VisualLen()` in Widget.zig
- Fixed CodeWidget highlighted/plain rendering for wide chars
- Terminal.render() skips padding cells and tracks `last_col` by `cell.char.width`

**BUG-3 (critical): Code blocks — double spacing, lost indentation**
- `parseCodeBlock()` handles `.blank_line` tokens as single newlines (not double)
- Prepends `indent` spaces from token to restore indentation stripped by `skipWhitespace()`

**BUG-4 (high): Table rows render as separate tables**
- `parseTable()` skips `.blank_line` tokens between header/separator/data rows

**BUG-5 (high): List nesting and numbering**
- ListWidget renders nested lists recursively via `drawAtDepth()`
- Markers drawn char-by-char instead of as single-cell grapheme
- Depth-based indentation (3 cols per level)

**BUG-6 (high): Status bar messages never expire**
- Added `nav.tick()` in render loop — timed messages now expire correctly
- Fixed duplicate "Slide N/M" appearance (was stale message on right side)

**BUG-7 (medium): `***bold italic***` broken**
- Added `parseBoldItalic()` for triple-asterisk → `strong(emphasis(content))`

**BUG-8 (medium): Thematic breaks don't render**
- Only `---` treated as slide separator; `***`/`___` render as thematic breaks within slides
- Added `isSlideSeparator()` helper

**BUG-10 (medium): Escape sequences not handled**
- Escape sequences (`\*`, `\[`, etc.) detected early in `parseNextInlineElement()`
- Backslash+char pair skipped so they aren't interpreted as formatting markers

**BUG-9, 11, 12**: Fixed by other fixes or already correct.

### Test results
- 126 unit/integration tests pass
- All expect TUI tests pass
- Clean build

---

## Phase 20: Tables & Polish (PR #58)

- Added TableWidget with Unicode box-drawing borders
- Styled headings (h1-h6 with colors) and blockquotes (│ left border)
- Fixed help overlay box rendering

## Phase 19: Formatting & Layout

- InlineTextWidget for bold/italic/code/strikethrough rendering
- Strikethrough parser support (full pipeline)
- Multi-slide code block fix
- Transition fix (removed stale pre-navigation render)

## Phase 18: Rendering Quality

- Highlighter whitespace preservation
- Help overlay rendering fix
- Status bar char-by-char rendering
- Unicode/emoji support

---

*Last updated: 2026-03-20 (Phase 21 complete)*
