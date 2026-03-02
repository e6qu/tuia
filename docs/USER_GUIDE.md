# TUIA User Guide

> Complete guide to using TUIA - the terminal presentation tool

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Creating Presentations](#creating-presentations)
3. [Presentation Features](#presentation-features)
4. [Configuration](#configuration)
5. [Advanced Features](#advanced-features)
6. [Tips & Tricks](#tips--tricks)

---

## Getting Started

### Installation

```bash
# Clone the repository
git clone https://github.com/e6qu/tuia.git
cd tuia

# Build with Zig 0.15+
zig build -Doptimize=ReleaseSafe

# Install to your PATH
sudo cp zig-out/bin/tuia /usr/local/bin/
```

### Quick Start

Create your first presentation:

```bash
# Create a markdown file
cat > hello.md << 'EOF'
# Hello World

Welcome to my presentation!

---

## Second Slide

- Point one
- Point two
- Point three

---

## Code Example

```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Hello!\n", .{});
}
```
EOF

# Present it
tuia hello.md
```

---

## Creating Presentations

### Markdown Format

TUIA uses standard Markdown with slide separators:

```markdown
# Slide 1 Title

Content here...

---

# Slide 2 Title

More content...
```

Use `---` (three dashes) to separate slides.

### Supported Elements

#### Headings

```markdown
# H1 Heading (Slide Title)
## H2 Heading
### H3 Heading
```

#### Text Formatting

```markdown
**Bold text**
*Italic text*
~~Strikethrough~~
`Inline code`
```

#### Lists

```markdown
- Unordered item 1
- Unordered item 2
  - Nested item
  - Another nested item

1. Ordered item 1
2. Ordered item 2
3. Ordered item 3
```

#### Code Blocks

Syntax highlighting is automatic:

```markdown
```zig
const x = 42;
```

```python
def hello():
    print("Hello!")
```

```javascript
console.log("Hello!");
```
```

Supported languages: Zig, Python, JavaScript, TypeScript, Bash, JSON, Rust, Go, Lua, Ruby

#### Images

```markdown
![Alt text](path/to/image.png)
```

Supported formats: PNG, JPEG, GIF, BMP

#### Blockquotes

```markdown
> This is a quote
> It can span multiple lines
```

#### Speaker Notes

Add notes for yourself (not shown in presentation):

```markdown
# Slide Title

Visible content here...

<!-- note: Remember to mention the key statistics here -->
```

Or use block syntax:

```markdown
<!-- note -->
These are speaker notes.
They won't appear in the presentation.
<!-- endnote -->
```

---

## Presentation Features

### Navigation

| Key | Action |
|-----|--------|
| `j`, `↓`, `Space`, `→` | Next slide |
| `k`, `↑`, `Backspace`, `←` | Previous slide |
| `g` | First slide |
| `G` | Last slide |
| `1-9` | Jump to slide number |
| `?`, `F1` | Show help |
| `q`, `Ctrl+C` | Quit |

### Jump Mode

Type a number and press `Enter` to jump directly to that slide:

1. Type `5`
2. Press `Enter`
3. You're now on slide 5

### Live Reload

TUIA automatically watches your markdown file and reloads changes:

```bash
tuia presentation.md
# Edit presentation.md in your editor
# Changes appear immediately!
```

---

## Configuration

### Configuration File

Create `~/.config/tuia/tuia.yaml`:

```yaml
# Theme settings
theme:
  name: dark  # dark, light, or custom

# Presentation behavior
presentation:
  loop: false
  show_slide_numbers: true
  show_total_slides: true
  aspect_ratio: 16:9

# Key bindings
keys:
  next_slide: j
  prev_slide: k
  first_slide: gg
  last_slide: G
  quit: q
  help: "?"

# Display settings
display:
  min_width: 40
  min_height: 10
  truecolor: true
  mouse: true
  unicode: full

# Code execution
executor:
  timeout_seconds: 30
  max_output_size: 1048576

# File watching
watch:
  enabled: true
  debounce_ms: 300
```

### Generate Sample Config

```bash
tuia --init > tuia.yaml
```

### Command-Line Options

```bash
# Use specific config file
tuia -c myconfig.yaml presentation.md

# Override theme
tuia -t light presentation.md

# Enable looping
tuia --loop presentation.md

# Set auto-advance (seconds)
tuia --auto-advance 10 presentation.md

# Set code execution timeout
tuia --timeout 60 presentation.md
```

---

## Advanced Features

### Code Execution

Execute code blocks during your presentation:

```markdown
## Python Example

```python
print("Hello from Python!")
```

Press the configured key (default: `e`) to execute.
```

**Security Note**: Code runs in a sandboxed subprocess with configurable timeout.

### Export to HTML

Export your presentation to a self-contained HTML file:

```bash
# Export to HTML
tuia -e html -o output/ presentation.md

# This creates output/presentation.html
```

Features:
- Self-contained (no external dependencies)
- Keyboard navigation
- Responsive design
- Dark mode support

### Image Support

TUIA automatically detects your terminal's image capabilities:

1. **Kitty Graphics Protocol** - Best quality, supported by Kitty, WezTerm
2. **iTerm2 Inline Images** - Supported by iTerm2, WezTerm
3. **Sixel** - Supported by xterm, mlterm
4. **ASCII Art** - Fallback for any terminal

### Custom Themes

Create a custom theme in `~/.config/tuia/themes/mytheme.yaml`:

```yaml
name: mytheme
background: "#1a1a2e"
foreground: "#eee"
heading1:
  fg: "#e94560"
  bold: true
heading2:
  fg: "#0f3460"
  bold: true
code:
  bg: "#16213e"
  fg: "#eee"
syntax:
  keyword: "#e94560"
  string: "#16c79a"
  number: "#f9a825"
  comment: "#666"
```

Then use it:

```bash
tuia -t mytheme presentation.md
```

---

## Tips & Tricks

### Terminal Requirements

For the best experience, use a terminal with:

- **True color support** (24-bit color)
- **Unicode support** (for box drawing)
- **Image protocol** (Kitty, iTerm2, or Sixel)

Recommended terminals:
- Kitty (best image support)
- WezTerm (cross-platform)
- iTerm2 (macOS)
- Alacritty (fast, but no images)

### Presentation Tips

1. **Keep it simple** - Terminal presentations work best with minimal content
2. **Use short lines** - Aim for <80 characters per line
3. **Test your images** - Verify they display correctly in your terminal
4. **Practice navigation** - Know the keyboard shortcuts
5. **Have a backup** - Export to HTML for web-based fallback

### Troubleshooting

#### Images not displaying

```bash
# Check your terminal supports images
echo -e '\e_Gi=1,a=q;\e\\'  # Kitty test
```

#### Colors look wrong

```bash
# Disable truecolor
tuia --theme dark presentation.md  # Use built-in theme
```

#### Terminal too small

```bash
# Check minimum requirements
tuia --help | grep -A2 "min"
```

#### File watching not working

```bash
# Disable and re-enable
tuia --config <(echo 'watch: { enabled: false }') presentation.md
```

### Example Presentations

See the `examples/` directory for sample presentations:

- `examples/demo.md` - Feature showcase
- `examples/tutorial.md` - Step-by-step tutorial
- `examples/cheatsheet.md` - Quick reference

---

## Keyboard Shortcuts Cheatsheet

```
Navigation:
  j, ↓, Space, →    Next slide
  k, ↑, Backspace   Previous slide
  g                 First slide
  G                 Last slide
  1-9, Enter        Jump to slide

Actions:
  ?, F1             Show help
  q, Ctrl+C         Quit

Code Execution:
  e                 Execute code block
```

---

## Getting Help

- **GitHub Issues**: https://github.com/e6qu/tuia/issues
- **Documentation**: See `docs/` directory
- **Examples**: See `examples/` directory

---

*Happy presenting!* 🎉
