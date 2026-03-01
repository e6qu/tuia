# File Format Specification

> Specification for ZIGPRESENTERM Markdown presentation files.

**Status:** 📝 Draft  
**Owner:** @team  
**Date:** 2026-03-01  
**Related:** [THEME_FORMAT.md](THEME_FORMAT.md), [CONFIG_FORMAT.md](CONFIG_FORMAT.md)

---

## Overview

ZIGPRESENTERM presentations are written in Markdown with extensions for slide control, code execution, and theming.

**File Extension:** `.md` (recommended)  
**MIME Type:** `text/markdown`  
**Encoding:** UTF-8

---

## Document Structure

```
┌─────────────────────────────────────┐
│         YAML Front Matter           │
│              (optional)              │
├─────────────────────────────────────┤
│                                     │
│         Slide 1 Content             │
│                                     │
├─────────────────────────────────────┤
│         Slide Separator             │
├─────────────────────────────────────┤
│                                     │
│         Slide 2 Content             │
│                                     │
├─────────────────────────────────────┤
│              ...                    │
└─────────────────────────────────────┘
```

---

## Front Matter

### Syntax

Front matter is optional YAML at the start of the file, delimited by `---`:

```markdown
---
title: "My Presentation"
author: "Jane Doe"
date: "2026-03-01"
---

# First Slide
Content here...
```

### Supported Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `title` | string | Presentation title | `"My Talk"` |
| `subtitle` | string | Subtitle | `"A deep dive"` |
| `author` | string | Single author | `"Jane Doe"` |
| `authors` | array | Multiple authors | `["Jane", "John"]` |
| `date` | string | Date string | `"2026-03-01"` |
| `event` | string | Event name | `"ZigConf 2026"` |
| `location` | string | Location | `"San Francisco"` |
| `theme` | string | Theme name | `"dark"` |

### Example

```markdown
---
title: "Building TUIs in Zig"
subtitle: "A Practical Guide"
author: "Jane Doe"
event: "Zig Meetup"
date: "2026-03-15"
theme: "dark"
---
```

---

## Slide Separators

### Standard Separator

Use HTML comment:

```markdown
# Slide 1
Content

<!-- end_slide -->

# Slide 2
More content
```

### Alternative Separator

With `end_slide_shorthand: true` in config:

```markdown
# Slide 1
Content

---

# Slide 2
More content
```

**Note:** Three dashes on their own line.

---

## Supported Markdown Elements

### Headings

```markdown
# H1 Heading
## H2 Heading
### H3 Heading
#### H4 Heading
##### H5 Heading
###### H6 Heading
```

**Special: Slide Titles**

Setext-style headers become slide titles:

```markdown
Slide Title
===========

This is a slide with a title.
```

### Paragraphs

```markdown
This is a paragraph.

This is another paragraph after a blank line.
```

### Text Formatting

```markdown
**bold text**
_italic text_
**_bold and italic_**
~~strikethrough~~
`inline code`
```

### Lists

**Unordered:**

```markdown
- Item 1
- Item 2
  - Nested item
  - Another nested
- Item 3
```

**Ordered:**

```markdown
1. First item
2. Second item
   1. Nested
   2. Nested
3. Third item
```

### Code Blocks

**Fenced:**

~~~markdown
```rust
fn main() {
    println!("Hello!");
}
```
~~~

**With language:**

~~~markdown
```python
def greet():
    return "Hello"
```
~~~

**With attributes:**

~~~markdown
```rust +line_numbers +exec
fn main() {
    println!("Executable!");
}
```
~~~

