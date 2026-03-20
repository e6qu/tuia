# Project Status

**Version:** pre-release
**Last Updated:** 2026-03-20
**Repository:** https://github.com/e6qu/tuia

---

## Quick Status

**Phase 25 complete.** Execution overlay is now slide-specific and properly cleans up. Transitions disabled by default (grapheme corruption). One known deferred bug.

---

## What Works

- **TUI presentation** — start, render, navigate, quit
- **Code execution** — `e` executes code block, results shown on that slide only, `E` toggles panel
- **Dark/Light themes** — theme-aware syntax colors, live switching with `t`
- **Code blocks** — syntax highlighting, indentation, single-spacing, box borders
- **Tables** — unified bordered rendering with header separator
- **Lists** — nested indentation, ordered numbering, bullet styling
- **Text rendering** — headings (h1-h6), paragraphs, blockquotes, thematic breaks
- **Inline formatting** — bold, italic, bold+italic, strikethrough, inline code
- **Wide characters** — CJK, emoji, dingbats, variation selectors
- **Help overlay** (`?`), theme picker (`t`), navigation (j/k/g/G/number+Enter)
- **Exporters** — HTML, Reveal.js, Beamer, PDF (CLI)
- 126 unit/integration tests passing

## Known Issues

- **Transitions disabled** — show garbled characters due to dangling grapheme pointers in cell buffers. Press `T` to enable (at your own risk). Needs deep-copy fix.

---

## Metrics

| Metric | Value |
|--------|-------|
| Lines of Code | ~20,000 |
| Unit/Integration Tests | 126 (passing) |
| Open Bugs | 1 (transitions, deferred) |
| Total Bugs Fixed | 77 |

---

*Last updated: 2026-03-20 (Phase 25)*
