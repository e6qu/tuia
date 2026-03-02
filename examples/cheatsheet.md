# TUIA Cheatsheet

Quick reference for common tasks

---

## Installation

```bash
# Clone and build
git clone https://github.com/e6qu/tuia.git
cd tuia
zig build -Doptimize=ReleaseSafe
sudo cp zig-out/bin/tuia /usr/local/bin/
```

---

## Basic Usage

```bash
# Present a file
tuia presentation.md

# With theme
tuia -t light presentation.md

# Export to HTML
tuia -e html presentation.md

# Create config
tuia --init > tuia.yaml
```

---

## Navigation Keys

| Key | Action |
|-----|--------|
| j, ↓, Space, → | Next slide |
| k, ↑, Backspace, ← | Previous slide |
| g | First slide |
| G | Last slide |
| 1-9, Enter | Jump to slide |
| ?, F1 | Help |
| q, Ctrl+C | Quit |

---

## Markdown Syntax

```markdown
# Heading 1
## Heading 2
### Heading 3

**bold**, *italic*, ~~strikethrough~~

- List item
- Another item

1. Ordered
2. List

`inline code`

```language
code block
```

> blockquote

![image](path.png)
```

---

## Configuration File

```yaml
theme:
  name: dark

presentation:
  loop: false
  show_slide_numbers: true
  aspect_ratio: 16:9

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

---

## CLI Options

| Option | Description |
|--------|-------------|
| `-c, --config FILE` | Config file |
| `-t, --theme THEME` | Theme name |
| `--loop` | Loop slides |
| `--auto-advance SEC` | Auto-advance |
| `--timeout SEC` | Code timeout |
| `-e, --export FMT` | Export format |
| `-o, --output DIR` | Output dir |

---

## Supported Languages

Syntax highlighting for:

- Zig, C, C++
- Python, Ruby
- JavaScript, TypeScript
- Go, Rust
- Bash, PowerShell
- JSON, YAML
- Lua

---

## Image Protocols

TUIA auto-detects (best to fallback):

1. **Kitty** - Best quality
2. **iTerm2** - macOS/WezTerm
3. **Sixel** - xterm, mlterm
4. **ASCII** - Universal fallback

---

## File Structure

```
project/
├── presentation.md
├── images/
│   └── diagram.png
└── themes/
    └── custom.yaml
```

Run with:

```bash
cd project
tuia presentation.md
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Images not showing | Use Kitty/WezTerm/iTerm2 |
| Colors wrong | Check `$TERM` |
| Terminal too small | Resize to 40x10 minimum |
| File not reloading | Check `watch.enabled` |

---

## Resources

- **GitHub:** https://github.com/e6qu/tuia
- **Docs:** docs/USER_GUIDE.md
- **Issues:** GitHub Issues

**Happy Presenting!** 🎊
