# Project Status

**Version:** pre-release
**Last Updated:** 2026-03-20
**Repository:** https://github.com/e6qu/tuia

---

## Quick Status

**Phase 22 debugging complete.** All major visual issues fixed. The TUI works end-to-end: navigation, transitions, code blocks, tables, lists (nested), themes, help overlay, number jump. 4 additional bugs found and fixed during tmux testing.

---

## What Works

- **TUI presentation mode** — start, render, navigate, quit cleanly
- **Transitions** — smooth ~60fps animation via timeout-based event loop
- **Code blocks** — syntax highlighting, proper indentation, single-spacing, border box
- **Tables** — unified bordered rendering with header separator
- **Lists** — nested indentation, ordered numbering (1-12), bullet styling
- **Text rendering** — headings (h1-h6 styled), paragraphs, blockquotes (│ border)
- **Inline formatting** — **bold**, *italic*, ***bold italic***, ~~strikethrough~~, `inline code`
- **Thematic breaks** — horizontal rules (*** and ___ render within slides, --- separates)
- **Wide characters** — CJK and emoji with proper 2-column width handling
- **Help overlay** (`?`) — keyboard shortcuts
- **Theme switching** (`t`) — dark/light picker
- **Navigation** — j/k/arrows/space, g/G first/last, number+Enter jump
- **Status bar** — slide counter left, title center, timed messages right
- **Escape sequences** — `\*`, `\[`, etc. render as literal characters
- **Enter key** — correctly parsed (not confused with Ctrl+M)
- **Exporters** — HTML, Reveal.js, Beamer, PDF (CLI)
- 126 unit/integration tests, 30 expect TUI tests (all passing)

## Needs Verification

- **Light theme visual appearance** — defined but not visually confirmed (colors look correct in code)
- **Transition visual quality** — animation works but haven't verified no artifacts

---

## Metrics

| Metric | Value |
|--------|-------|
| Lines of Code | ~20,000 |
| Unit/Integration Tests | 126 (passing) |
| TUI Tests (real pty) | 30 (passing) |
| Open Bugs | 0 |

---

*Last updated: 2026-03-20 (Phase 22)*
