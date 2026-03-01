# CLI Specification

> Command-line interface specification for ZIGPRESENTERM.

**Status:** 📝 Draft  
**Owner:** @team  
**Date:** 2026-03-01  
**Related:** [CONFIG_FORMAT.md](../formats/CONFIG_FORMAT.md), [FILE_FORMAT.md](../formats/FILE_FORMAT.md)

---

## Overview

ZIGPRESENTERM provides a comprehensive command-line interface for presenting and managing Markdown presentations.

**Command Name:** `slidz` (working name)  
**Version:** 0.1.0

---

## Synopsis

```
slidz [OPTIONS] [COMMAND] [FILE]
slidz [OPTIONS] [FILE]
slidz --help
slidz --version
```

---

## Global Options

Options available for all commands.

| Option | Short | Type | Description | Default |
|--------|-------|------|-------------|---------|
| `--help` | `-h` | flag | Show help message | - |
| `--version` | `-V` | flag | Show version | - |
| `--config` | `-c` | path | Config file path | auto-detect |
| `--theme` | `-t` | string | Theme name | from config |
| `--verbose` | `-v` | flag | Verbose output | false |
| `--quiet` | `-q` | flag | Suppress output | false |

---

## Commands

### `present` (default)

Present a Markdown file. This is the default command when a file is provided.

```
slidz present [OPTIONS] <FILE>
slidz [OPTIONS] <FILE>      # Shorthand
```

**Arguments:**

| Argument | Required | Description |
|----------|----------|-------------|
| `FILE` | Yes | Path to presentation file |

**Options:**

| Option | Short | Type | Description | Default |
|--------|-------|------|-------------|---------|
| `--present` | `-p` | flag | Presentation mode (no hot reload) | false |
| `--execute` | `-x` | flag | Enable code execution | false |
| `--execute-auto` | `-X` | flag | Enable auto-execution | false |
| `--validate-snippets` | | flag | Validate all snippets on start | false |
| `--image-protocol` | | string | Force image protocol | auto |
| `--no-watch` | | flag | Disable file watching | false |
| `--start-at` | | int | Start at slide number | 1 |

**Examples:**

```bash
# Basic presentation
slidz presentation.md

# Presentation mode (no hot reload)
slidz -p presentation.md

# With code execution
slidz -x presentation.md

# Force Kitty image protocol
slidz --image-protocol kitty presentation.md

# Start at slide 5
slidz --start-at 5 presentation.md
```

---

### `export`

Export presentation to other formats.

```
slidz export [OPTIONS] <FORMAT> <FILE>
```

**Arguments:**

| Argument | Required | Description |
|----------|----------|-------------|
| `FORMAT` | Yes | Export format: html, pdf |
| `FILE` | Yes | Path to presentation file |

**Options:**

| Option | Short | Type | Description | Default |
|--------|-------|------|-------------|---------|
| `--output` | `-o` | path | Output file path | auto |
| `--theme` | `-t` | string | Theme for export | from file |

**Examples:**

```bash
# Export to HTML
slidz export html presentation.md

# Export to PDF with custom output
slidz export pdf presentation.md -o output.pdf

# Export with specific theme
slidz export html presentation.md -t light
```

---

### `init`

Create a new presentation file.

```
slidz init [OPTIONS] [FILE]
```

**Arguments:**

| Argument | Required | Description |
|----------|----------|-------------|
| `FILE` | No | Output file path | default: `presentation.md` |

**Options:**

| Option | Short | Type | Description |
|--------|-------|------|-------------|
| `--title` | | string | Presentation title |
| `--author` | | string | Author name |
| `--theme` | | string | Initial theme |

**Examples:**

```bash
# Create default presentation
slidz init

# Create with metadata
slidz init talk.md --title "My Talk" --author "Jane Doe"
```

**Generated File:**

```markdown
---
title: "My Talk"
author: "Jane Doe"
date: "2026-03-01"
---

Welcome
=======

Welcome to my presentation!

<!-- end_slide -->

Code Example
============

```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Hello, world!\\n", .{});
}
```

<!-- end_slide -->

The End
=======

Thank you!
```

---

### `validate`

Validate a presentation file.

```
slidz validate [OPTIONS] <FILE>
```

**Arguments:**