See [Code Attributes](#code-attributes) for all options.

### Blockquotes

```markdown
> This is a blockquote.
> It can span multiple lines.

> [!note]
> This is a GitHub-style alert.

> [!warning]
> This is a warning alert.
```

### Tables

```markdown
| Header 1 | Header 2 |
|----------|----------|
| Cell 1   | Cell 2   |
| Cell 3   | Cell 4   |
```

### Horizontal Rules

```markdown
---
```

### Links

```markdown
[Link text](https://example.com)
[Link with title](https://example.com "Title")
```

**Note:** Links may not be clickable in terminal. Display only.

### Images

```markdown
![Alt text](path/to/image.png)
![Sized image](path/to/image.png){width=50%}
```

See [Images](#images) for sizing options.

---

## ZIGPRESENTERM Extensions

### Pause Markers

Create incremental reveals:

```markdown
# My Slide

This is shown first.

<!-- pause -->

This appears after pressing next.

<!-- pause -->

And this appears last.
```

### Incremental Lists

Reveal list items one at a time:

```markdown
<!-- incremental_lists -->

- First item (shown immediately)
- Second item (revealed on next)
- Third item (revealed later)
```

### Column Layouts

Split content into columns:

```markdown
<!-- column_layout: [3, 2] -->
<!-- column: 0 -->

Left column content (60%)
- Point 1
- Point 2

<!-- column: 1 -->

Right column content (40%)
![Image](image.png)

<!-- reset_layout -->

Full width content again.
```

**Layout syntax:**
- `<!-- column_layout: [N, M, ...] -->` - Define column ratios
- `<!-- column: N -->` - Switch to column N (0-indexed)
- `<!-- reset_layout -->` - Return to full width

### Speaker Notes

Add notes for presenter (not shown):

```markdown
# My Slide

Visible content.

???

This is a speaker note.
Only visible in notes mode.
```

---

## Code Attributes

Code blocks support attributes after the language:

### Display Attributes

| Attribute | Description | Example |
|-----------|-------------|---------|
| `+line_numbers` | Show line numbers | ```` ```rust +line_numbers ```` |
| `+no_background` | No background color | ```` ```rust +no_background ```` |

### Execution Attributes

| Attribute | Description | Example |
|-----------|-------------|---------|
| `+exec` | Executable on keypress | ```` ```bash +exec ```` |
| `+exec_replace` | Auto-execute and replace | ```` ```bash +exec_replace ```` |
| `+validate` | Validate syntax only | ```` ```rust +validate ```` |

### Execution Modifiers

| Modifier | Description | Example |
|----------|-------------|---------|
| `+pty` | Run in pseudo-terminal | ```` ```bash +exec +pty ```` |
| `+pty:80:24` | PTY with size | ```` ```bash +exec +pty:80:24 ```` |
| `+pty:standby` | Show area before exec | ```` ```bash +exec +pty:standby ```` |
| `+id:name` | Name for output reference | ```` ```bash +exec +id:myoutput ```` |
| `+expect:failure` | Expect non-zero exit | ```` ```rust +validate +expect:failure ```` |

### Selective Highlighting

Highlight specific lines:

~~~markdown
```rust {1-4|6-10|all} +line_numbers
fn main() {
    println!("Lines 1-4 shown first");
    println!("Still lines 1-4");
}

fn helper() {
    println!("Lines 6-10 shown next");
    println!("Still 6-10");
}
```
~~~

**Syntax:** `{range1|range2|...}`
- `1-4` = lines 1 through 4
- `6,8,10` = lines 6, 8, and 10
- `all` = entire block

### Alternative Executors

Use different runners:

~~~markdown
```rust +exec:rust-script
// Uses rust-script instead of rustc
```

```python +exec:pytest
# Runs with pytest
```
~~~

---

## Images

### Basic Syntax

```markdown
![Alt text](path/to/image.png)
```

### Sizing

```markdown
![50% width](image.png){width=50%}
![80% width](image.png){width=80%}
```

Or using comment syntax:

```markdown
<!-- image:width:50% -->
![Alt](image.png)
```

### Supported Formats

- PNG
- JPEG
- GIF (including animated)
- WebP (terminal-dependent)

### Path Resolution

1. Relative to presentation file
2. Relative to `$XDG_CONFIG_HOME/zigpresenterm/images/`

---

## Colored Text

Use HTML span tags:

```markdown
<span style="color: red">Red text</span>
<span style="color: #ff0000">Also red</span>
<span style="background-color: yellow">Highlighted</span>
<span style="color: white; background-color: blue">White on blue</span>
```

Or use theme palette classes:

```markdown
<span class="alert">Alert text</span>
<span class="success">Success text</span>
```

(Classes defined in theme.)

---

## Font Sizes

For terminals supporting Kitty's font size protocol:

```markdown
<!-- font_size: 2 -->
# Larger Heading

<!-- font_size: 1 -->
Normal text
```

Or in theme configuration for consistent sizing.

---

## Complete Example

```markdown
---
title: "ZIGPRESENTERM Demo"
author: "Jane Doe"
date: "2026-03-01"
theme: "dark"
---

Welcome
=======

A demo of **ZIGPRESENTERM** features.

<!-- end_slide -->

Code Example
============

Here's some Zig code with execution:

```zig +exec
const std = @import("std");

pub fn main() void {
    std.debug.print("Hello from ZIGPRESENTERM!\n", .{});
}
```

<!-- end_slide -->

Column Layout
=============

<!-- column_layout: [2, 1] -->
<!-- column: 0 -->

Left side:
- Point 1
- Point 2
- Point 3

<!-- column: 1 -->

![Logo](logo.png){width=80%}

<!-- reset_layout -->

Full width again.

<!-- end_slide -->

Incremental Reveal
==================

This appears first.

<!-- pause -->

This appears second.

<!-- pause -->

This appears third.

???

Speaker notes: Walk through each point slowly.

<!-- end_slide -->

The End
=======

Thank you!

Questions?
```

---

## BNF Grammar (Simplified)

```bnf
<presentation> ::= <front_matter>? <slide>+

<front_matter> ::= "---" "\n" <yaml_content> "---" "\n"

<slide> ::= <content> <slide_separator>?

<slide_separator> ::= "<!-- end_slide -->" "\n"
                    | "---" "\n"  ; if shorthand enabled

<content> ::= <element>*

<element> ::= <heading>
            | <paragraph>
            | <code_block>
            | <list>
            | <blockquote>
            | <table>
            | <image>
            | <pause_marker>
            | <layout_directive>
            | <speaker_notes>

<heading> ::= "#"+ " " <text> "\n"
            | <text> "\n" "="+ "\n"  ; setext h1
            | <text> "\n" "-"+ "\n"  ; setext h2

<pause_marker> ::= "<!-- pause -->" "\n"

<layout_directive> ::= "<!-- column_layout:" <ratios> "-->"
                     | "<!-- column:" <number> "-->"
                     | "<!-- reset_layout -->"

<speaker_notes> ::= "???" "\n" <text>
```

---

## Changelog

- 2026-03-01: Initial file format specification

---

*File Format Spec v1.0*
