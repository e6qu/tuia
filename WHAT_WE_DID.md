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
| Bug Hunt | Ongoing | Fixes | 27 bugs fixed (17 critical, 10 high/med/low) |
| Phase 13 | Post-release | Memory & Safety | 14 bugs fixed (3 critical, 4 high, 5 medium, 2 compile) |
| Phase 14 | Post-release | TUI Layer | Fixed-memory terminal, zero-alloc rendering (3 bugs fixed) |
| Phase 15 | Post-release | Final Sweep | 3 bugs fixed (compile, URL escaping) |
| Phase 15b | Post-release | TUI Testing | 5 crash/overflow bugs fixed (render, parser) |
| Phase 16 | Post-release | TUI Bug Sweep | 5 bugs fixed (pty input, parser, HTML export) + 25 TUI tests |

---

## Key Achievements

### Core Features
- Markdown parser with front matter support
- Widget system (text, headings, code, lists, tables, images)
- Theme engine (dark/light built-in, custom YAML themes)
- vim-style navigation with jump-to-slide

### Advanced Features
- Speaker notes
- Code execution (8 languages)
- Image display (Kitty/iTerm2/Sixel/ASCII)
- HTML export

### TUI & Export (Phases 14-16)
- Fixed-memory TUI terminal layer (zero runtime allocations)
- Reveal.js, Beamer/LaTeX, PDF export formats
- 25 automated TUI tests using expect/pty
- `TUIA_TTY_FD` env var for pty-based testing
- Parser fixes: heading tokens, blockquote exit, HTML author metadata

### Quality & Security
- 117 unit/integration tests + 25 TUI tests
- 57 total bugs fixed (0 remaining)
- Semgrep SAST rules
- Custom ziglint tool
- Daily fuzzing
- Valgrind memory checks

---

*Last updated: 2026-03-19 (Phase 16 complete — 57 bugs fixed, 0 remaining)*
