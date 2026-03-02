# Changelog

All notable changes to TUIA will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-02

### Added

#### Core Features
- **Markdown Parser** - Full Markdown parsing with slide separation
- **Slide Model** - Hierarchical presentation structure with elements
- **Widget System** - Modular UI components (Text, Heading, Code, Slide widgets)
- **Theme Engine** - Dark/light themes with custom theme support
- **Navigation & Input** - vim-style key bindings, jump mode, help system
- **Code Highlighting** - Syntax highlighting for 10+ languages

#### Advanced Features
- **Speaker Notes** - Hidden notes for presenters (`<!-- note -->` syntax)
- **Export Formats** - Self-contained HTML export with navigation
- **Image Support** - Kitty, iTerm2, Sixel, and ASCII art protocols
- **Code Execution** - Run code blocks in 8 languages with sandboxing
- **Configuration System** - YAML config with CLI overrides

#### Documentation
- Comprehensive User Guide (7,000+ words)
- API Reference for library users
- Example presentations (demo, tutorial, cheatsheet)
- Updated README with quick start

### Technical

- Zig 0.15.2 compatibility
- Cross-compilation for 5 targets (Linux, macOS, Windows)
- ~3MB binary size
- 70+ unit tests
- CI/CD with GitHub Actions

[1.0.0]: https://github.com/e6qu/tuia/releases/tag/v1.0.0
