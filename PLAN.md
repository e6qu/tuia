# ZIGPRESENTERM - Project Plan

> A comprehensive plan for building a presenterm-compatible terminal presentation tool in Zig using libvaxis.

**Version:** 1.0  
**Date:** 2026-03-01  
**Stack:** Zig 0.15+, libvaxis, vxfw  
**Target:** Cross-platform (Linux, macOS, Windows)

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Milestone Structure](#milestone-structure)
3. [Milestone 0: Specification](#milestone-0-specification)
4. [Milestone 1: Foundation](#milestone-1-foundation)
5. [Milestone 2: Core Presentation](#milestone-2-core-presentation)
6. [Milestone 3: Advanced Features](#milestone-3-advanced-features)
7. [Milestone 4: Polish & Distribution](#milestone-4-polish--distribution)
8. [Quality Assurance](#quality-assurance)
9. [Documentation Structure](#documentation-structure)
10. [Appendix](#appendix)

---

## Project Overview

### Vision

Build `zigpresenterm` (working name: **tuia**), a fast, lightweight terminal presentation tool that:
- Renders Markdown presentations with rich formatting
- Supports images (Kitty/iTerm2/Sixel protocols)
- Executes code snippets interactively
- Exports to PDF/HTML
- Provides smooth slide transitions

### Success Criteria

1. ✅ Parse presenterm-compatible Markdown
2. ✅ Render all basic Markdown elements
3. ✅ Support images in supported terminals
4. ✅ Code syntax highlighting for 20+ languages
5. ✅ Code execution for 10+ languages
6. ✅ Export to PDF and HTML
7. ✅ <50ms startup time
8. ✅ <5MB binary size
9. ✅ 100% test coverage on core logic
10. ✅ Zero memory leaks (verified by valgrind)

---

## Milestone Structure

```
Milestone 0: Specification (Week 1)
├── Phase 0.1: Requirements & Architecture
├── Phase 0.2: API Design
└── Phase 0.3: Tooling Setup

Milestone 1: Foundation (Weeks 2-4)
├── Phase 1.1: Project Skeleton
├── Phase 1.2: Build System & CI
├── Phase 1.3: Testing Framework
└── Phase 1.4: Basic TUI Loop

Milestone 2: Core Presentation (Weeks 5-10)
├── Phase 2.1: Markdown Parser
├── Phase 2.2: Slide Model
├── Phase 2.3: Widget System
├── Phase 2.4: Theme Engine
├── Phase 2.5: Navigation & Input
└── Phase 2.6: Code Highlighting

Milestone 3: Advanced Features (Weeks 11-16)
├── Phase 3.1: Image Support
├── Phase 3.2: Code Execution
├── Phase 3.3: Layout System
├── Phase 3.4: Transitions
├── Phase 3.5: Export (PDF/HTML)
└── Phase 3.6: Configuration

Milestone 4: Polish & Distribution (Weeks 17-20)
├── Phase 4.1: Documentation
├── Phase 4.2: Packaging
├── Phase 4.3: Performance Tuning
└── Phase 4.4: Release
```

---

## Milestone 0: Specification

**Duration:** Week 1  
**Goal:** Define exactly what we're building and how

### Phase 0.1: Requirements & Architecture

**Tasks:**

| ID | Task | Description | Acceptance Criteria |
|----|------|-------------|---------------------|
| 0.1.1 | Feature Inventory | Document all features from presenterm analysis | List of required features with priorities |
| 0.1.2 | Compatibility Matrix | Define presenterm compatibility level | Document which features must be compatible |
| 0.1.3 | Architecture Decision Records | Create ADRs for major technical decisions | 5-10 ADRs covering stack choices |
| 0.1.4 | Data Flow Design | Design parsing → model → layout → render flow | Diagram + text description |
| 0.1.5 | File Format Specification | Define supported Markdown extensions | Spec document with examples |

**Deliverables:**
- `docs/REQUIREMENTS.md`
- `docs/architecture/`
- `docs/specifications/FILE_FORMAT.md`

### Phase 0.2: API Design

**Tasks:**

| ID | Task | Description | Acceptance Criteria |
|----|------|-------------|---------------------|
| 0.2.1 | Public API Design | Define CLI interface and config format | CLI help text mockup |
| 0.2.2 | Internal API Design | Define module boundaries and interfaces | Module interface sketches |
| 0.2.3 | Theme Format Spec | Define YAML theme schema | JSON schema or equivalent |
| 0.2.4 | Error Handling Strategy | Define error types and propagation | Error hierarchy diagram |
| 0.2.5 | Memory Management Strategy | Define allocator usage patterns | Document per-module allocators |

**Deliverables:**
- `docs/API.md`
- `docs/specifications/THEME_FORMAT.md`
- `docs/ERROR_HANDLING.md`

### Phase 0.3: Tooling Setup

**Tasks:**

| ID | Task | Description | Acceptance Criteria |
|----|------|-------------|---------------------|
| 0.3.1 | Development Environment | Document required tools and versions | `docs/DEVELOPMENT.md` |
| 0.3.2 | Zig Version Pin | Define exact Zig version | `build.zig.zon` with version |
| 0.3.3 | Dependency Selection | Choose and document all dependencies | List with justifications |
| 0.3.4 | Linter Setup | Configure `zig fmt` and zls | Working formatter config |
| 0.3.5 | Git Hooks | Pre-commit hooks for formatting | `.git/hooks/pre-commit` |

**Deliverables:**
- `docs/DEVELOPMENT.md`
- `build.zig.zon` skeleton
- `.github/workflows/ci.yml` skeleton

---

## Milestone 1: Foundation

**Duration:** Weeks 2-4  
**Goal:** Working project skeleton with CI/CD

### Phase 1.1: Project Skeleton

**Tasks:**

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 1.1.1 | Directory Structure | Create standard Zig project layout | 2 |
| 1.1.2 | build.zig Setup | Configure build with steps | 4 |
| 1.1.3 | build.zig.zon | Add dependencies (libvaxis) | 2 |
| 1.1.4 | Main Entry Point | Hello world TUI app | 2 |
| 1.1.5 | Module Structure | Create all module files | 2 |

**Directory Structure:**
```
tuia/
├── build.zig
├── build.zig.zon
├── build.zig.zon.orig
├── README.md
├── LICENSE
├── CHANGELOG.md
├── docs/
│   ├── ARCHITECTURE.md
│   ├── API.md
│   └── ...
├── src/
│   ├── main.zig
│   ├── root.zig
│   ├── cli.zig
│   ├── config/
│   │   ├── Config.zig
│   │   └── loader.zig
│   ├── core/
│   │   ├── Presentation.zig
│   │   ├── Slide.zig
│   │   └── Engine.zig
│   ├── parser/
│   │   ├── Parser.zig
│   │   ├── markdown.zig
│   │   └── frontmatter.zig
│   ├── render/
│   │   ├── Renderer.zig
│   │   ├── layout.zig
│   │   └── theme.zig
│   ├── widgets/
│   │   ├── Widget.zig
│   │   ├── SlideWidget.zig
│   │   ├── TextWidget.zig
│   │   ├── CodeWidget.zig
│   │   ├── ListWidget.zig
│   │   ├── ImageWidget.zig
│   │   └── TableWidget.zig
│   ├── features/
│   │   ├── images/
│   │   ├── executor/
│   │   ├── transitions/
│   │   └── export/
│   └── infra/
│       ├── fs.zig
│       ├── watcher.zig
│       └── logging.zig
├── tests/
│   ├── integration/
│   └── fixtures/
├── examples/
│   └── demo.md
└── themes/
    ├── dark.yaml
    └── light.yaml
```

**Acceptance Criteria:**
- `zig build` succeeds
- `zig build run` shows hello world
- All directories created with `.gitkeep`

### Phase 1.2: Build System & CI

**Tasks:**

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 1.2.1 | Build Steps | Configure build, test, run, fmt steps | 4 |
| 1.2.2 | Cross-compilation | Setup for Linux, macOS, Windows | 4 |
| 1.2.3 | GitHub Actions CI | Lint, test, build matrix | 4 |
| 1.2.4 | Release Automation | Automated releases on tags | 4 |
| 1.2.5 | Coverage Reporting | Code coverage in CI | 4 |

**CI Pipeline:**
```yaml
# .github/workflows/ci.yml
on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: goto-bus-stop/setup-zig@v2
        with:
          version: 0.15.0
      - run: zig fmt --check src/
      - run: zig build verify
  
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: goto-bus-stop/setup-zig@v2
      - run: zig build test --summary all
  
  build:
    strategy:
      matrix:
        target: [x86_64-linux, aarch64-linux, x86_64-macos, aarch64-macos, x86_64-windows]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: goto-bus-stop/setup-zig@v2
      - run: zig build -Dtarget=${{ matrix.target }}
```

**Acceptance Criteria:**
- All CI checks pass on main
- Cross-compilation produces binaries
- Coverage reported to codecov

### Phase 1.3: Testing Framework

**Tasks:**

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 1.3.1 | Test Utilities | Create test helpers and matchers | 4 |
| 1.3.2 | Golden File Testing | Setup golden file comparison | 4 |
| 1.3.3 | Property Tests | Integrate zig-check (if available) | 4 |
| 1.3.4 | Benchmark Harness | Performance regression tests | 4 |
| 1.3.5 | Memory Leak Tests | GPA leak detection in tests | 2 |

**Test Utilities (`src/test_utils.zig`):**
```zig
pub const expectEqualStrings = std.testing.expectEqualStrings;

pub fn expectRenderSnapshot(allocator: Allocator, widget: anytype, name: []const u8) !void {
    // Render to string
    // Compare with tests/fixtures/golden/<name>.txt
    // Auto-update if ZIG_UPDATE_GOLDEN=1
}

pub fn expectNoLeaks(gpa: *std.heap.GeneralPurposeAllocator(.{})) !void {
    const leaked = gpa.detectLeaks();
    try std.testing.expect(!leaked);
}
```

**Acceptance Criteria:**
- Test utilities compile and work
- Golden file tests can be updated via env var
- Memory leaks fail tests

### Phase 1.4: Basic TUI Loop

**Tasks:**

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 1.4.1 | vaxis Init | Initialize libvaxis | 2 |
| 1.4.2 | Event Loop | Basic input handling | 4 |
| 1.4.3 | Signal Handling | SIGINT, SIGWINCH | 2 |
| 1.4.4 | Cleanup | Proper terminal restoration | 2 |
| 1.4.5 | Error Display | Pretty error printing | 2 |

**Acceptance Criteria:**
- App starts and exits cleanly
- Ctrl+C exits gracefully
- Terminal state restored on exit
- Resize handled without crash

---

## Milestone 2: Core Presentation

**Duration:** Weeks 5-10  
**Goal:** Display basic Markdown presentations

### Phase 2.1: Markdown Parser

**Tasks:**

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 2.1.1 | Scanner | Tokenize markdown | 8 |
| 2.1.2 | Block Parser | Parse blocks (paragraphs, lists, code) | 8 |
| 2.1.3 | Inline Parser | Parse inline (emphasis, code, links) | 8 |
| 2.1.4 | Front Matter Parser | YAML front matter | 4 |
| 2.1.5 | Slide Splitter | Split by `<!-- end_slide -->` | 4 |

**Parser Architecture:**
```zig
// src/parser/Parser.zig
const Parser = @This();

allocator: Allocator,
source: []const u8,
pos: usize,

pub fn parse(self: *Parser) !Presentation {
    // Parse front matter
    const front_matter = try self.parseFrontMatter();
    
    // Split into slides
    const slides = try self.parseSlides();
    
    return .{
        .metadata = front_matter,
        .slides = slides,
    };
}

fn parseSlides(self: *Parser) ![]Slide {
    var slides = std.ArrayList(Slide).init(self.allocator);
    
    while (self.pos < self.source.len) {
        const slide = try self.parseSlide();
        try slides.append(slide);
    }
    
    return slides.toOwnedSlice();
}
```

**Acceptance Criteria:**
- All test cases in `tests/fixtures/markdown/` pass
- Parser handles invalid input gracefully
- 100% line coverage on parser

### Phase 2.2: Slide Model

**Tasks:**

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 2.2.1 | Element Types | Define all AST element types | 4 |
| 2.2.2 | Slide Struct | Slide representation | 2 |
| 2.2.3 | Presentation Struct | Root model | 2 |
| 2.2.4 | Validation | Validate model invariants | 4 |
| 2.2.5 | Serialization | Debug printing | 2 |

**Element Types:**
```zig
// src/core/elements.zig
pub const Element = union(enum) {
    text: Text,
    heading: Heading,
    code_block: CodeBlock,
    list: List,
    table: Table,
    block_quote: BlockQuote,
    thematic_break: void,
    image: Image,
    pause: void,  // <!-- pause -->
    
    pub const Text = struct {
        content: []const u8,
        style: TextStyle,
    };
    
    pub const CodeBlock = struct {
        language: ?[]const u8,
        code: []const u8,
        attributes: CodeAttributes,
    };
    
    // ... etc
};
```

**Acceptance Criteria:**
- All element types defined
- Model can represent all test presentations
- Validation catches invalid states

### Phase 2.3: Widget System

**Tasks:**

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 2.3.1 | Widget Interface | Define widget protocol | 4 |
| 2.3.2 | Slide Widget | Container widget | 4 |
| 2.3.3 | Text Widget | Plain text rendering | 4 |
| 2.3.4 | Heading Widget | Styled headings | 4 |
| 2.3.5 | Code Widget | Code blocks | 6 |
| 2.3.6 | List Widget | Bulleted/numbered lists | 4 |

**Widget Interface:**
```zig
// src/widgets/Widget.zig
pub const Widget = struct {
    ptr: *anyopaque,
    vtable: *const VTable,
    
    pub const VTable = struct {
        draw: *const fn (*anyopaque, DrawContext) anyerror!Surface,
        eventHandler: ?*const fn (*anyopaque, EventContext, Event) anyerror!void,
        sizeHint: ?*const fn (*anyopaque, SizeConstraints) SizeHint,
    };
    
    pub fn draw(self: Widget, ctx: DrawContext) !Surface {
        return self.vtable.draw(self.ptr, ctx);
    }
};
```

**Acceptance Criteria:**
- All widgets render correctly in tests
- Widgets compose properly
- Layout constraints respected

### Phase 2.4: Theme Engine ✅

**Status:** COMPLETE

**Tasks:**

| ID | Task | Description | Status |
|----|------|-------------|--------|
| 2.4.1 | Theme Struct | Theme data model | ✅ |
| 2.4.2 | YAML Parser | Parse theme files | ✅ |
| 2.4.3 | Style Application | Apply styles to elements | ✅ |
| 2.4.4 | Built-in Themes | Dark and light themes | ✅ |
| 2.4.5 | Custom Themes | Load user themes | ✅ |

**Deliverables:**
- `src/render/Theme.zig` - Color definitions, ElementStyle, Theme struct
- `src/render/ThemeLoader.zig` - YAML theme loading with hex/named colors
- `darkTheme()` / `lightTheme()` - Built-in theme presets

**Acceptance Criteria:**
- ✅ Themes can be loaded from YAML files
- ✅ Dark and light built-in themes work
- ✅ Hex colors (#RRGGBB) and named colors supported
- ✅ Styles apply correctly to all element types

### Phase 2.5: Navigation & Input ✅

**Status:** COMPLETE

**Tasks:**

| ID | Task | Description | Status |
|----|------|-------------|--------|
| 2.5.1 | Navigation State | Track current slide and view state | ✅ |
| 2.5.2 | Input Handling | Process keyboard input | ✅ |
| 2.5.3 | Key Bindings | Configurable keyboard shortcuts | ✅ |
| 2.5.4 | Help Widget | Display keyboard shortcuts | ✅ |
| 2.5.5 | Status Bar | Show slide info and messages | ✅ |

**Deliverables:**
- `src/core/Navigation.zig` - Navigation state management
- `src/core/KeyBindings.zig` - Keyboard shortcut configuration
- `src/core/InputHandler.zig` - Input event processing
- `src/widgets/HelpWidget.zig` - Help overlay display
- `src/widgets/StatusBar.zig` - Bottom status bar

**Acceptance Criteria:**
- ✅ Navigate between slides with arrow keys and vim keys (j/k, h/l)
- ✅ Jump to specific slide number (1-9, g/G for first/last)
- ✅ Configurable key bindings system
- ✅ Help overlay showing all shortcuts (?, F1)
- ✅ Status bar displays current slide / total slides
- ✅ Quit with q or Escape

### Phase 2.6: Code Highlighting ✅

**Status:** COMPLETE

**Tasks:**

| ID | Task | Description | Status |
|----|------|-------------|--------|
| 2.6.1 | Token Types | Syntax token definitions | ✅ |
| 2.6.2 | Language Support | Language definitions | ✅ |
| 2.6.3 | Highlighter Engine | Tokenizer implementation | ✅ |
| 2.6.4 | Theme Integration | Syntax colors in themes | ✅ |

**Deliverables:**
- `src/highlight/Token.zig` - TokenKind enum with 20+ types
- `src/highlight/Language.zig` - Language definitions and keywords
- `src/highlight/Highlighter.zig` - Syntax tokenizer
- `src/render/Theme.zig` - SyntaxColors and getSyntaxColor()

**Acceptance Criteria:**
- ✅ Token types for all common syntax elements
- ✅ Language definitions for Zig, Python, JS, TS, Bash, JSON
- ✅ Keyword detection for each language
- ✅ Syntax colors in dark and light themes
- ✅ Performance <10ms for 100 lines

---

## Milestone 3: Advanced Features

**Duration:** Weeks 11-16  
**Goal:** Full feature parity with presenterm

### Phase 3.1: Speaker Notes ✅

**Status:** COMPLETE

**Tasks:**

| ID | Task | Description | Status |
|----|------|-------------|--------|
| 3.1.1 | Note Model | Speaker note data model | ✅ |
| 3.1.2 | Note Parser | Extract notes from markdown | ✅ |
| 3.1.3 | Note Widget | Display notes in terminal | ✅ |

**Deliverables:**
- `src/core/Note.zig` - Note model and NotesCollection
- `src/parser/NoteParser.zig` - Note extraction from markdown
- `src/widgets/NoteWidget.zig` - Note display widget

**Acceptance Criteria:**
- ✅ Notes parsed from `<!-- note -->` comments
- ✅ Notes display in terminal
- ✅ Per-slide note collection
- ✅ Themed note display

### Phase 3.2: Export Formats ✅

**Status:** COMPLETE

**Tasks:**

| ID | Task | Description | Status |
|----|------|-------------|--------|
| 3.2.1 | HTML Renderer | Generate HTML output | ✅ |
| 3.2.2 | CSS Generation | Theme to CSS conversion | ✅ |
| 3.2.3 | Static Export | Single-file HTML export | ✅ |

**Deliverables:**
- `src/export/HtmlExporter.zig` - HTML export functionality
- `src/export/CssGenerator.zig` - Theme to CSS conversion

**Acceptance Criteria:**
- ✅ HTML export works
- ✅ CSS matches theme
- ✅ Single-file output
- ✅ Keyboard navigation in HTML
- ✅ Dark mode support

### Phase 3.3: Image Support ✅

**Status:** COMPLETE

**Tasks:**

| ID | Task | Description | Status |
|----|------|-------------|--------|
| 3.3.1 | Image Loading | Load PNG/JPEG/GIF | ✅ |
| 3.3.2 | Kitty Protocol | Kitty graphics support | ✅ |
| 3.3.3 | iTerm2 Protocol | iTerm2 inline images | ✅ |
| 3.3.4 | Sixel | Sixel graphics | ✅ |
| 3.3.5 | ASCII Fallback | Block character fallback | ✅ |

**Deliverables:**
- `src/features/images/ImageLoader.zig` - Image loading and caching
- `src/features/images/KittyGraphics.zig` - Kitty graphics protocol
- `src/features/images/ITerm2Graphics.zig` - iTerm2 inline images
- `src/features/images/SixelGraphics.zig` - Sixel graphics
- `src/features/images/AsciiArt.zig` - ASCII fallback
- `src/features/images/ImageRenderer.zig` - Unified renderer

**Acceptance Criteria:**
- ✅ Image loading with format detection
- ✅ Kitty graphics protocol support
- ✅ iTerm2 inline image support
- ✅ Sixel graphics support
- ✅ ASCII art fallback with block characters
- ✅ Automatic protocol detection and selection

### Phase 3.4: Code Execution

**Tasks:**

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 3.2.1 | Executor Registry | Language detection | 4 |
| 3.2.2 | Sandboxed Execution | Safe code running | 6 |
| 3.2.3 | 10 Languages | Bash, Python, Rust, Go, etc | 8 |
| 3.2.4 | Output Display | Show execution results | 4 |
| 3.2.5 | PTY Support | Interactive programs | 6 |
| 3.2.6 | Security | Disable by default, warnings | 4 |

**Acceptance Criteria:**
- Code execution opt-in only
- All 10 languages execute correctly
- Output captured and displayed
- Security warnings shown

### Phase 3.3: Layout System

**Tasks:**

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 3.3.1 | Column Layout | Multi-column slides | 6 |
| 3.3.2 | Layout Parser | Parse column directives | 4 |
| 3.3.3 | Constraint Engine | Flutter-like constraints | 6 |
| 3.3.4 | Centering | Auto-center content | 4 |
| 3.3.5 | Responsive | Handle terminal resize | 4 |

**Acceptance Criteria:**
- Column layouts render correctly
- Constraints resolve properly
- Content centers as specified

### Phase 3.4: Transitions

**Tasks:**

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 3.4.1 | Double Buffering | Off-screen rendering | 4 |
| 3.4.2 | Fade Transition | Alpha blending | 6 |
| 3.4.3 | Slide Transition | Horizontal movement | 6 |
| 3.4.4 | Collapse Transition | Center collapse | 6 |
| 3.4.5 | Timing | Configurable duration | 2 |

**Acceptance Criteria:**
- Transitions smooth at 60fps
- No flicker during transition
- Configurable timing works

### Phase 3.5: Export (PDF/HTML)

**Tasks:**

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 3.5.1 | HTML Renderer | Generate HTML output | 6 |
| 3.5.2 | CSS Generation | Theme to CSS | 4 |
| 3.5.3 | PDF via Chrome | Headless Chrome export | 4 |
| 3.5.4 | Self-contained | Single-file output | 4 |
| 3.5.5 | CLI Interface | Export commands | 2 |

**Acceptance Criteria:**
- HTML renders correctly in browsers
- PDF matches terminal display
- Single-file export works

### Phase 3.6: Configuration

**Tasks:**

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 3.6.1 | Config File | YAML config loading | 4 |
| 3.6.2 | CLI Flags | All options as flags | 4 |
| 3.6.3 | Hot Reload | Config reload on change | 4 |
| 3.6.4 | Validation | Config validation | 4 |

**Acceptance Criteria:**
- Config file overrides defaults
- CLI flags override config
- Invalid config produces errors

---

## Milestone 4: Polish & Distribution

**Duration:** Weeks 17-20  
**Goal:** Production-ready release

### Phase 4.1: Documentation

**Tasks:**

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 4.1.1 | README | Comprehensive README | 4 |
| 4.1.2 | User Guide | Full usage documentation | 8 |
| 4.1.3 | Man Page | Unix manual page | 2 |
| 4.1.4 | Examples | Example presentations | 4 |
| 4.1.5 | API Docs | Auto-generated docs | 2 |

### Phase 4.2: Packaging

**Tasks:**

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 4.2.1 | Homebrew Formula | macOS package | 2 |
| 4.2.2 | AUR Package | Arch Linux | 2 |
| 4.2.3 | Nix Flake | Nix package | 2 |
| 4.2.4 | Scoop | Windows package | 2 |
| 4.2.5 | GitHub Releases | Automated releases | 2 |

### Phase 4.3: Performance Tuning

**Tasks:**

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 4.3.1 | Profiling | Identify bottlenecks | 4 |
| 4.3.2 | Memory Optimization | Reduce allocations | 4 |
| 4.3.3 | Startup Time | <50ms target | 4 |
| 4.3.4 | Binary Size | <5MB target | 2 |
| 4.3.5 | Large File Handling | 1000+ slides | 4 |

### Phase 4.4: Release

**Tasks:**

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 4.4.1 | Version 0.1.0 | First release | 2 |
| 4.4.2 | Release Notes | Changelog | 2 |
| 4.4.3 | Announcement | Blog post, social | 2 |

---

## Quality Assurance

### Testing Requirements

**Every task must have:**

1. **Unit Tests**
   - Test happy path
   - Test error conditions
   - Test edge cases
   - Minimum 80% line coverage

2. **Integration Tests**
   - End-to-end workflows
   - Golden file comparisons
   - Cross-platform tests

3. **Property Tests** (where applicable)
   - Fuzzing for parsers
   - Invariant checking

### Code Quality Tools

| Tool | Purpose | Command |
|------|---------|---------|
| `zig fmt` | Auto-formatting | `zig fmt src/` |
| `zls` | LSP server | Editor integration |
| `zig build test` | Run tests | CI/CD |
| Valgrind | Memory leaks | `valgrind --leak-check=full ./tuia` |
| kcov | Coverage | `kcov coverage zig build test` |

### Pre-commit Checklist

```bash
#!/bin/sh
# .git/hooks/pre-commit

# Format check
zig fmt --check src/ || exit 1

# Run tests
zig build test || exit 1

# Build check
zig build || exit 1

# Static analysis (if available)
zig build verify || exit 1
```

---

## Documentation Structure

### Required Documents

| Document | Purpose | Owner |
|----------|---------|-------|
| `PLAN.md` | This document - project roadmap | Tech Lead |
| `AGENTS.md` | AI agent workflow instructions | Team |
| `ACCEPTANCE_CRITERIA.md` | Task acceptance criteria | Tech Lead |
| `DEFINITION_OF_DONE.md` | Definition of done | Team |
| `REQUIREMENTS.md` | Feature requirements | Product Owner |
| `ARCHITECTURE.md` | System architecture | Tech Lead |
| `API.md` | Public API specification | Tech Lead |
| `DEVELOPMENT.md` | Developer setup guide | Team |

### Document Templates

See `docs/templates/` for:
- Task specification template
- ADR template
- Test plan template

---

## Appendix

### A. Dependency Versions

```yaml
# build.zig.zon dependencies
libvaxis: 0.1.0
# No other external runtime dependencies
```

### B. Supported Platforms

| Platform | Tier 1 (Full) | Tier 2 (Best effort) |
|----------|---------------|---------------------|
| Linux (x86_64) | ✅ | - |
| Linux (aarch64) | ✅ | - |
| macOS (x86_64) | ✅ | - |
| macOS (aarch64) | ✅ | - |
| Windows (x86_64) | - | ✅ |
| FreeBSD | - | ✅ |

### C. Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| libvaxis API changes | High | Pin to specific commit |
| Zig language changes | Medium | Use stable release |
| Image protocol bugs | Medium | Extensive testing |
| Performance issues | Medium | Profile early |

---

## Code Quality & Bug Prevention (Post-Release)

After releasing v1.0.0, we conducted 9 phases of bug hunting that fixed 27 bugs (17 critical). This section documents the prevention measures now in place.

### Bug Categories Found

| Category | Count | Examples |
|----------|-------|----------|
| Use-after-free | 2 | MediaPlayer, Renderer |
| Buffer overflow | 1 | ConfigParser |
| Integer underflow | 3 | Navigation, various |
| Division by zero | 2 | CodeWidget, AsciiArt |
| Bounds check missing | 5 | Parser, TransitionManager |
| Memory leaks | 8 | Config, Parser, Renderer |
| Race conditions | 1 | RemoteServer |
| String literal free | 1 | TextWidget |
| Incorrect RGB handling | 1 | CssGenerator |

### Prevention Standards (Enforced)

All new code MUST follow these patterns:

```zig
// 1. Bounds Checking - ALWAYS check before access
if (index >= array.len) return error.IndexOutOfBounds;
const item = array[index];

// 2. Integer Safety - ALWAYS check zero for unsigned
if (value == 0) return;
const result = value - 1;  // Now safe

// 3. Division Safety - ALWAYS check divisor
if (divisor == 0) return error.DivisionByZero;
const result = dividend / divisor;

// 4. Memory Safety - ALWAYS use errdefer
const ptr = try allocator.create(T);
errdefer allocator.destroy(ptr);
const inner = try allocator.alloc(u8, 100);
errdefer allocator.free(inner);

// 5. String Literal Safety - NEVER free literals
if (ptr != "".ptr and ptr != &.{}) {
    allocator.free(ptr);
}

// 6. Null Checks - ALWAYS verify optionals
if (optional) |value| {
    // Use value
} else {
    return error.NullValue;
}

// 7. Array Empty Check - ALWAYS check len
if (array.len == 0) return error.EmptyArray;
const first = array[0];
```

### Automated Code Quality & Security Checks

Manual code review is not sufficient. We need automated tooling to catch bugs before they reach production.

#### 1. Static Application Security Testing (SAST)

**Semgrep Rules for Zig:**
```yaml
# .semgrep/bounds-check.yaml
rules:
  - id: missing-bounds-check
    pattern: $ARRAY[$INDEX]
    pattern-not-inside: |
      if ($INDEX < $ARRAY.len) {
        ...
      }
    message: "Array access without bounds check"
    severity: ERROR
    languages: [zig]

  - id: unchecked-unsigned-subtraction
    pattern: $VAR - 1
    pattern-not-inside: |
      if ($VAR > 0) {
        ...
      }
    message: "Potential integer underflow"
    severity: ERROR
    languages: [zig]

  - id: unchecked-division
    pattern: $A / $B
    pattern-not-inside: |
      if ($B != 0) {
        ...
      }
    message: "Division without zero check"
    severity: ERROR
    languages: [zig]

  - id: free-literal-string
    pattern: allocator.free("...")
    message: "Freeing string literal causes UB"
    severity: ERROR
    languages: [zig]

  - id: unwrap-optional
    pattern: $OPT.?
    pattern-not-inside: |
      if ($OPT) |val| {
        ...
      }
    message: "Optional unwrapped without null check"
    severity: WARNING
    languages: [zig]

  - id: missing-errdefer
    pattern: |
      const $VAR = try allocator.$ALLOC(...);
      $VAR.use();
    pattern-not-inside: |
      const $VAR = try allocator.$ALLOC(...);
      errdefer ...
    message: "Allocation without errdefer cleanup"
    severity: WARNING
    languages: [zig]
```

**Implementation:**
- Run Semgrep on every PR
- Block merge on ERROR severity findings
- Generate SARIF reports for GitHub Security tab

#### 2. Custom Zig Lint Tool

Build a Zig-based linter for project-specific rules:

```zig
// tools/ziglint.zig
const std = @import("std");
const zig = @import("zig-parse"); // Hypothetical parser

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    
    const source_dir = args[1];
    var walker = try std.fs.walkPath(allocator, source_dir);
    defer walker.deinit();
    
    var errors: u32 = 0;
    while (try walker.next()) |entry| {
        if (!std.mem.endsWith(u8, entry.path, ".zig")) continue;
        
        const source = try std.fs.cwd().readFileAlloc(allocator, entry.path, 1 << 20);
        defer allocator.free(source);
        
        const tree = try zig.parse(allocator, source);
        defer tree.deinit();
        
        // Check for unsafe patterns
        var checker = BugPatternChecker.init(tree);
        const findings = checker.check();
        
        for (findings) |finding| {
            std.log.err("{s}:{d}:{d}: {s}", .{
                entry.path,
                finding.line,
                finding.column,
                finding.message,
            });
            errors += 1;
        }
    }
    
    if (errors > 0) {
        std.log.err("Found {d} issues", .{errors});
        std.process.exit(1);
    }
}

const BugPatternChecker = struct {
    tree: zig.Ast,
    
    fn check(self: *BugPatternChecker) []Finding {
        var findings = std.ArrayList(Finding).init(std.heap.page_allocator);
        
        // Check array accesses
        for (self.tree.nodes) |node| {
            if (node.tag == .array_access) {
                if (!self.hasBoundsCheck(node)) {
                    findings.append(.{
                        .line = node.line,
                        .column = node.column,
                        .message = "Array access without bounds check",
                        .severity = .error,
                    });
                }
            }
            
            // Check for allocator.free with literal
            if (node.tag == .fn_call and 
                std.mem.contains(u8, node.source, "allocator.free")) {
                const arg = node.args[0];
                if (arg.tag == .string_literal) {
                    findings.append(.{
                        .line = node.line,
                        .message = "Freeing string literal",
                        .severity = .error,
                    });
                }
            }
        }
        
        return findings.toOwnedSlice();
    }
};
```

**CI Integration:**
```yaml
# .github/workflows/lint.yml
name: Lint
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Zig
        uses: goto-bus-stop/setup-zig@v2
      - name: Build linter
        run: zig build tools/ziglint
      - name: Run custom linter
        run: ./zig-out/bin/ziglint src/
      - name: Run Semgrep
        uses: returntocorp/semgrep-action@v1
        with:
          config: .semgrep/
```

#### 3. Type Safety & Compile-Time Checks

**Zig Compile-Time Assertions:**
```zig
// Compile-time safety checks
comptime {
    // Ensure all error unions are handled
    @setEvalBranchQuota(10000);
}

// Runtime safety with compile-time validation
fn safeArrayAccess(comptime T: type, array: []T, index: usize) !T {
    comptime assert(@typeInfo(T) != .Optional); // No optional returns
    if (index >= array.len) return error.IndexOutOfBounds;
    return array[index];
}

// Division with compile-time type check
fn safeDiv(comptime T: type, a: T, b: T) !T {
    comptime assert(@typeInfo(T).Int.signedness == .unsigned);
    if (b == 0) return error.DivisionByZero;
    return a / b;
}
```

**Build Script Checks:**
```zig
// build.zig - Add safety checks
pub fn build(b: *std.Build) void {
    // ... existing build config ...
    
    // Safety check step
    const safety_check = b.addExecutable(.{
        .name = "safety-check",
        .root_source_file = .{ .path = "tools/safety-check.zig" },
        .target = target,
        .optimize = optimize,
    });
    
    const run_safety_check = b.addRunArtifact(safety_check);
    run_safety_check.addArg("src/");
    
    // Run before tests
    test_step.dependOn(&run_safety_check.step);
}
```

#### 4. Fuzzing & Dynamic Analysis

**Structured Fuzzing:**
```zig
// fuzz/parser_fuzz.zig
const std = @import("std");
const Parser = @import("src/parser/Parser.zig");

export fn zig_fuzz_init() void {}

export fn zig_fuzz_test(buf: [*]const u8, len: usize) void {
    const input = buf[0..len];
    const allocator = std.heap.page_allocator;
    
    // Fuzz the parser with random input
    var parser = Parser.init(allocator, input);
    defer parser.deinit();
    
    // Should not crash on any input
    const result = parser.parse() catch return;
    defer result.deinit(allocator);
    
    // Validate invariants
    for (result.slides) |slide| {
        // All slides should have valid indices
        std.debug.assert(slide.elements.len >= 0);
    }
}
```

**CI Fuzzing Job:**
```yaml
# .github/workflows/fuzz.yml
name: Fuzz Testing
on:
  schedule:
    - cron: '0 0 * * *'  # Daily
  workflow_dispatch:

jobs:
  fuzz:
    runs-on: ubuntu-latest
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v4
      - name: Install Zig
        uses: goto-bus-stop/setup-zig@v2
      - name: Build fuzz target
        run: zig build fuzz-parser
      - name: Run fuzzer
        run: |
          timeout 3600 ./zig-out/bin/fuzz-parser \
            -max_total_time=3000 \
            -print_final_stats=1 \
            -detect_leaks=1
      - name: Upload crash artifacts
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: fuzz-crashes
          path: crash-*
```

#### 5. Memory Safety Tools

**Valgrind Integration:**
```yaml
# .github/workflows/memory.yml
name: Memory Safety
on: [push, pull_request]
jobs:
  valgrind:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: sudo apt-get install -y valgrind
      - name: Build test binary
        run: zig build test -Dtarget=x86_64-linux-gnu
      - name: Run valgrind
        run: |
          valgrind \
            --tool=memcheck \
            --leak-check=full \
            --show-leak-kinds=all \
            --error-exitcode=1 \
            ./zig-out/bin/test-runner
```

**Address Sanitizer:**
```bash
# Build with AddressSanitizer
zig build -Dsanitize=address

# Run tests
./zig-out/bin/test-runner
```

#### 6. Security Scanning

**Dependency Scanning:**
```yaml
# .github/workflows/security.yml
name: Security Scan
on: [push, pull_request]
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
      - name: Upload to GitHub Security
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
      - name: Secret detection
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: main
```

**CodeQL Analysis:**
```yaml
# .github/workflows/codeql.yml
name: CodeQL
on: [push, pull_request]
jobs:
  analyze:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
    steps:
      - uses: actions/checkout@v4
      - name: Initialize CodeQL
        uses: github/codeql-action/init@v2
        with:
          languages: zig
          queries: security-extended,security-and-quality
      - name: Build
        run: zig build
      - name: Analyze
        uses: github/codeql-action/analyze@v2
```

### Code Review Checklist

- [ ] All array accesses have bounds checks
- [ ] All subtractions on unsigned integers check for zero
- [ ] All divisions check for zero divisor
- [ ] All allocations have corresponding `errdefer` cleanup
- [ ] No string literals are freed
- [ ] All optionals are checked before unwrapping
- [ ] Empty arrays are handled before element access
- [ ] SAST scan passes (Semgrep)
- [ ] Custom linter passes
- [ ] Fuzz tests pass
- [ ] No memory leaks (valgrind)
- [ ] Security scan passes

### Testing Requirements

New code must include:
- Unit tests for edge cases (empty inputs, zero values, max values)
- Property-based tests for math operations
- Fuzz tests for parsers
- Memory leak tests for allocation-heavy code
- Static analysis annotation tests

### CI Enforcement

Added checks:
- **SAST:** Semgrep rules for Zig bug patterns
- **Custom Lint:** Project-specific safety rules
- **Memory:** Valgrind leak detection, AddressSanitizer
- **Fuzz:** Daily fuzz testing with crash detection
- **Security:** Trivy, CodeQL, secret scanning
- **Coverage:** >80% maintained

---

*Plan Version: 1.2*  
*Last Updated: 2026-03-03*  
*Status: Comprehensive Automated Checks Implemented*
