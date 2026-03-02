# TUIA Tutorial

Learn TUIA in 10 minutes

---

## What is TUIA?

TUIA is a **terminal presentation tool** that lets you:

- Write presentations in Markdown
- Present in any terminal
- Execute code live
- Export to HTML

---

## Creating Your First Presentation

### Step 1: Create a Markdown file

```bash
cat > mytalk.md << 'EOF'
# My Talk

Hello, World!

---

## Slide 2

More content here...
EOF
```

### Step 2: Present it

```bash
tuia mytalk.md
```

---

## Slide Separators

Use `---` (three dashes) to separate slides:

```markdown
# Slide 1

Content...

---

# Slide 2

More content...
```

---

## Adding Code

Code blocks with syntax highlighting:

```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Hello!\n", .{});
}
```

Supported: Zig, Python, JavaScript, Bash, and more!

---

## Speaker Notes

Add notes for yourself:

```markdown
# My Slide

Visible content...

<!-- note: This is a secret note only you can see! -->
```

<!-- note: Press 'n' during presentation to view notes (if configured). -->

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
```

---

## Exporting

Export to HTML for sharing:

```bash
tuia -e html -o output/ mytalk.md
```

Creates a self-contained HTML file with:

- Keyboard navigation
- Responsive design
- No external dependencies

---

## Tips for Great Presentations

1. **Keep it simple** - Less text is more
2. **Use code examples** - Show, don't tell
3. **Practice navigation** - Know your shortcuts
4. **Test your terminal** - Images need Kitty/iTerm2
5. **Have a backup** - Export to HTML

---

## You're Ready!

Now you can create amazing terminal presentations.

**Next steps:**

- Read the full [User Guide](../docs/USER_GUIDE.md)
- Check out more [Examples](./)
- Configure your [Theme](../docs/USER_GUIDE.md#custom-themes)

Happy presenting! 🎉
