# What We Did

> Chronicle of completed work on TUIA

---

## Milestone 0: Specification ✅

**Duration:** Week 1  
**Status:** Complete

- 17 specification documents created

---

## Milestone 1: Foundation ✅

- Phase 1.1: Project Skeleton ✅
- Phase 1.2: Build System & CI ✅
- Phase 1.3: Testing Framework ✅
- Phase 1.4: Basic TUI Loop ✅

---

## Milestone 2: Core Presentation 🔄

### Phase 2.1: Markdown Parser ✅

**Date:** 2026-03-02

- Token.zig, Scanner.zig, AST.zig, Parser.zig
- Slide splitting, block-level parsing

### Phase 2.2: Slide Model ✅

**Date:** 2026-03-02

- Element.zig, Slide.zig, Presentation.zig
- Core data models with validation

### Phase 2.3: Widget System ✅

**Date:** 2026-03-02

- **Widget.zig**: Base Widget interface with VTable
- **TextWidget.zig**: Paragraph rendering with word wrap
- **HeadingWidget.zig**: Styled headings (bold, underline per level)
- **CodeWidget.zig**: Code blocks with line numbers, dark background
- **SlideWidget.zig**: Complete slide renderer for all element types

### Phase 2.4: Theme Engine ✅

**Date:** 2026-03-02

- **Theme.zig**: Theme data model with Color enum (ANSI + RGB)
  - ElementStyle with fg, bg, bold, italic, underline, strikethrough
  - Built-in dark and light themes
  - vaxis.Color conversion for rendering
- **ThemeLoader.zig**: YAML theme loader
  - Hex color parsing (#RRGGBB)
  - Named color support (16 ANSI colors)
  - Simplified YAML format for theme files

### Phase 2.5: Navigation & Input ✅

**Date:** 2026-03-02

- **Navigation.zig**: Navigation state management
  - Current slide tracking, total slides
  - Help overlay and overview mode toggles
  - Message display with timeout
  - Jump-to-slide functionality
- **KeyBindings.zig**: Configurable keyboard shortcuts
  - vim-style navigation (j/k, h/l, g/G)
  - Arrow keys and space/backspace support
  - Help toggle (?, F1), quit (q, Esc)
- **InputHandler.zig**: Keyboard event processing
  - Jump mode for entering slide numbers
  - Action dispatch to navigation
- **HelpWidget.zig**: Help overlay display
  - Keyboard shortcut reference
  - Centered popup with themed styling
- **StatusBar.zig**: Bottom status display
  - Current slide / total slides
  - Presentation title and messages

---

## Current State

- **Binary:** `tuia` (~2.9MB)
- **Tests:** 35+ passing
- **Build:** Cross-compilation working
- **CI:** All workflows passing

---

## Next Phase

**Phase 2.6: Code Highlighting** - See `DO_NEXT.md`
