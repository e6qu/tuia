# Project Status

**Version:** pre-release
**Last Updated:** 2026-03-20
**Repository:** https://github.com/e6qu/tuia

---

## Quick Status

**Phase 24 complete.** Code syntax colors now follow the active theme. Thematic break scanner fixed to only match line-only patterns. Emoji/unicode position tracking fixed in inline text. 77 total bugs fixed, 0 open.

---

## What Works

- **TUI presentation mode** — start, render, navigate, quit cleanly
- **Transitions** — smooth ~60fps animation, rapid navigation works
- **Dark theme** — bright headings, cyan bullets, magenta/green/yellow syntax highlighting
- **Light theme** — dark headings, blue bullets, purple/green/red syntax highlighting (theme-specific)
- **Code blocks** — theme-aware syntax colors, indentation, single-spacing, box borders
- **Tables** — unified bordered rendering with header separator, emoji in cells
- **Lists** — nested indentation, ordered numbering (1-12), bullet styling
- **Text rendering** — headings (h1-h6 styled), paragraphs, blockquotes (│ border)
- **Inline formatting** — **bold**, *italic*, ***bold italic***, ~~strikethrough~~, `inline code`
- **Thematic breaks** — `***`/`___` render as rules (only when line has no other content)
- **Wide characters** — CJK, emoji, dingbats, variation selectors all handled correctly
- **Inline text position** — emoji/unicode segments tracked by visual width, not byte length
- **Help overlay** (`?`) — keyboard shortcuts
- **Theme switching** (`t`) — dark/light with live rebuild
- **Navigation** — j/k/arrows/space, g/G, number+Enter jump
- **Status bar** — slide counter left, title center
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
| Total Bugs Fixed | 77 |

---

*Last updated: 2026-03-20 (Phase 24)*
