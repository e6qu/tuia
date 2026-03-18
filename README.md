# TUIA

> A fast, lightweight terminal presentation tool written in Zig.

[![CI](https://github.com/e6qu/tuia/workflows/CI/badge.svg)](https://github.com/e6qu/tuia/actions)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](LICENSE)
[![Zig Version](https://img.shields.io/badge/Zig-0.15.2-orange.svg)](https://ziglang.org)

**Status:** ✅ Version 1.0.0 Released

---

## Features

- 📝 **Markdown-based** - Write presentations in familiar Markdown
- 🎨 **Themes** - Built-in dark/light themes, custom theme support
- 🖼️ **Images** - Kitty, iTerm2, Sixel, and ASCII art fallbacks
- 💻 **Code Execution** - Run code snippets in 8+ languages
- 🎯 **Syntax Highlighting** - 10+ programming languages
- 📤 **Export** - HTML, Reveal.js, Beamer/LaTeX, PDF
- 🗒️ **Speaker Notes** - Hidden notes for presenters
- ⚡ **Fast** - ~3MB binary, smooth rendering
- 🔧 **Configurable** - YAML configuration, CLI overrides

---

## Installation

### Requirements

- Zig 0.15.2+ (for building)
- Terminal with Unicode support (recommended)

### From Source

```bash
# Clone repository
git clone https://github.com/e6qu/tuia.git
cd tuia

# Build optimized binary
zig build -Doptimize=ReleaseSafe

# Install to PATH
sudo cp zig-out/bin/tuia /usr/local/bin/
```

### Pre-built Binaries

Download from [Releases](https://github.com/e6qu/tuia/releases) (coming soon)

---

## Quick Start

Create a presentation:

```bash
cat > hello.md << 'EOF'
# Hello World

Welcome to **TUIA**!

---

## Features

- Fast & lightweight
- Markdown-based
- Live reload

---

## Code Example

```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Hello!\n", .{});
}
```
EOF
```

Present it:

```bash
tuia hello.md
```

**Navigation:**
- `j`/`k` or `↑`/`↓` - Navigate slides
- `g`/`G` - First/last slide
- `1-9` - Jump to slide
- `?` - Help
- `q` - Quit

---

## Usage

```bash
# Basic usage
tuia presentation.md

# With custom theme
tuia -t light presentation.md

# Export to HTML
tuia -e html -o output/ presentation.md

# Create sample config
tuia --init > tuia.yaml

# Show help
tuia --help
```

### Command-Line Options

| Option | Description |
|--------|-------------|
| `-c, --config <FILE>` | Use specific config file |
| `-t, --theme <THEME>` | Set theme (dark, light, custom) |
| `--loop` | Loop presentation |
| `--auto-advance <SEC>` | Auto-advance slides |
| `--timeout <SEC>` | Code execution timeout |
| `-e, --export <FORMAT>` | Export to format (html, revealjs, beamer, pdf) |
| `-o, --output <DIR>` | Output directory for export |
| `--init` | Generate sample config |
| `-h, --help` | Show help |
| `-V, --version` | Show version |

---

## Markdown Format

TUIA uses standard Markdown with `---` slide separators:

```markdown
# Title Slide

Welcome to my presentation!

---

## Code Slide

```python
def hello():
    print("Hello, World!")
```

---

## List Slide

- Point one
- Point two
- Point three

---

## The End

Thank you!
```

### Supported Elements

- Headings (`#`, `##`, `###`)
- Text formatting (**bold**, *italic*, ~~strikethrough~~)
- Lists (ordered and unordered)
- Code blocks with syntax highlighting
- Images (PNG, JPEG, GIF, BMP)
- Blockquotes
- Speaker notes (`<!-- note: ... -->`)

See [User Guide](docs/USER_GUIDE.md) for complete documentation.

---

## Configuration

Create `~/.config/tuia/tuia.yaml`:

```yaml
theme:
  name: dark

presentation:
  loop: false
  show_slide_numbers: true

keys:
  next_slide: j
  prev_slide: k
  quit: q

display:
  truecolor: true
  mouse: true

executor:
  timeout_seconds: 30
```

Generate a sample config:

```bash
tuia --init > ~/.config/tuia/tuia.yaml
```

---

## Project Status

| Milestone | Status | Description |
|-----------|--------|-------------|
| 0: Specification | ✅ Complete | All specs written |
| 1: Foundation | ✅ Complete | Build system, TUI, testing |
| 2: Core | ✅ Complete | Parser, widgets, themes, highlighting |
| 3: Features | ✅ Complete | Images, execution, export, config |
| 4: Polish | ✅ Complete | Documentation, packaging |

See [PLAN.md](PLAN.md) for detailed roadmap.

---

## Documentation

- **[User Guide](docs/USER_GUIDE.md)** - Complete usage guide
- **[PLAN.md](PLAN.md)** - Project roadmap and milestones
- **[STATUS.md](STATUS.md)** - Current development status
- **[WHAT_WE_DID.md](WHAT_WE_DID.md)** - Completed work log

---

## Development

```bash
# Build
cd tuia
zig build

# Run with example
zig build run -- examples/demo.md

# Run tests
zig build unit_test
zig build integration_test

# Run TUI tests (requires expect)
expect scripts/test_tui.exp

# Pre-commit hooks (zig fmt, lint, unit tests)
pre-commit install
pre-commit run --all-files
```

### Project Structure

```
tuia/
├── src/
│   ├── main.zig          # Entry point
│   ├── cli.zig           # CLI parsing
│   ├── tui/              # Terminal I/O (POSIX-only)
│   ├── config/           # Configuration system
│   ├── core/             # Data models (Slide, Presentation)
│   ├── parser/           # Markdown parser
│   ├── render/           # Theme & styling
│   ├── widgets/          # UI components
│   ├── export/           # HTML, Reveal.js, Beamer, PDF
│   ├── features/         # Images, execution, transitions
│   ├── highlight/        # Syntax highlighting
│   └── infra/            # File watching, logging
├── tests/                # Test suite
├── scripts/              # TUI tests (expect)
├── examples/             # Example presentations
├── docs/                 # Documentation
└── themes/               # Built-in themes
```

---

## Acknowledgments

- Inspired by [presenterm](https://github.com/mfontanini/presenterm)
- Built with [Zig](https://ziglang.org/)
- Custom POSIX TUI layer (zero-allocation rendering)
- Image support via [zigimg](https://github.com/zigimg/zigimg)

---

## License

AGPL-3.0 License - see [LICENSE](LICENSE) file.

---

<p align="center">Made with ❤️ and Zig</p>
