# Zig Clean-Room Reimplementation of presenterm

> Exploring a Zig-based implementation using Ghostty's libraries and the modern Zig TUI ecosystem.

## Table of Contents

1. [Why Zig?](#why-zig)
2. [Ghostty's Library Architecture](#ghosttys-library-architecture)
3. [Zig TUI Ecosystem](#zig-tui-ecosystem)
4. [Architecture with libghostty-vt](#architecture-with-libghostty-vt)
5. [Implementation Strategy](#implementation-strategy)
6. [Comparison with Go/Rust](#comparison-with-gorust)
7. [Recommended Stack](#recommended-stack)
8. [Code Examples](#code-examples)

---

## Why Zig?

### Advantages for a Presentation Tool

| Aspect | Benefit |
|--------|---------|
| **Performance** | Zero-cost abstractions, comparable to C/C++/Rust |
| **Memory Safety** | Compile-time memory management, no GC pauses |
| **Comptime** | Powerful metaprogramming for code generation |
| **C Interop** | Seamless integration with C libraries (Chroma, etc.) |
| **Single Binary** | Easy distribution, no runtime dependencies |
| **Cross-compilation** | Built-in support for all major platforms |
| **Readability** | Explicit, simple syntax compared to Rust |

### Specific Advantages for TUI

- **Zero-allocation rendering paths possible**
- **Direct terminal control** without abstraction overhead
- **SIMD-optimized parsing** (via libghostty-vt)
- **Predictable performance** for smooth transitions

---

## Ghostty's Library Architecture

### libghostty Family (In Development)

Ghostty is splitting its core into reusable libraries:

```
┌─────────────────────────────────────────────────────────────────┐
│                        libghostty                               │
├─────────────────────────────────────────────────────────────────┤
│  libghostty-vt    │  libghostty-input  │  libghostty-render    │
│  (available now)  │  (planned)         │  (planned)            │
├─────────────────────────────────────────────────────────────────┤
│  libghostty-gtk   │  libghostty-swift  │  libghostty-metal     │
│  (GTK widgets)    │  (SwiftUI)         │  (GPU rendering)      │
└─────────────────────────────────────────────────────────────────┘
```

### libghostty-vt (Available Now)

**Repository:** Part of https://github.com/ghostty-org/ghostty

**Key Features:**
- ✅ **Zero dependencies** (not even libc!)
- ✅ **SIMD-optimized** terminal sequence parsing
- ✅ **Full VT state machine** implementation
- ✅ **Unicode support** (grapheme clusters, etc.)
- ✅ **Kitty Graphics Protocol** support
- ✅ **Tmux Control Mode** support
- ✅ **Fuzzed & Valgrind-tested** codebase
- ✅ **Zig API** available now
- ✅ **C API** coming soon

**What It Does:**

```
Raw Bytes ──▶ libghostty-vt ──▶ Terminal State
                     │
                     ▼
              ┌──────────────┐
              │  Grid cells  │
              │  Cursor pos  │
              │  Attributes  │
              │  Scrollback  │
              └──────────────┘
```

**Perfect For:**
- Embedding terminal emulation in applications
- Parsing ANSI sequences correctly
- Building terminal multiplexers
- Read-only terminal views (CI logs, etc.)

**Note:** libghostty-vt is a **terminal emulator library**, not a TUI library. It helps you *emulate* a terminal, not build terminal UIs directly.

---

## Zig TUI Ecosystem

### 1. libvaxis (Recommended) ⭐

**Repository:** https://github.com/rockorager/libvaxis

**Philosophy:** Modern TUI without terminfo - detects features via terminal queries

**Two APIs:**

#### Low-Level API (vaxis)
Direct cell control, bring your own event loop

```zig
var vx = try vaxis.init(allocator, .{});
defer vx.deinit(allocator);

// Get terminal capabilities
const caps = vx.caps;

// Write to screen
vx.setCell(0, 0, .{ .char = 'H', .style = .{ .fg = .red } });

// Render
try vx.render(writer);
```

#### High-Level API (vxfw - Vaxis Framework)
Flutter-inspired reactive framework

```zig
// Widget with state
const Counter = struct {
    count: u32 = 0,
    button: vxfw.Button,
    
    pub fn widget(self: *Counter) vxfw.Widget {
        return .{
            .userdata = self,
            .eventHandler = Counter.handleEvent,
            .drawFn = Counter.draw,
        };
    }
    
    fn draw(ptr: *anyopaque, ctx: vxfw.DrawContext) !vxfw.Surface {
        const self = @ptrCast(@alignCast(ptr));
        // Constraint-based layout like Flutter
        // Return Surface with children
    }
};
```

**Features:**
- ✅ RGB color
- ✅ Kitty Graphics Protocol (images!)
- ✅ Kitty Keyboard Protocol
- ✅ Hyperlinks (OSC 8)
- ✅ Sixel support
- ✅ Bracketed paste
- ✅ Fancy underlines (undercurl)
- ✅ Mouse shapes
- ✅ System clipboard (OSC 52)
- ✅ Synchronized output (Mode 2026)
- ✅ Unicode Core (Mode 2027)
- ✅ Cross-platform (macOS, Windows, Linux/BSD)

### 2. Tuile

**Repository:** https://github.com/akarpovskii/tuile

**Philosophy:** React-like component tree with crossterm backend

```zig
var tui = try tuile.Tuile.init(.{});
defer tui.deinit();

try tui.add(
    tuile.block(
        .{
            .border = tuile.Border.all(),
            .border_type = .rounded,
            .layout = .{ .flex = 1 },
        },
        tuile.label(.{ .text = "Hello World!" }),
    ),
);

try tui.run();
```

**Features:**
- ✅ Component-based architecture
- ✅ Crossterm backend (cross-platform)
- ✅ Borders, layouts, labels
- ⚠️ Less mature than libvaxis

### 3. TUI.zig

**Repository:** https://github.com/Muhammad-Fiaz/TUI.zig

**Status:** Newer project, documentation-focused

**Features:**
- 36+ widgets
- Form components
- Navigation components

**Note:** Less established in the community compared to libvaxis.

---

## Architecture with libghostty-vt

### Important Clarification

For a **presentation tool** (not a terminal multiplexer), you likely **don't need libghostty-vt**. Here's why:

| Use Case | Needs libghostty-vt? | Alternative |
|----------|---------------------|-------------|
| Terminal multiplexer (tmux clone) | ✅ Yes | Embed full terminal |
| IDE terminal panel | ✅ Yes | Embed full terminal |
| CI log viewer with ANSI | ✅ Yes | Parse ANSI sequences |
| **Presentation tool** | ❌ No | Direct TUI control |

**For presenterm-like tool:** Use **libvaxis** directly, not libghostty-vt.

### Recommended Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     ZIGPRESENTERM                                           │
├─────────────────────────────────────────────────────────────────────────────┤
│  CLI Layer (src/main.zig)                                                   │
│  ├── Argument parsing (std.process.args)                                    │
│  └── Configuration loading                                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│  Core Engine (src/engine.zig)                                               │
│  ├── Presentation state machine                                             │
│  ├── Event loop (libxev or custom)                                          │
│  └── Slide navigation                                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│  Parser (src/parser/)                                                       │
│  ├── Markdown parser (custom or pulldown-zig)                               │
│  ├── Front matter (mustache or custom)                                      │
│  └── Code attribute parser (+exec, +line_numbers)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│  Rendering (src/render/)                                                    │
│  ├── vxfw widgets (from libvaxis)                                           │
│  ├── Layout engine (constraint-based)                                       │
│  ├── Theme application                                                      │
│  └── Text wrapping & alignment                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│  Features (src/features/)                                                   │
│  ├── Images (Kitty/iTerm2/Sixel via libvaxis)                               │
│  ├── Code highlighting (tree-sitter or Chroma via C)                        │
│  ├── Code execution (std.process.Child)                                     │
│  ├── Transitions (custom interpolation)                                     │
│  └── Export (PDF via headless browser)                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│  Infrastructure (src/infra/)                                                │
│  ├── File watching (std.os.linux.inotify or fsnotify C)                     │
│  ├── Memory management (Arena allocators)                                   │
│  └── Logging (std.log)                                                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Implementation Strategy

### Phase 1: Foundation (2-3 weeks)

**Goal:** Basic slide navigation with vxfw

```zig
// build.zig.zon
.{
    .name = "zigpresenterm",
    .version = "0.1.0",
    .dependencies = .{
        .vaxis = .{
            .url = "git+https://github.com/rockorager/libvaxis.git#<commit>",
            .hash = "...",
        },
    },
}
```

```zig
// src/main.zig
const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Presentation = @import("presentation.zig").Presentation;
const Parser = @import("parser.zig").Parser;
const SlideWidget = @import("widgets/slide.zig").SlideWidget;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    
    // Parse presentation
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);
    
    const parser = Parser.init(alloc);
    const presentation = try parser.parseFile(args[1]);
    
    // Create app
    var app = try App.init(alloc, presentation);
    defer app.deinit();
    
    // Run vxfw
    try vxfw.run(alloc, app.widget());
}

const App = struct {
    allocator: std.mem.Allocator,
    presentation: Presentation,
    current_slide: usize = 0,
    
    pub fn widget(self: *App) vxfw.Widget {
        return .{
            .userdata = self,
            .eventHandler = App.handleEvent,
            .drawFn = App.draw,
        };
    }
    
    fn handleEvent(ptr: *anyopaque, ctx: *vxfw.EventContext, event: vxfw.Event) !void {
        const self = @ptrCast(@alignCast(ptr));
        switch (event) {
            .key_press => |key| {
                if (key.matches('q', .{})) {
                    ctx.quit = true;
                } else if (key.matches('l', .{}) or key.matches(' ', .{})) {
                    self.nextSlide();
                    ctx.redraw = true;
                } else if (key.matches('h', .{})) {
                    self.prevSlide();
                    ctx.redraw = true;
                }
            },
            else => {},
        }
    }
    
    fn draw(ptr: *anyopaque, ctx: vxfw.DrawContext) !vxfw.Surface {
        const self = @ptrCast(@alignCast(ptr));
        const slide = self.presentation.slides[self.current_slide];
        
        // Delegate to SlideWidget
        const slide_widget = SlideWidget.init(slide, self.presentation.theme);
        return slide_widget.draw(ctx);
    }
    
    fn nextSlide(self: *App) void {
        if (self.current_slide < self.presentation.slides.len - 1) {
            self.current_slide += 1;
        }
    }
    
    fn prevSlide(self: *App) void {
        if (self.current_slide > 0) {
            self.current_slide -= 1;
        }
    }
};
```

### Phase 2: Markdown Parsing (2-3 weeks)

**Options:**

1. **Custom parser** (recommended for control)
   ```zig
   // Simple state machine parser
   pub const Parser = struct {
       pub fn parse(self: *Parser, source: []const u8) !Presentation {
           // Parse front matter (YAML)
           // Split slides by <!-- end_slide -->
           // Parse each slide's markdown
       }
   };
   ```

2. **Goldmark via Cgo-style** (if Go parser exists)
   - Not recommended, adds CGO complexity

3. **Tree-sitter markdown grammar**
   ```zig
   // Use tree-sitter for robust parsing
   const ts = @cImport({
       @cInclude("tree_sitter/api.h");
   });
   ```

### Phase 3: Code Highlighting

**Options:**

1. **tree-sitter** (native Zig port available)
   - Fast, incremental parsing
   - Good for dynamic highlighting

2. **Chroma via C bindings**
   ```zig
   // Link against Chroma C library
   const chroma = @cImport({
       @cInclude("chroma.h");
   });
   ```

3. **Custom highlighters** (simpler languages)
   - Regex-based for common languages
   - Fast, zero dependencies

### Phase 4: Images (via libvaxis)

```zig
// Images are built into libvaxis!

const Image = struct {
    path: []const u8,
    width: ?usize = null,
    
    pub fn widget(self: *Image) vxfw.Widget {
        return .{
            .userdata = self,
            .drawFn = Image.draw,
        };
    }
    
    fn draw(ptr: *anyopaque, ctx: vxfw.DrawContext) !vxfw.Surface {
        const self = @ptrCast(@alignCast(ptr));
        
        // Load image
        const img = try vaxis.Image.load(self.path);
        
        // Calculate size
        const max_width = self.width orelse ctx.max.width;
        const size = img.scaleToWidth(max_width);
        
        return vxfw.Surface{
            .size = .{
                .width = size.cols,
                .height = size.rows,
            },
            .image = img,
        };
    }
};
```

### Phase 5: Code Execution

```zig
const std = @import("std");

pub const Executor = struct {
    allocator: std.mem.Allocator,
    
    pub fn execute(
        self: *Executor,
        language: []const u8,
        code: []const u8,
    ) !ExecutionResult {
        // Find runner for language
        const runner = try self.getRunner(language);
        
        // Create temp file with code
        const tmp = try std.fs.createTempFile(".zigpresenterm", code);
        defer tmp.close();
        
        // Execute
        var child = std.process.Child.init(
            &.{ runner, tmp.path() },
            self.allocator,
        );
        
        child.stdout_behavior = .Pipe;
        child.stderr_behavior = .Pipe;
        
        try child.spawn();
        
        const stdout = try child.stdout.?.readToEndAlloc(self.allocator, 1024 * 1024);
        const stderr = try child.stderr.?.readToEndAlloc(self.allocator, 1024 * 1024);
        
        const term = try child.wait();
        
        return .{
            .stdout = stdout,
            .stderr = stderr,
            .exit_code = switch (term) {
                .Exited => |code| code,
                else => 1,
            },
        };
    }
};
```

---

## Comparison with Go/Rust

### Feature Comparison

| Feature | Go + Textual | Rust + Ratatui | Zig + libvaxis |
|---------|-------------|----------------|----------------|
| **Performance** | Good (GC pauses) | Excellent | Excellent |
| **Binary Size** | ~10-20MB | ~2-5MB | ~1-3MB |
| **Memory Safety** | GC | Compile-time | Compile-time |
| **Build Time** | Fast | Slow | Very Fast |
| **Learning Curve** | Low | High | Medium |
| **TUI Libraries** | Excellent (Textual) | Excellent (Ratatui) | Good (libvaxis) |
| **Image Support** | Via libraries | Via libraries | Built-in (vaxis) |
| **Cross-compile** | Good | Good | **Excellent** |
| **C Interop** | CGO (complex) | FFI (safe) | **Native** |
| **Hiring Pool** | Large | Large | Small |

### When to Choose Each

**Choose Go + Textual when:**
- Rapid development is priority
- Team knows Python/Go
- Need rich ecosystem
- Acceptable to have larger binary

**Choose Rust + Ratatui when:**
- Maximum safety is required
- Complex async I/O patterns
- Large team, strict code review
- Long-term maintenance critical

**Choose Zig + libvaxis when:**
- Minimal binary size matters
- Need C interop (embed Chroma, etc.)
- Fast compile times important
- Want to contribute to cutting-edge TUI
- Team likes explicit, simple code

---

## Recommended Stack

### For Maximum Compatibility (Recommended)

```
Core:
  - libvaxis (TUI framework)
  - vxfw (Flutter-like high-level API)

Parsing:
  - Custom markdown parser (Zig)
  - Mustache-yaml for front matter

Highlighting:
  - tree-sitter (native Zig or C bindings)
  OR
  - Custom regex highlighters

Images:
  - libvaxis built-in Kitty/iTerm2/Sixel

Execution:
  - std.process.Child

Export:
  - Headless Chrome/Chromium via std.process
```

### Alternative: Maximum Performance

```
Core:
  - libvaxis low-level API (no vxfw)
  - Custom immediate-mode UI

Parsing:
  - Custom SIMD-optimized parser
  - Inspired by libghostty-vt techniques

This gives maximum control but more code.
```

---

## Code Examples

### Complete Slide Widget

```zig
// src/widgets/slide.zig
const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Element = @import("../parser/element.zig").Element;
const Theme = @import("../theme.zig").Theme;

pub const SlideWidget = struct {
    elements: []const Element,
    theme: Theme,
    layout: ?ColumnLayout,
    
    pub fn init(elements: []const Element, theme: Theme) SlideWidget {
        return .{
            .elements = elements,
            .theme = theme,
            .layout = null,
        };
    }
    
    pub fn widget(self: *SlideWidget) vxfw.Widget {
        return .{
            .userdata = self,
            .drawFn = SlideWidget.draw,
        };
    }
    
    fn draw(ptr: *anyopaque, ctx: vxfw.DrawContext) !vxfw.Surface {
        const self = @ptrCast(@alignCast(ptr));
        
        // Calculate available space with margins
        const margin = self.theme.default_margin;
        const available = .{
            .width = ctx.max.width -| (margin.left + margin.right),
            .height = ctx.max.height -| (margin.top + margin.bottom),
        };
        
        // Create children for each element
        var children = std.ArrayList(vxfw.SubSurface).init(ctx.arena);
        
        var row: usize = margin.top;
        for (self.elements) |element| {
            const child = try self.elementToWidget(element);
            const child_surface = try child.draw(ctx.withConstraints(
                .{ .width = 0, .height = 0 },
                available,
            ));
            
            try children.append(.{
                .origin = .{ .row = row, .col = margin.left },
                .surface = child_surface,
            });
            
            row += child_surface.size.height;
        }
        
        return .{
            .size = ctx.max,
            .children = try children.toOwnedSlice(),
        };
    }
    
    fn elementToWidget(self: *SlideWidget, element: Element) vxfw.Widget {
        return switch (element) {
            .text => |t| TextWidget.init(t, self.theme.default_style),
            .heading => |h| HeadingWidget.init(h, self.theme),
            .code => |c| CodeWidget.init(c, self.theme),
            .list => |l| ListWidget.init(l, self.theme),
            .image => |i| ImageWidget.init(i),
            // ... etc
        };
    }
};
```

### Theme Definition

```zig
// src/theme.zig

pub const Theme = struct {
    name: []const u8,
    default_style: Style,
    slide_title: HeadingStyle,
    headings: [6]HeadingStyle,
    code: CodeStyle,
    footer: FooterConfig,
    
    pub fn loadBuiltin(name: []const u8) ?Theme {
        // Embedded themes using @embedFile
        const dark_theme = @embedFile("themes/dark.json");
        // Parse and return
    }
};

pub const Style = struct {
    fg: ?vaxis.Color = null,
    bg: ?vaxis.Color = null,
    bold: bool = false,
    italic: bool = false,
    underline: bool = false,
};

pub const HeadingStyle = struct {
    style: Style,
    prefix: []const u8 = "",
    font_size: u8 = 1,
    padding_top: u8 = 0,
    padding_bottom: u8 = 0,
    separator: bool = false,
};
```

### Configuration

```zig
// src/config.zig

const std = @import("std");

pub const Config = struct {
    theme: []const u8 = "dark",
    validate_overflows: OverflowValidation = .never,
    max_columns: ?u16 = null,
    bindings: KeyBindings = .{},
    
    pub const OverflowValidation = enum {
        never,
        always,
        when_presenting,
        when_developing,
    };
    
    pub fn load(allocator: std.mem.Allocator, path: ?[]const u8) !Config {
        // Load from ~/.config/zigpresenterm/config.yaml
        // Parse with custom YAML parser or mustache
    }
};

pub const KeyBindings = struct {
    next: []const []const u8 = &.{"l", "j", "right", " "},
    previous: []const []const u8 = &.{"h", "k", "left"},
    exit: []const []const u8 = &.{"q", "ctrl+c"},
    // ... etc
};
```

---

## Key Insights

### 1. libghostty-vt vs libvaxis

| | libghostty-vt | libvaxis |
|---|---------------|----------|
| **Purpose** | Terminal emulation | TUI framework |
| **Use for** | Multiplexers, embedded terminals | Direct UI rendering |
| **Presenterm** | ❌ Not needed | ✅ Perfect fit |
| **Dependencies** | Zero | Minimal |
| **Maturity** | Alpha API (stable core) | Stable, actively developed |

### 2. The Zig Advantage for Presentations

- **Single small binary** - Easy to distribute at conferences
- **Fast startup** - No VM/runtime warmup
- **Predictable memory** - No GC stutter during transitions
- **C interop** - Can embed proven libraries (Chroma, tree-sitter)

### 3. Current State (March 2025)

- ✅ libvaxis is production-ready
- ✅ vxfw framework is usable
- ⚠️ libghostty-vt C API not yet stable
- ✅ Zig 0.15+ has all needed features
- ⚠️ Smaller ecosystem than Go/Rust

---

## Conclusion

**Zig + libvaxis is a viable and attractive option** for a presenterm reimplementation:

**Pros:**
- Excellent performance characteristics
- Small binary size
- Native image support via libvaxis
- Modern TUI framework (vxfw)
- Fun to develop with

**Cons:**
- Smaller ecosystem (fewer libraries)
- Less mature than Go/Rust options
- Smaller community for support

**Recommendation:** If you're comfortable with Zig's explicit style and want to be on the cutting edge of TUI development, **Zig + libvaxis is an excellent choice**. The vxfw framework provides a Flutter-like experience that makes building complex layouts surprisingly pleasant.

---

*Document created March 2025*
*libvaxis: https://github.com/rockorager/libvaxis*
*Ghostty: https://github.com/ghostty-org/ghostty*
