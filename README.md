# slidz

> A fast, lightweight terminal presentation tool written in Zig.

[![CI](https://github.com/user/slidz/workflows/CI/badge.svg)](https://github.com/user/slidz/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Status:** 🚧 In Development (Milestone 1: Foundation)

## Features

- 📝 **Markdown-based** - Write presentations in familiar Markdown
- 🎨 **Themes** - Built-in dark/light themes, custom theme support
- 🖼️ **Images** - Kitty, iTerm2, and Sixel image protocols
- 💻 **Code execution** - Run code snippets directly in presentations
- 🎯 **Syntax highlighting** - 20+ programming languages
- 📦 **Single binary** - No dependencies, easy to distribute
- ⚡ **Fast** - <50ms startup, smooth 60fps rendering

## Current Status

**Milestone 1: Foundation** - In Progress

- ✅ Project structure
- ✅ Build system
- ✅ Basic CLI
- 🔄 TUI integration (next)

## Installation

### From Source

Requirements: Zig 0.15.0+

```bash
# Clone repository
git clone https://github.com/user/slidz.git
cd slidz

# Build
zig build -Doptimize=ReleaseFast

# Install (optional)
cp zig-out/bin/slidz ~/.local/bin/
```

### Development Build

```bash
# Debug build
zig build

# Run
zig build run -- examples/demo.md

# Test
zig build test

# Verify (format + tests)
zig build verify
```

## Quick Start

Create `presentation.md`:

```markdown
---
title: "My Talk"
author: "Jane Doe"
---

Welcome
=======

This is my presentation!

<!-- end_slide -->

Code Example
============

```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Hello, world!\n", .{});
}
```

<!-- end_slide -->

The End
=======

Thank you!
```

Present it:

```bash
slidz presentation.md
```

## Usage

```bash
# Present a file
slidz presentation.md

# Show help
slidz --help

# Show version
slidz --version
```

## Project Structure

```
slidz/
├── specs/           # Specifications
├── src/             # Source code
│   ├── main.zig     # Entry point
│   ├── core/        # Data models
│   ├── parser/      # Markdown parser
│   ├── render/      # Rendering engine
│   ├── widgets/     # UI components
│   └── features/    # Images, execution, etc.
├── tests/           # Tests
├── examples/        # Example presentations
└── docs/            # Documentation
```

## Documentation

- [Project Plan](PLAN.md) - Roadmap and milestones
- [Specification Index](specs/README.md) - All specifications
- [Development Guide](docs/DEVELOPMENT.md) - Contributing
- [Architecture](specs/architecture/ARCHITECTURE.md) - System design
- [File Format](specs/formats/FILE_FORMAT.md) - Markdown format

## Development

### Setup

```bash
# Install Zig 0.15.0+
# https://ziglang.org/download/

# Clone
git clone https://github.com/user/slidz.git
cd slidz

# Build
zig build

# Run tests
zig build test
```

### Project Phases

| Milestone | Status | Description |
|-----------|--------|-------------|
| 0: Specification | ✅ Complete | All specs written |
| 1: Foundation | 🔄 In Progress | Build system, TUI setup |
| 2: Core | ⏳ Planned | Parser, widgets, themes |
| 3: Features | ⏳ Planned | Images, execution, export |
| 4: Polish | ⏳ Planned | Docs, packaging, release |

See [PLAN.md](PLAN.md) for detailed roadmap.

## License

MIT License - see [LICENSE](LICENSE) file.

## Acknowledgments

- Inspired by [presenterm](https://github.com/mfontanini/presenterm)
- Built with [Zig](https://ziglang.org/)
- Uses [libvaxis](https://github.com/rockorager/libvaxis) for TUI
