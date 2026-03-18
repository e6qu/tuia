# Changelog

All notable changes to TUIA are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Pre-commit hooks (zig fmt, lint, unit tests) via `.pre-commit-config.yaml`
- `TUIA_TTY_FD` env var for pty-based TUI testing
- 25 automated TUI tests using `expect` (`scripts/test_tui.exp`)
- `<meta name="author">` in HTML export

### Fixed

- TUI-1: Terminal reads from pty when `TUIA_TTY_FD` is set
- TUI-2: Blockquote no longer swallows `---` slide separators
- TUI-3: List items correctly grouped (resolved by TUI-2 fix)
- TUI-4: Heading token includes full line text
- TUI-5: HTML export includes author metadata

### Removed

- Windows cross-compilation targets (Terminal requires POSIX)

## [1.0.0] - 2026-03-04

### Added

- Markdown parser with front matter support
- Widget system (Text, Heading, Code, List, Table, Image, Slide widgets)
- Theme engine (dark/light themes, custom YAML themes)
- vim-style navigation with jump-to-slide
- Syntax highlighting for 10+ languages
- Speaker notes (`<!-- note -->` syntax)
- Export: HTML, Reveal.js, Beamer/LaTeX, PDF
- Image display (Kitty, iTerm2, Sixel, ASCII protocols)
- Code execution (8 languages with sandboxing)
- YAML configuration with CLI overrides
- Custom POSIX TUI layer with fixed-memory, zero-allocation rendering

### Security & Quality

- Semgrep SAST (bounds, integer, memory, null safety rules)
- Custom ziglint tool for AST-based pattern detection
- Fuzzing infrastructure with libFuzzer
- Valgrind memory leak detection in CI
- Trivy dependency vulnerability scanning
- TruffleHog secret detection

### Fixed

- 57 bugs fixed across 16 phases
- Use-after-free, buffer overflows, integer underflows
- Memory leaks, race conditions, bounds check issues
- Parser, renderer, and exporter correctness fixes

### Technical

- Zig 0.15.2
- Cross-compilation for Linux and macOS (x86_64, aarch64)
- ~3MB binary size
- 117 unit/integration tests + 25 TUI tests
- 30+ CI checks

[1.0.0]: https://github.com/e6qu/tuia/releases/tag/v1.0.0
