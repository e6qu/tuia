# Architecture Specification

> High-level architecture for ZIGPRESENTERM.

**Status:** 📝 Draft  
**Owner:** @team  
**Date:** 2026-03-01  
**Related:** [../requirements/REQUIREMENTS.md](../requirements/REQUIREMENTS.md), [COMPONENTS.md](COMPONENTS.md)

---

## Overview

ZIGPRESENTERM follows a layered architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────────┐
│                        Presentation Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │     CLI     │  │   Export    │  │    Configuration        │  │
│  │   (main)    │  │ (PDF/HTML)  │  │    (config files)       │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘  │
└─────────┼────────────────┼─────────────────────┼────────────────┘
          │                │                     │
          ▼                ▼                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Core Layer                               │
│  ┌─────────────────────────────────────────────────────────┐     │
│  │                    Presentation Engine                   │     │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │     │
│  │  │   Parser    │──▶│    Model    │──▶│     Layout      │  │     │
│  │  │  (Markdown) │  │ (AST/Slides)│  │  (Constraints)  │  │     │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘  │     │
│  └─────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Rendering Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Widgets   │  │   Theme     │  │    Terminal (libvaxis)  │  │
│  │  (UI comp)  │  │  (Styling)  │  │    (Output)             │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Infrastructure Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Events    │  │    FS       │  │       Logging           │  │
│  │  (Input)    │  │  (Watch)    │  │                         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Architectural Principles

### 1. Separation of Concerns

Each layer has a single responsibility:
- **Presentation:** User interface (CLI, config)
- **Core:** Business logic (parsing, modeling, layout)
- **Rendering:** Visual output (widgets, themes, terminal)
- **Infrastructure:** Cross-cutting concerns (I/O, logging)

### 2. Dependency Direction

Dependencies flow downward:
```
Presentation → Core → Rendering → Infrastructure
```

Infrastructure knows nothing about Rendering. Rendering knows nothing about Core, etc.

### 3. Explicit Data Flow

```
Source File → Parser → AST → Layout Engine → Render Tree → Terminal
```

Each transformation is explicit and testable.

### 4. Zero-Cost Abstractions

Zig's comptime allows us to:
- Use abstractions without runtime cost
- Monomorphize generic code
- Avoid virtual dispatch where possible

---

## Component Overview

### Presentation Layer

| Component | Responsibility | Key Types |
|-----------|---------------|-----------|
| `main` | Entry point, CLI parsing | - |
| `cli` | Argument parsing | `Args`, `Command` |
| `config` | Configuration loading | `Config`, `Loader` |
| `export` | Export to HTML/PDF | `Exporter`, `Format` |

### Core Layer

| Component | Responsibility | Key Types |
|-----------|---------------|-----------|
| `parser` | Markdown parsing | `Parser`, `Element` |
| `model` | Data models | `Presentation`, `Slide` |
| `layout` | Constraint-based layout | `LayoutEngine`, `Constraints` |
| `engine` | Event loop, state | `Engine`, `State` |

### Rendering Layer

| Component | Responsibility | Key Types |
|-----------|---------------|-----------|
| `widgets` | UI components | `Widget`, `SlideWidget` |
| `theme` | Styling | `Theme`, `Style` |
| `terminal` | Terminal output | `Terminal` (from libvaxis) |

### Feature Layer

| Component | Responsibility | Key Types |
|-----------|---------------|-----------|
| `images` | Image protocols | `ImageProtocol`, `KittyProtocol` |
| `executor` | Code execution | `Executor`, `Sandbox` |
| `highlighter` | Syntax highlighting | `Highlighter`, `Language` |
| `transitions` | Slide animations | `Transition`, `Fade` |

---

## Data Flow

### 1. Loading Flow

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│   File   │────▶│  Parser  │────▶│   AST    │────▶│  Model   │
│   Read   │     │  (Parse) │     │ (Memory) │     │ (Slides) │
└──────────┘     └──────────┘     └──────────┘     └──────────┘
                                                         │
                              ┌─────────────────────────┘
                              ▼
                       ┌──────────┐
                       │  Theme   │
                       │  Load    │
                       └──────────┘
```

### 2. Rendering Flow

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  Model   │────▶│  Widget  │────▶│  Layout  │────▶│  Render  │
│ (Slides) │     │  Tree    │     │ (Size)   │     │ (Draw)   │
└──────────┘     └──────────┘     └──────────┘     └────┬─────┘
                                                        │
                              ┌────────────────────────┘
                              ▼
                       ┌──────────┐
                       │ Terminal │
                       │  Output  │
                       └──────────┘
```

