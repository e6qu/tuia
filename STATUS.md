# Project Status

**Version:** pre-release (functional TUI)
**Last Updated:** 2026-03-19
**Repository:** https://github.com/e6qu/tuia

---

## Quick Status

**The app works.** Running `tuia presentation.md` starts the app, renders slides with visible text, accepts navigation input (j/k/g/G/arrows/space), and exits cleanly with `q` or Ctrl+C. Terminal state is properly restored on exit. Non-tty contexts get a clean error message.

---

## What Works

- **TUI presentation mode** — start, render, navigate, quit
- Parser: Markdown to AST (unit tested)
- Converter: AST to presentation model (unit tested)
- Exporters: HTML, Reveal.js, Beamer, PDF (integration tested, CLI works)
- Pre-commit hooks: zig fmt, lint, unit tests
- Welcome screen when launched without a file
- Human-readable error messages (no stack traces for users)
- 30 expect-based TUI tests through real pty (no fake tty hacks)

## What Needs Work

- Help overlay (`?`) doesn't visually render (toggle logic works but widget doesn't draw)
- Code blocks render without spaces between tokens
- Transition animations are disabled (broken — caused off-by-one slide rendering)
- Table rendering shows placeholder text ("[Table: render not yet implemented]")
- Some text corruption on slides with complex inline formatting

---

## Metrics

| Metric | Value |
|--------|-------|
| Lines of Code | ~20,000 |
| Unit/Integration Tests | 120 |
| TUI Tests (expect, real pty) | 30 |
| App starts and renders | Yes |
| Navigation works | Yes |
| Clean exit | Yes |

---

*Last updated: 2026-03-19 (Phase 17 complete)*
