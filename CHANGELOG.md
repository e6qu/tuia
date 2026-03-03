# Changelog

All notable changes to TUIA are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-04

### Added

- Markdown parser with front matter support
- Widget system (Text, Heading, Code, List, Table, Image, Slide widgets)
- Theme engine (dark/light themes, custom YAML themes)
- vim-style navigation with jump-to-slide
- Syntax highlighting for 10+ languages
- Speaker notes (`<!-- note -->` syntax)
- HTML export with keyboard navigation
- Image display (Kitty, iTerm2, Sixel, ASCII protocols)
- Code execution (8 languages with sandboxing)
- YAML configuration with CLI overrides

### Security & Quality

- Semgrep SAST (bounds, integer, memory, null safety rules)
- Custom ziglint tool for AST-based pattern detection
- Fuzzing infrastructure with libFuzzer
- Valgrind memory leak detection in CI
- Trivy dependency vulnerability scanning
- TruffleHog secret detection

### Fixed

- 27 bugs fixed (17 critical, 6 high, 4 medium/low)
- Use-after-free, buffer overflows, integer underflows
- Memory leaks, race conditions, bounds check issues

### Technical

- Zig 0.15.2
- Cross-compilation for 5 targets
- ~3MB binary size
- 117 tests, >80% coverage
- 30+ CI checks

[1.0.0]: https://github.com/e6qu/tuia/releases/tag/v1.0.0