| Argument | Required | Description |
|----------|----------|-------------|
| `FILE` | Yes | Path to presentation file |

**Options:**

| Option | Description |
|--------|-------------|
| `--strict` | Fail on warnings |
| `--snippets` | Also validate code snippets |

**Examples:**

```bash
# Basic validation
slidz validate presentation.md

# Strict validation
slidz validate --strict presentation.md

# Validate including snippets
slidz validate --snippets presentation.md
```

**Exit Codes:**

| Code | Meaning |
|------|---------|
| 0 | Valid |
| 1 | Parse error |
| 2 | Validation warning (with --strict) |
| 3 | Snippet error |

---

### `themes`

List and preview available themes.

```
slidz themes [SUBCOMMAND]
```

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `list` | List all themes |
| `preview` | Preview a theme |

**Examples:**

```bash
# List themes
slidz themes list

# Preview theme
slidz themes preview dark
```

---

### `config`

Manage configuration.

```
slidz config [SUBCOMMAND]
```

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `init` | Create default config file |
| `path` | Show config file path |
| `validate` | Validate config file |

**Examples:**

```bash
# Create config file
slidz config init

# Show config path
slidz config path

# Validate config
slidz config validate
```

---

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SLIDZ_CONFIG` | Config file path | `~/.config/slidz/config.yaml` |
| `SLIDZ_THEME` | Default theme | `dark` |
| `SLIDZ_TERM_FONT_SIZE` | Terminal font size (Windows) | `16` |
| `SLIDZ_IMAGE_PROTOCOL` | Force image protocol | `kitty` |

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Invalid arguments |
| 3 | File not found |
| 4 | Parse error |
| 5 | Validation error |
| 130 | Interrupted (Ctrl+C) |

---

## Help Output

### Main Help

```
$ slidz --help
slidz 0.1.0
Terminal presentation tool

USAGE:
    slidz [OPTIONS] [COMMAND] [FILE]
    slidz [OPTIONS] [FILE]

ARGS:
    <FILE>    Presentation file to display

OPTIONS:
    -c, --config <PATH>     Config file path
    -h, --help              Print help information
    -q, --quiet             Suppress output
    -t, --theme <NAME>      Theme to use
    -v, --verbose           Verbose output
    -V, --version           Print version information

COMMANDS:
    present     Present a file (default)
    export      Export to other formats
    init        Create new presentation
    validate    Validate presentation
    themes      Theme management
    config      Config management
    help        Print this message or help for subcommands

Run 'slidz help <COMMAND>' for more info on a command.
```

### Command Help

```
$ slidz help present
Present a Markdown presentation

USAGE:
    slidz present [OPTIONS] <FILE>

ARGS:
    <FILE>    Path to presentation file

OPTIONS:
    -p, --present           Presentation mode (no hot reload)
    -x, --execute           Enable code execution
    -X, --execute-auto      Enable auto-execution
        --image-protocol    Force image protocol [auto|kitty|iterm2|sixel]
        --no-watch          Disable file watching
        --start-at <N>      Start at slide number
        --validate-snippets Validate all snippets on start
    -h, --help              Print help information
```

---

## Examples

### Daily Use

```bash
# Present with defaults
slidz talk.md

# Present with hot reload for development
slidz talk.md

# Present without hot reload for actual talk
slidz -p talk.md

# Present with code demos
slidz -x talk.md
```

### Development Workflow

```bash
# Create new talk
slidz init talk.md --title "My Talk"

# Edit and preview (with hot reload)
slidz talk.md

# Validate before presenting
slidz validate --snippets talk.md

# Export to PDF for sharing
slidz export pdf talk.md -o talk.pdf
```

### CI/CD Integration

```bash
# Validate in CI
slidz validate --strict talk.md

# Export for web
slidz export html talk.md -o public/talk.html
```

---

## Shell Completion

Generate shell completion scripts:

```bash
# Bash
slidz --generate-completion bash > /etc/bash_completion.d/slidz

# Zsh
slidz --generate-completion zsh > /usr/share/zsh/site-functions/_slidz

# Fish
slidz --generate-completion fish > ~/.config/fish/completions/slidz.fish
```

---

## Changelog

- 2026-03-01: Initial CLI specification

---

*CLI Spec v1.0*
