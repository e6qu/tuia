# Requirements Specification

> Functional and non-functional requirements for ZIGPRESENTERM.

**Status:** 📝 Draft  
**Owner:** @team  
**Date:** 2026-03-01  
**Related:** [COMPATIBILITY.md](COMPATIBILITY.md), [ARCHITECTURE.md](../architecture/ARCHITECTURE.md)

---

## Table of Contents

1. [Introduction](#introduction)
2. [Functional Requirements](#functional-requirements)
3. [Non-Functional Requirements](#non-functional-requirements)
4. [Constraints](#constraints)
5. [Prioritization](#prioritization)

---

## Introduction

### Purpose

This document specifies the requirements for **ZIGPRESENTERM** (working name: **tuia**), a terminal-based presentation tool written in Zig.

### Scope

- In scope: Terminal presentation rendering from Markdown
- Out of scope: GUI version, collaborative editing, cloud sync

### Definitions

| Term | Definition |
|------|------------|
| **Presentation** | A collection of slides rendered in the terminal |
| **Slide** | A single page of content delimited by separators |
| **Theme** | A collection of visual styling rules |
| **Widget** | A UI component that renders content |
| **Transition** | Animation between slides |

---

## Functional Requirements

### FR-1: Markdown Parsing

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-1.1 | Parse standard CommonMark Markdown | Must |
| FR-1.2 | Support YAML front matter | Must |
| FR-1.3 | Parse slide separators (`<!-- end_slide -->`) | Must |
| FR-1.4 | Support alternative separator (`---` with config) | Should |
| FR-1.5 | Parse code block attributes (`+exec`, `+line_numbers`) | Must |
| FR-1.6 | Parse pause markers (`<!-- pause -->`) | Must |
| FR-1.7 | Parse column layout directives | Should |
| FR-1.8 | Support include directives | Could |

### FR-2: Content Rendering

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-2.1 | Render headings (H1-H6) | Must |
| FR-2.2 | Render paragraphs | Must |
| FR-2.3 | Render emphasis (bold, italic, strikethrough) | Must |
| FR-2.4 | Render inline code | Must |
| FR-2.5 | Render code blocks with syntax highlighting | Must |
| FR-2.6 | Render unordered lists | Must |
| FR-2.7 | Render ordered lists | Must |
| FR-2.8 | Render blockquotes | Must |
| FR-2.9 | Render tables | Should |
| FR-2.10 | Render horizontal rules | Must |
| FR-2.11 | Render hyperlinks | Should |
| FR-2.12 | Render images | Must |
| FR-2.13 | Render LaTeX/math expressions | Could |

### FR-3: Slide Navigation

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-3.1 | Navigate to next slide | Must |
| FR-3.2 | Navigate to previous slide | Must |
| FR-3.3 | Jump to first slide | Must |
| FR-3.4 | Jump to last slide | Must |
| FR-3.5 | Jump to specific slide by number | Must |
| FR-3.6 | Display slide index modal | Should |
| FR-3.7 | Search within presentation | Should |
| FR-3.8 | Support vim-style key bindings (hjkl) | Must |

### FR-4: Theming

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-4.1 | Load themes from YAML files | Must |
| FR-4.2 | Built-in dark theme | Must |
| FR-4.3 | Built-in light theme | Must |
| FR-4.4 | Customize colors (foreground/background) | Must |
| FR-4.5 | Customize fonts (size where supported) | Should |
| FR-4.6 | Customize layout (margins, alignment) | Must |
| FR-4.7 | Customize footer | Should |
| FR-4.8 | Per-element theming (headings, code, etc.) | Should |

### FR-5: Code Features

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-5.1 | Syntax highlighting for 20+ languages | Must |
| FR-5.2 | Line numbers in code blocks | Should |
| FR-5.3 | Selective line highlighting | Should |
| FR-5.4 | Execute code blocks (opt-in) | Should |
| FR-5.5 | Display execution output | Should |
| FR-5.6 | Support 10+ languages for execution | Should |
| FR-5.7 | Hide code lines with `# ` prefix | Should |

### FR-6: Images

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-6.1 | Display images in supported terminals | Must |
| FR-6.2 | Support Kitty graphics protocol | Must |
| FR-6.3 | Support iTerm2 inline images | Must |
| FR-6.4 | Support Sixel | Should |
| FR-6.5 | ASCII fallback for unsupported terminals | Must |
| FR-6.6 | Image sizing (width percentage) | Should |
| FR-6.7 | Animated GIF support | Could |

### FR-7: Layout

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-7.1 | Single-column default layout | Must |
| FR-7.2 | Multi-column layouts | Should |
| FR-7.3 | Content centering | Should |
| FR-7.4 | Automatic text wrapping | Must |
| FR-7.5 | Respect terminal dimensions | Must |

### FR-8: Presentation Features

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-8.1 | Introduction slide from front matter | Must |
| FR-8.2 | Slide titles from headings | Must |
| FR-8.3 | Pause/incremental reveals | Should |
| FR-8.4 | Incremental list reveals | Should |
| FR-8.5 | Speaker notes | Could |
| FR-8.6 | Slide transitions | Could |
| FR-8.7 | Visual grid toggle | Could |

### FR-9: Export

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-9.1 | Export to HTML | Should |
| FR-9.2 | Export to PDF | Should |
| FR-9.3 | Self-contained exports | Should |
| FR-9.4 | Theme applied in exports | Should |

### FR-10: Configuration

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-10.1 | Configuration file support (YAML) | Must |
| FR-10.2 | CLI flags for all options | Must |
| FR-10.3 | Default theme configuration | Must |
| FR-10.4 | Custom key bindings | Should |
| FR-10.5 | Hot reload of configuration | Could |

### FR-11: File Operations

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-11.1 | Load presentation from file | Must |
| FR-11.2 | Hot reload presentation on save | Should |
| FR-11.3 | Load from stdin | Should |
| FR-11.4 | Validate presentation on load | Should |

---

## Non-Functional Requirements

### NFR-1: Performance

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-1.1 | Startup time | < 50ms |
| NFR-1.2 | Slide transition time | < 16ms (60fps) |
| NFR-1.3 | Parse 100 slides | < 100ms |
| NFR-1.4 | Render large slide | < 16ms |
| NFR-1.5 | Memory usage (100 slides) | < 50MB |
| NFR-1.6 | Binary size | < 5MB |

### NFR-2: Compatibility

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-2.1 | Terminal compatibility | VT100+ |
| NFR-2.2 | Image protocol support | Kitty, iTerm2, Sixel |
| NFR-2.3 | OS support (Tier 1) | Linux, macOS |
| NFR-2.4 | OS support (Tier 2) | Windows, FreeBSD |
| NFR-2.5 | Zig version | 0.15.0+ |

### NFR-3: Reliability

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-3.1 | Crash rate | < 0.1% |
| NFR-3.2 | Graceful error handling | 100% of errors |
| NFR-3.3 | Terminal state restoration | Always |
| NFR-3.4 | Memory safety | No leaks (verified) |

### NFR-4: Usability

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-4.1 | Help documentation | Comprehensive |
| NFR-4.2 | Error messages | Clear, actionable |
| NFR-4.3 | Configuration validation | Helpful errors |
| NFR-4.4 | Vim-style bindings | Available |

### NFR-5: Maintainability

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-5.1 | Code coverage | > 80% |
| NFR-5.2 | Documentation coverage | 100% public APIs |
| NFR-5.3 | Testability | All units testable |
| NFR-5.4 | Modularity | Clear boundaries |

### NFR-6: Security

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-6.1 | Code execution | Opt-in only |
| NFR-6.2 | Path traversal | Prevented |
| NFR-6.3 | Resource limits | Enforced |
| NFR-6.4 | Input validation | Strict |

---

## Constraints

### Technical Constraints

- **C1:** Must compile with Zig 0.15.0+
- **C2:** No runtime dependencies (single binary)
- **C3:** Must work without GUI (pure TUI)

### Business Constraints

- **C4:** Open source (AGPL-3.0 license)
- **C5:** Presenterm-compatible where feasible

### Resource Constraints

- **C6:** 20-week development timeline
- **C7:** Small team (1-3 developers)

---

## Prioritization

### MoSCoW Analysis

#### Must Have (MVP)

Core functionality for a usable presentation tool:

1. Parse Markdown with front matter
2. Render basic Markdown (text, headings, lists, code)
3. Syntax highlighting
4. Slide navigation
5. Built-in themes (dark/light)
6. Configuration file
7. CLI interface
8. Help documentation

#### Should Have

Important but not blocking:

1. Images (Kitty/iTerm2)
2. Code execution
3. Column layouts
4. Export to HTML/PDF
5. Hot reload
6. Search
7. 20+ languages for highlighting

#### Could Have

Nice to have:

1. Slide transitions
2. Speaker notes
3. LaTeX math
4. Animated GIFs
5. Custom key bindings
6. Visual grid

#### Won't Have (Out of Scope)

1. GUI version
2. Collaborative editing
3. Cloud storage integration
4. Plugin system (initially)
5. Video playback

---

## Traceability Matrix

| Requirement | Architecture | Implementation | Test |
|-------------|--------------|----------------|------|
| FR-1.1 | Parser module | markdown.zig | parser_test.zig |
| FR-2.1 | Widget system | HeadingWidget.zig | widget_test.zig |
| FR-3.1 | Engine | Engine.zig | engine_test.zig |
| FR-4.1 | Theme system | theme.zig | theme_test.zig |
| FR-6.1 | Image feature | images/ | image_test.zig |

---

## Changelog

- 2026-03-01: Initial requirements specification

---

*Requirements Spec v1.0*
