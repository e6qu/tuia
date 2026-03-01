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

Build `zigpresenterm` (working name: **slidz**), a fast, lightweight terminal presentation tool that:
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
slidz/
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

### Phase 2.4: Theme Engine

**Tasks:**

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 2.4.1 | Theme Struct | Theme data model | 4 |
| 2.4.2 | YAML Parser | Parse theme files | 4 |
| 2.4.3 | Style Application | Apply styles to elements | 6 |
| 2.4.4 | Built-in Themes | Dark and light themes | 4 |
| 2.4.5 | Custom Themes | Load user themes | 4 |

**Acceptance Criteria:**
- Themes apply correctly to all elements
- Invalid theme files produce helpful errors
- Theme switching works at runtime

### Phase 2.5: Navigation & Input

**Tasks:**

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 2.5.1 | Key Binding System | Configurable bindings | 6 |
| 2.5.2 | Navigation | Next/prev/first/last slide | 4 |
| 2.5.3 | Jump to Slide | Direct slide navigation | 2 |
| 2.5.4 | Search | Find text in presentation | 6 |
| 2.5.5 | Modals | Index, help modals | 6 |
| 2.5.6 | Pause Support | Incremental reveals | 4 |

**Acceptance Criteria:**
- All vim-style bindings work
- Modals display correctly
- Search finds and highlights matches

### Phase 2.6: Code Highlighting

**Tasks:**

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 2.6.1 | Syntax Definition | Define highlight rules | 6 |
| 2.6.2 | Tree-sitter Integration | Or custom highlighter | 8 |
| 2.6.3 | 20 Languages | Support top 20 languages | 6 |
| 2.6.4 | Selective Highlight | Line-based highlighting | 4 |
| 2.6.5 | Line Numbers | Optional line numbers | 2 |

**Acceptance Criteria:**
- All test code samples highlight correctly
- Line ranges highlight correctly
- Performance <10ms for 100 lines

---

## Milestone 3: Advanced Features

**Duration:** Weeks 11-16  
**Goal:** Full feature parity with presenterm

### Phase 3.1: Image Support

**Tasks:**

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 3.1.1 | Image Loading | Load PNG/JPEG/GIF | 4 |
| 3.1.2 | Kitty Protocol | Kitty graphics support | 6 |
| 3.1.3 | iTerm2 Protocol | iTerm2 inline images | 6 |
| 3.1.4 | Sixel | Sixel graphics | 6 |
| 3.1.5 | ASCII Fallback | Block character fallback | 2 |
| 3.1.6 | Sizing | Width/height constraints | 4 |

**Acceptance Criteria:**
- Images display in Kitty, iTerm2, WezTerm
- Fallback works in unsupported terminals
- Animated GIFs play

### Phase 3.2: Code Execution

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
| Valgrind | Memory leaks | `valgrind --leak-check=full ./slidz` |
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

*Plan Version: 1.0*  
*Next Review: End of Milestone 1*  
*Status: Draft → Ready for Milestone 0*
