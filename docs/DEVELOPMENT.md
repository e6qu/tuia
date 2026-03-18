# Development Guide

> Setup and workflow for TUIA development.

---

## Prerequisites

### Required

| Tool | Version | Purpose |
|------|---------|---------|
| Zig | 0.15.2+ | Language compiler |
| git | 2.30+ | Version control |

### Recommended

| Tool | Purpose |
|------|---------|
| zls | Language server |
| pre-commit | Git hooks framework |
| expect | TUI test runner |
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
git clone https://github.com/e6qu/tuia.git
cd tuia
```

### Install Pre-commit Hooks

```bash
pip install pre-commit
pre-commit install
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
# Unit tests
zig build unit_test

# Integration tests
zig build integration_test

# TUI tests (requires expect)
expect scripts/test_tui.exp

# With leak detection
zig build unit_test -Dleak-check=full
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
├── tui/              # Terminal I/O (POSIX-only)
├── config/           # Configuration
├── core/             # Core models
├── parser/           # Markdown parser
├── render/           # Rendering
├── widgets/          # UI widgets
├── export/           # HTML, Reveal.js, Beamer, PDF
├── features/         # Features (images, execution, transitions)
├── highlight/        # Syntax highlighting
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
# Unit tests
zig build unit_test

# Integration tests
zig build integration_test

# TUI tests
expect scripts/test_tui.exp
```

## Debugging

### GDB

```bash
zig build -Doptimize=Debug
gdb ./zig-out/bin/tuia
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
valgrind --leak-check=full ./tuia presentation.md
```

## Committing

### Pre-commit

Pre-commit hooks run automatically on `git commit`:

```bash
# Install hooks (one-time)
pre-commit install

# Run manually
pre-commit run --all-files
```

Hooks: `zig fmt`, lint (no-warnings build), unit tests.

### Commit Format

```
type(scope): description

body

footer
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

---

*Last updated: 2026-03-19*
