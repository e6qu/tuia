# Project Status

**Version:** pre-release
**Last Updated:** 2026-03-20
**Repository:** https://github.com/e6qu/tuia

---

## Quick Status

**Phase 23 complete.** Theme switching works (dark/light themes verified via ANSI captures). Renderer now responds to runtime theme changes. All libvaxis references removed. The TUI is fully functional.

---

## What Works

- **TUI presentation mode** — start, render, navigate, quit cleanly
- **Transitions** — smooth ~60fps animation, rapid navigation works
- **Dark theme** — bright_white headings, cyan bullets, magenta keywords, green strings, dark code bg
- **Light theme** — black headings, blue bullets, light code bg — switches correctly at runtime
- **Code blocks** — syntax highlighting, indentation, single-spacing, Unicode box borders
- **Tables** — unified bordered rendering with header separator
- **Lists** — nested indentation, ordered numbering (1-12), bullet styling
- **Text rendering** — headings (h1-h6 styled), paragraphs, blockquotes (│ border)
- **Inline formatting** — **bold**, *italic*, ***bold italic***, ~~strikethrough~~, `inline code`
- **Thematic breaks** — *** and ___ render as horizontal rules, --- separates slides
- **Wide characters** — CJK and emoji with proper 2-column width
- **Help overlay** (`?`) — keyboard shortcuts
- **Theme switching** (`t`) — dark/light picker, live rebuild of slide widgets
- **Navigation** — j/k/arrows/space, g/G first/last, number+Enter jump
- **Status bar** — slide counter left, title center, timed messages right
- **Escape sequences** — `\*`, `\[`, etc. render as literal characters
- **Exporters** — HTML, Reveal.js, Beamer, PDF (CLI)
- 126 unit/integration tests, 30 expect TUI tests (all passing)

---

## Metrics

| Metric | Value |
|--------|-------|
| Lines of Code | ~20,000 |
| Unit/Integration Tests | 126 (passing) |
| TUI Tests (real pty) | 30 (passing) |
| Open Bugs | 0 |
| Total Bugs Fixed | 74 |

---

*Last updated: 2026-03-20 (Phase 23)*