### 3. Event Flow

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│ Terminal │────▶│  Engine  │────▶│ Command  │────▶│  Update  │
│  Input   │     │  (Route) │     │ (Exec)   │     │  State   │
└──────────┘     └──────────┘     └──────────┘     └────┬─────┘
                                                        │
                              ┌────────────────────────┘
                              ▼
                       ┌──────────┐
                       │  Render  │
                       │  Refresh │
                       └──────────┘
```

---

## Module Dependencies

### Module Graph

```
main
├── cli
├── config
├── core
│   ├── engine
│   │   ├── events
│   │   └── fs
│   ├── model
│   ├── parser
│   │   └── (external: no zig markdown parser)
│   └── layout
├── render
│   ├── widgets
│   ├── theme
│   └── terminal (libvaxis)
└── features
    ├── images
    ├── executor
    ├── highlighter
    └── transitions
```

### Dependency Rules

1. **No circular dependencies** - Enforced by Zig
2. **Layer isolation** - Core doesn't import Render
3. **Feature isolation** - Features are optional
4. **Infrastructure at bottom** - Events, FS, logging

---

## Memory Management Strategy

### Allocators by Module

| Module | Allocator Strategy |
|--------|-------------------|
| Parser | Arena (per parse) |
| Model | Arena (presentation lifetime) |
| Layout | Frame (per render) |
| Render | Frame (per render) |
| Engine | GPA (long-lived) |

### Example: Presentation Parsing

```zig
// Create arena for this parse
var arena = std.heap.ArenaAllocator.init(gpa);
defer arena.deinit();
const alloc = arena.allocator();

// All parsing allocations use this arena
const pres = try Parser.parse(alloc, source);

// Everything freed at once when arena deinits
```

### Example: Rendering

```zig
// Frame allocator for this render
var frame = std.heap.stackFallback(4096, gpa);
const alloc = frame.get();

// Temporary allocations for rendering
try renderer.render(alloc, presentation);

// Stack space reused, heap freed
```

---

## Error Handling Strategy

### Error Types

```zig
// Per-module error sets
pub const ParseError = error{
    InvalidSyntax,
    InvalidFrontMatter,
    OutOfMemory,
};

pub const RenderError = error{
    TerminalTooSmall,
    ImageLoadFailed,
    OutOfMemory,
};

// Combined application errors
pub const AppError = ParseError || RenderError || error{
    UserInterrupt,
    ConfigInvalid,
};
```

### Error Propagation

- Use `try` for expected errors
- Use `catch` for recovery
- Use `errdefer` for cleanup
- Bubble up to user at boundaries

---

## Threading Model

### Single-Threaded (Initial)

- Main thread: Event loop + rendering
- Synchronous I/O
- Simple, predictable

### Future: Multi-Threaded

Potential future enhancement:
- Main thread: Event loop + rendering
- Background thread: File watching
- Background thread: Image loading
- Thread pool: Code execution

---

## Extension Points

### Adding a New Widget

1. Implement `Widget` interface in `src/widgets/`
2. Add to widget registry
3. Add tests
4. Update documentation

### Adding a New Theme

1. Create YAML in `themes/`
2. Embed in binary
3. Add to theme loader

### Adding a New Image Protocol

1. Implement `ImageProtocol` interface
2. Add to protocol detection
3. Add fallback logic

---

## Technology Choices

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| Language | Zig 0.15+ | Performance, safety, simplicity |
| TUI Framework | libvaxis | Modern, image support, Zig-native |
| High-Level UI | vxfw | Flutter-like patterns |
| Parsing | Custom | No good Zig markdown parser |
| Highlighting | tree-sitter or custom | Accuracy |
| Testing | Built-in + custom | Native Zig solution |

See ADRs for detailed decision rationale.

---

## Performance Considerations

### Startup Path

```
Parse CLI args → Load config → Parse markdown → Init terminal
   < 1ms            < 1ms         < 10ms          < 5ms
```

Target: < 50ms total

### Runtime Path

```
Input → Update state → Layout → Render → Output
 <1ms      <1ms        <5ms     <5ms      <1ms
```

Target: < 16ms (60fps)

### Memory Budgets

| Component | Budget |
|-----------|--------|
| Presentation model | 10MB |
| Render state | 5MB |
| Images | 20MB |
| Total working set | 50MB |

---

## Security Considerations

### Sandboxing

- Code execution in separate process
- Timeout limits
- Resource limits (CPU, memory)

### Input Validation

- Strict markdown parsing
- Path validation
- Size limits

---

## Changelog

- 2026-03-01: Initial architecture specification

---

*Architecture Spec v1.0*
