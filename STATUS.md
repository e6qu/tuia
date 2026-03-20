# Project Status

**Version:** pre-release
**Last Updated:** 2026-03-20
**Repository:** https://github.com/e6qu/tuia

---

## Quick Status

**Phase 26 complete.** Deleted 16 dead files, 4 dead functions (93 lines of dead code removed). All tests pass, no regressions. Next: Phase 27 (config wiring).

---

## What Works

- TUI presentation — start, render, navigate, quit
- Code execution — slide-specific, `e`/`E` toggle
- Dark/Light themes — theme-aware syntax colors, live switching
- Code blocks, tables, lists (nested), blockquotes, thematic breaks
- Inline formatting — bold, italic, bold+italic, strikethrough, inline code
- Wide characters — CJK, emoji, dingbats, variation selectors
- Help overlay, theme picker, navigation (j/k/g/G/number+Enter)
- Exporters — HTML, Reveal.js, Beamer, PDF (CLI)
- 126 unit/integration tests passing

## Known Issues

- Transitions disabled by default (Phase 28)
- 18+ config fields parsed but unwired (Phase 27)

---

## Metrics

| Metric | Value |
|--------|-------|
| Unit/Integration Tests | 126 (passing) |
| Open Bugs | 1 (transitions) |
| Total Bugs Fixed | 77 |
| Dead Code Deleted | 16 files, 93 lines (Phase 26) |

---

*Last updated: 2026-03-20 (Phase 26 complete)*
