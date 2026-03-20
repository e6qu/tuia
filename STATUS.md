# Project Status

**Version:** pre-release
**Last Updated:** 2026-03-20
**Repository:** https://github.com/e6qu/tuia

---

## Quick Status

**Planning stub completion (Phases 26-30).** Comprehensive audit found ~60 stubs, placeholder modules, dead functions, and unwired config fields. Plan:
- Phase 26: Dead code cleanup (14 empty modules, 4 dead functions)
- Phase 27: Config wiring (18+ config fields → runtime behavior)
- Phase 28: Fix transitions (deep-copy grapheme data)
- Phase 29: Slide overview mode (`o` key)
- Phase 30: Minor stubs polish

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

- Transitions disabled by default (dangling grapheme pointers — Phase 28 fix)

---

## Metrics

| Metric | Value |
|--------|-------|
| Unit/Integration Tests | 126 (passing) |
| Open Bugs | 1 (transitions) |
| Total Bugs Fixed | 77 |
| Stubs/Dead Code | ~60 items (Phase 26-30 plan) |

---

*Last updated: 2026-03-20*
