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

### Phase 2.6: Code Highlighting ✅

**Date:** 2026-03-02

- **Token.zig**: Token types for syntax highlighting
  - TokenKind enum with 20+ token types
  - Default color mapping for each token kind
- **Language.zig**: Language definitions
  - Support for Zig, Python, JavaScript, TypeScript, Bash, JSON
  - Language detection from file extension and markdown tags
  - Keyword sets for each language
- **Highlighter.zig**: Syntax highlighting engine
  - Tokenizer for supported languages
  - Comment, string, number, keyword, identifier recognition
- **Theme Integration**:
  - SyntaxColors struct for code highlighting
  - Dark and light theme syntax color presets
  - getSyntaxColor() method on Theme

---

## Milestone 3: Advanced Features 🔄

### Phase 3.1: Speaker Notes ✅

**Date:** 2026-03-02

- **Note.zig**: Speaker note model
  - Note struct with content storage
  - NotesCollection for managing notes per slide
- **NoteParser.zig**: Parser for extracting notes from markdown
  - Support for `<!-- note: ... -->` syntax
  - Support for `<!-- note --> ... <!-- endnote -->` syntax
  - Per-slide note extraction
- **NoteWidget.zig**: Widget for displaying speaker notes
  - Themed note display with border
  - Word-wrapped content rendering
  - Empty state handling

### Phase 3.2: Export Formats ✅

**Date:** 2026-03-02

- **HtmlExporter.zig**: HTML export functionality
  - Full presentation to HTML conversion
  - All element types supported (headings, paragraphs, code, lists, etc.)
  - exportToHtml() and exportToFile() methods
- **CssGenerator.zig**: Theme to CSS conversion
  - Converts theme colors to CSS
  - Responsive slide styling
  - Dark mode support via media queries
- **Features**:
  - Self-contained HTML files
  - Keyboard navigation (arrow keys, space)
  - Scroll-snap for slide transitions
  - Print-friendly CSS

### Phase 3.3: Image Support ✅

**Date:** 2026-03-02

- **ImageLoader.zig**: Image loading and caching
  - Support for PNG, JPEG, GIF, BMP formats
  - Format detection from magic bytes
  - LRU cache for loaded images
- **KittyGraphics.zig**: Kitty graphics protocol
  - Full Kitty terminal graphics support
  - Base64-encoded image data
  - Image placement options
- **ITerm2Graphics.zig**: iTerm2 inline images
  - iTerm2 image protocol support
  - WezTerm compatibility
  - Dimension controls
- **SixelGraphics.zig**: Sixel graphics
  - Sixel protocol implementation
  - 6-pixel vertical encoding
  - Color palette support
- **AsciiArt.zig**: ASCII fallback
  - Luminance-based ASCII conversion
  - Unicode block character mode
  - Configurable dimensions
- **ImageRenderer.zig**: Unified renderer
  - Automatic protocol detection
  - Fallback chain: Kitty → iTerm2 → Sixel → ASCII

---

## Current State

- **Binary:** `tuia` (~2.9MB)
- **Tests:** 55+ passing
- **Build:** Cross-compilation working
- **CI:** All workflows passing

---

## Next Phase

**Phase 3.4: Code Execution** - See `DO_NEXT.md`
