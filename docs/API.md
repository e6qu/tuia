# TUIA API Documentation

> API reference for using TUIA as a library

---

## Overview

TUIA is organized into several modules:

- `core` - Data models (Presentation, Slide, Element)
- `parser` - Markdown parsing
- `render` - Theme and styling
- `widgets` - UI components
- `config` - Configuration management
- `features` - Images, execution, export
- `highlight` - Syntax highlighting

---

## Core Module

### Presentation

```zig
const Presentation = @import("tuia").core.Presentation;

// Create a presentation
var pres = Presentation{
    .slides = &[_]Slide{},
    .metadata = .{
        .title = "My Talk",
        .author = "Jane Doe",
    },
};

// Deinit when done
try pres.deinit(allocator);
```

### Slide

```zig
const Slide = @import("tuia").core.Slide;

// Create a slide
var slide = Slide{
    .elements = &[_]Element{
        .{ .heading = .{ .level = 1, .text = "Title" } },
        .{ .paragraph = .{ .text = "Content..." } },
    },
};
```

### Element Types

```zig
const Element = @import("tuia").core.Element;

// Element is a union of:
// - .heading { level: u8, text: []const u8 }
// - .paragraph { text: []const u8 }
// - .code { language: ?[]const u8, content: []const u8 }
// - .list { ordered: bool, items: []const []const u8 }
// - .image { path: []const u8, alt: ?[]const u8 }
// - .blockquote { content: []const u8 }
```

---

## Parser Module

### MarkdownParser

```zig
const MarkdownParser = @import("tuia").parser.MarkdownParser;

var parser = MarkdownParser.init(allocator);
defer parser.deinit();

// Parse markdown source
const pres = try parser.parse(source);
defer pres.deinit(allocator);
```

---

## Render Module

### Theme

```zig
const Theme = @import("tuia").render.Theme;

// Use built-in theme
const theme = Theme.darkTheme();

// Or light theme
const theme = Theme.lightTheme();
```

### Color

```zig
const Color = @import("tuia").render.Color;

// ANSI colors
const red = Color.red;
const bright_blue = Color.bright_blue;

// RGB colors
const custom = Color{ .rgb = .{ .r = 255, .g = 128, .b = 0 } };
```

### ElementStyle

```zig
const ElementStyle = @import("tuia").render.ElementStyle;

const style = ElementStyle{
    .fg = Color.blue,
    .bg = null,
    .bold = true,
    .italic = false,
    .underline = false,
};
```

---

## Config Module

### Config

```zig
const Config = @import("tuia").config.Config;

// Default configuration
var config = Config.defaults();

// Load from file
var manager = ConfigManager.init(allocator);
defer manager.deinit();
try manager.loadFile("config.yaml");
const config = manager.getConfig();
```

### ConfigParser

```zig
const ConfigParser = @import("tuia").config.ConfigParser;

const parser = ConfigParser.init(allocator);
const config = try parser.parseString("""
theme:
  name: light
""");
```

---

## Features Module

### Images

```zig
const ImageLoader = @import("tuia").features.images.ImageLoader;
const ImageRenderer = @import("tuia").features.images.ImageRenderer;

// Load an image
var loader = ImageLoader.init(allocator);
const image = try loader.loadFromFile("image.png");

// Render it
var renderer = ImageRenderer.init(allocator);
const output = try renderer.render(image, .{});
```

### Code Execution

```zig
const CodeExecutor = @import("tuia").features.CodeExecutor;
const Language = @import("tuia").features.Language;

const executor = CodeExecutor.init(allocator, .{
    .timeout_seconds = 30,
});

// Execute Python code
const result = try executor.execute("print('Hello')", .python);
defer result.deinit(allocator);

// Check result
if (result.success()) {
    std.debug.print("Output: {s}\n", .{result.stdout});
}
```

### Export

```zig
const HtmlExporter = @import("tuia").export_.HtmlExporter;

var exporter = HtmlExporter.init(allocator, theme);
const html = try exporter.exportToHtml(presentation);
defer allocator.free(html);
```

---

## Highlight Module

### Highlighter

```zig
const Highlighter = @import("tuia").highlight.Highlighter;
const Language = @import("tuia").highlight.Language;

var highlighter = Highlighter{
    .source = code,
    .language = .zig,
};

const tokens = try highlighter.tokenize(allocator);
defer {
    for (tokens) |*t| t.deinit(allocator);
    allocator.free(tokens);
}
```

---

## Complete Example

```zig
const std = @import("std");
const tuia = @import("tuia");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Load configuration
    var config_manager = tuia.config.ConfigManager.init(allocator);
    defer config_manager.deinit();
    try config_manager.loadDefault();
    const config = config_manager.getConfig();

    // Parse markdown
    const source = try std.fs.cwd().readFileAlloc(
        allocator,
        "presentation.md",
        1024 * 1024,
    );
    defer allocator.free(source);

    var parser = tuia.parser.MarkdownParser.init(allocator);
    defer parser.deinit();

    const presentation = try parser.parse(source);
    defer presentation.deinit(allocator);

    // Export to HTML
    const theme = if (std.mem.eql(u8, config.theme.name, "light"))
        tuia.render.Theme.lightTheme()
    else
        tuia.render.Theme.darkTheme();

    var exporter = tuia.export_.HtmlExporter.init(allocator, theme);
    const html = try exporter.exportToHtml(presentation);
    defer allocator.free(html);

    try std.fs.cwd().writeFile(.{
        .sub_path = "output.html",
        .data = html,
    });

    std.debug.print("Exported to output.html\n", .{});
}
```

---

## Error Handling

Most functions return Zig errors:

```zig
const result = parser.parse(source) catch |err| {
    switch (err) {
        error.OutOfMemory => std.log.err("Out of memory!", .{}),
        error.InvalidSyntax => std.log.err("Invalid markdown syntax", .{}),
        else => std.log.err("Parse error: {}", .{err}),
    }
    return;
};
```

---

## Memory Management

TUIA follows Zig conventions:

- Allocators are explicit parameters
- Use `defer` for cleanup
- Caller owns returned memory
- Check function docs for ownership rules

```zig
// Good pattern
var obj = try Module.init(allocator);
defer obj.deinit(allocator);

const result = try obj.doSomething(allocator);
defer allocator.free(result);
```

---

## Version Compatibility

- **Current Version**: 0.1.0
- **Zig Version**: 0.15.2+
- **API Stability**: Unstable (pre-1.0)

---

## See Also

- [User Guide](USER_GUIDE.md) - End-user documentation
- [Architecture](../specs/architecture/ARCHITECTURE.md) - System design
