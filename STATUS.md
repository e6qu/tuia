# Project Status

**Version:** pre-release (functional TUI with rendering fixes)
**Last Updated:** 2026-03-20
**Repository:** https://github.com/e6qu/tuia

---

## Quick Status

**The app works with proper rendering.** Slides render text, code blocks, unicode, emoji, and status bars correctly. Help overlay, theme switching, and navigation all function. Code blocks with syntax highlighting render with proper spacing.

---

## What Works

- **TUI presentation mode** — start, render, navigate, quit
- **Text rendering** — headings, paragraphs, lists, blockquotes
- **Code blocks** — syntax highlighting with proper whitespace, bordered display
- **Unicode & emoji** — full multi-byte UTF-8 support (CJK, math symbols, emoji)
- **Help overlay** (`?`) — keyboard shortcuts display
- **Theme switching** (`t`) — dark/light theme picker
- **Status bar** — slide counter, title, messages render correctly
- **Welcome screen** — clean display when no file is given
- **Exporters** — HTML, Reveal.js, Beamer, PDF (CLI works)
- **Error handling** — human-readable messages, no stack traces
- 120 unit/integration tests, 30 expect TUI tests

## What Needs Work

- Code blocks don't render on multi-slide presentations (layout/converter bug)
- Transitions disabled (broken — pre-navigation render causes off-by-one)
- Table rendering shows placeholder text
- Inline formatting shows raw markers (~~strikethrough~~)
- Help overlay box corners slightly garbled (unicode box-drawing alignment)

---

## Metrics

| Metric | Value |
|--------|-------|
| Lines of Code | ~20,000 |
| Unit/Integration Tests | 120 |
| TUI Tests (expect, real pty) | 30 |
| App starts and renders | Yes |
| Unicode/emoji support | Yes |
| Theme switching | Yes |
| Help overlay | Yes |

---

*Last updated: 2026-03-20 (Phase 18 — rendering quality fixes)*
