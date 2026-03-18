---
title: Getting Started with TUIA
author: TUIA Team
date: 2026-03-19
---

# Getting Started with TUIA

A fast, lightweight terminal presentation tool

---

## What is TUIA?

TUIA turns **Markdown** into terminal presentations.

- Write slides in familiar Markdown
- Present directly in your terminal
- Export to HTML, Reveal.js, LaTeX, or PDF

> No browser, no GUI — just your terminal.

---

## Installation

```bash
git clone https://github.com/e6qu/tuia.git
cd tuia
zig build -Doptimize=ReleaseSafe
```

Then run:

```bash
./zig-out/bin/tuia examples/quickstart.md
```

---

## Slide Syntax

Separate slides with `---`:

```markdown
# First Slide

Content here

---

## Second Slide

More content
```

---

## Text Formatting

| Syntax | Result |
|--------|--------|
| `**bold**` | **bold** |
| `*italic*` | *italic* |
| `` `code` `` | `code` |
| `~~strike~~` | ~~strike~~ |

---

## Code Blocks

Syntax highlighting for 10+ languages:

```python
def hello(name: str) -> str:
    return f"Hello, {name}!"

print(hello("World"))
```

```zig
const std = @import("std");

pub fn main() !void {
    std.debug.print("Hello from Zig!\n", .{});
}
```

---

## Lists

- Unordered lists with `-`, `*`, or `+`
- Nested items with indentation
  - Like this
  - And this

1. Ordered lists work too
2. Just use numbers
3. Simple as that

---

## Export Formats

```bash
# Static HTML
tuia -e html -o output/ presentation.md

# Reveal.js (interactive web slides)
tuia -e revealjs -o output/ presentation.md

# LaTeX/Beamer
tuia -e beamer -o output/ presentation.md

# PDF (generates .tex, requires pdflatex)
tuia -e pdf -o output/ presentation.md
```

---

## Thank You

**GitHub:** https://github.com/e6qu/tuia

Navigate with `j`/`k`, quit with `q`
