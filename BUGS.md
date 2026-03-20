# Bug Tracking

**Status:** Phase 24 — Continued Polish (complete)
**Open Bugs:** 0
**Total Fixed:** 77 (57 + 12 + 4 + 1 + 3)

---

## Open Bugs

None.

---

## Fixed in Phase 24 (Continued Polish)

| Bug | Severity | Fix |
|-----|----------|-----|
| Code syntax ignores theme | MEDIUM | `drawHighlightedCode` now uses `ctx.theme.getSyntaxColor()` before falling back to defaults |
| `_____` parsed as thematic break | MEDIUM | Scanner now checks rest-of-line is blank before emitting thematic_break; saves/restores pos on failure |
| Inline text position drift | MEDIUM | InlineTextWidget uses `utf8VisualLen()` instead of byte `.len` for segment position tracking |

## Fixed in Phase 23 (Visual Polish)

| Bug | Severity | Fix |
|-----|----------|-----|
| Theme switching no-op | HIGH | Renderer now detects theme changes, updates `self.theme`, and rebuilds slide widgets |

---

## Fixed in Phase 22 (Visual Debugging)

| Bug | Severity | Fix |
|-----|----------|-----|
| Code double-spacing | HIGH | `parseCodeBlock` text tokens no longer append `\n` (blank_line tokens handle newlines) |
| Status bar duplicate | MEDIUM | Removed redundant `showSlideStatus()` calls — `renderStatusBar()` already shows slide counter |
| List parsing broken | HIGH | Rewrote `parseList` inner loop — stops at block elements, outer loop skips blank_lines between items |
| Enter = Ctrl+M | HIGH | Moved Enter/Tab handlers before Ctrl+letter handler in `parseKey()` |

---

## Fixed in Phase 21 (PR #59)

| Bug | Severity | Fix |
|-----|----------|-----|
| BUG-1 | CRITICAL | Event loop timeout-based polling for transition animation (~60fps) |
| BUG-2 | CRITICAL | `Cell.charWidth()` + wide char support in all draw functions and Terminal.render() |
| BUG-3 | CRITICAL | Code block parsing: blank_line → single newline, indent spaces restored |
| BUG-4 | HIGH | Table parsing: skip blank_line tokens between header/separator/data rows |
| BUG-5 | HIGH | ListWidget: recursive nested rendering, char-by-char markers, depth indentation |
| BUG-6 | HIGH | `nav.tick()` in render loop; timed messages expire correctly |
| BUG-7 | MEDIUM | `parseBoldItalic()` for `***text***` → strong(emphasis()) |
| BUG-8 | MEDIUM | Only `---` separates slides; `***`/`___` render as thematic breaks |
| BUG-9 | MEDIUM | Already correct (blockquote parser stops at blank lines) |
| BUG-10 | MEDIUM | Escape sequences detected before inline format parsing |
| BUG-11 | MEDIUM | Fixed by BUG-2 wide character support |
| BUG-12 | MEDIUM | Fixed by BUG-6 (stale messages were masking jump mode) |

---

## Previously Fixed (Phases 1-20)

57 bugs across parser, renderer, widgets, TUI layer, exporters, memory management, and security.

---

*Last updated: 2026-03-20*
