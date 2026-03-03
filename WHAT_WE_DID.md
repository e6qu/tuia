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

### Quality & Security
- 117 tests, >80% coverage
- Semgrep SAST rules
- Custom ziglint tool
- Daily fuzzing
- Valgrind memory checks
- 0 open bugs

---

*Version 1.0.0 - March 2026*
