# Development Guide

> Setup and workflow for ZIGPRESENTERM development.

---

## Prerequisites

### Required

| Tool | Version | Purpose |
|------|---------|---------|
| Zig | 0.15.0+ | Language compiler |
| git | 2.30+ | Version control |

### Recommended

| Tool | Purpose |
|------|---------|
| zls | Language server |
| zig fmt | Code formatting |
| valgrind | Memory checking (Linux) |

## Installation

### Install Zig

```bash
# macOS/Linux
brew install zig

# Or download from https://ziglang.org/download/

# Verify
zig version  # Should show 0.15.0 or higher
```

### Install ZLS (Zig Language Server)

```bash
git clone https://github.com/zigtools/zls.git
cd zls
zig build -Doptimize=ReleaseSafe
# Add zig-out/bin/zls to PATH
```

### Clone Repository

```bash
git clone https://github.com/user/zigpresenterm.git
cd zigpresenterm
```

## Development Workflow

### Build

```bash
# Debug build
zig build

# Release build
zig build -Doptimize=ReleaseFast

# Run
zig build run -- presentation.md
```

### Test

```bash
# Run all tests
zig build test

# Run specific test
zig test src/parser/Parser.zig

# With leak detection
zig build test -Dleak-check=full
```

### Format

```bash
# Format all files
zig fmt src/

# Check formatting
zig fmt --check src/
```

## IDE Setup

### VS Code

1. Install "Zig" extension
2. Configure ZLS path:
   ```json
   {
     "zig.zls.path": "/path/to/zls"
   }
   ```

### Neovim

```lua
-- Using lspconfig
require('lspconfig').zls.setup{}
```

### Emacs

```elisp
(use-package zig-mode
  :hook (zig-mode . lsp))
```

## Project Structure

```
src/
├── main.zig          # Entry point
├── cli.zig           # CLI parsing
├── config/           # Configuration
├── core/             # Core models
├── parser/           # Markdown parser
├── render/           # Rendering
├── widgets/          # UI widgets
├── features/         # Features (images, etc)
└── infra/            # Infrastructure
```

## Testing

### Writing Tests

```zig
// Inline in source file
test "description" {
    const result = try function();
    try std.testing.expectEqual(expected, result);
}
```

### Test Commands

```bash
# Run all tests
zig build test

# Run with filter
zig build test -Dtest-filter="parse"

# Update golden files
ZIG_UPDATE_GOLDEN=1 zig build test
```

## Debugging

### GDB

```bash
zig build -Doptimize=Debug
gdb ./zig-out/bin/slidz
```

### Print Debugging

```zig
std.debug.print("value: {any}\n", .{value});
```

### Memory Leaks

```bash
# Use GPA
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer std.debug.print("Leaks: {}\n", .{gpa.detectLeaks()});

# Or valgrind
valgrind --leak-check=full ./slidz presentation.md
```

## Committing

### Pre-commit

```bash
# Run before every commit
zig fmt --check src/ && zig build && zig build test
```

### Commit Format

```
type(scope): description

body

footer
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

---

*Development Guide v0.1*
