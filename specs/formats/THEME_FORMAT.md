# Theme Format Specification

> Specification for ZIGPRESENTERM theme files.

**Status:** 📝 Draft  
**Owner:** @team  
**Date:** 2026-03-01  
**Related:** [FILE_FORMAT.md](FILE_FORMAT.md), [CONFIG_FORMAT.md](CONFIG_FORMAT.md)

---

## Overview

Themes define the visual appearance of presentations. They are YAML files that specify colors, fonts, spacing, and styling for all elements.

**File Extension:** `.yaml`  
**MIME Type:** `application/yaml`  
**Encoding:** UTF-8

---

## File Structure

```yaml
# Theme metadata
name: "Theme Name"
author: "Author Name"
version: "1.0.0"

# Default styles applied to all slides
default:
  margin:
    # ...
  colors:
    # ...

# Element-specific styles
intro_slide:
  # ...

slide_title:
  # ...

headings:
  # ...

# ... etc
```

---

## Color Specification

### Hex Colors

```yaml
colors:
  foreground: "e6e6e6"      # 6-digit hex
  background: "040312"      # No # prefix
  accent: "ff5733"          # RGB
```

### Named Colors

A subset of CSS named colors:

```yaml
colors:
  foreground: "white"
  background: "black"
  error: "red"
  success: "green"
```

**Supported names:**
- Basic: `black`, `white`, `red`, `green`, `blue`, `yellow`, `magenta`, `cyan`
- Extended: `gray`, `darkgray`, `lightgray`, `darkred`, `darkgreen`, etc.

### Terminal Colors

Reference terminal palette:

```yaml
colors:
  foreground: "terminal.white"
  background: "terminal.black"
  accent: "terminal.bright_blue"
```

**Terminal palette:**
- `terminal.black` through `terminal.white`
- `terminal.bright_black` through `terminal.bright_white`
- `terminal.0` through `terminal.15` (indexed)

---

## Common Properties

### Alignment

```yaml
alignment: left       # or center, right

# For left/right alignment:
margin:
  fixed: 5            # exact columns
  # OR
  percent: 8          # percentage of width

# For center alignment:
minimum_size: 40      # minimum width
minimum_margin:
  percent: 8          # minimum side margins
```

### Colors Block

```yaml
colors:
  foreground: "e6e6e6"     # text color
  background: "040312"     # background color
```

### Text Styles

```yaml
bold: true
italic: true
underlined: true
strikethrough: false
```

---

## Top-Level Sections

### `default`

Applied to all slides as base styling.

```yaml
default:
  margin:
    left:
      percent: 8
    right:
      percent: 8
    top: 1
    bottom: 0
  
  colors:
    foreground: "e6e6e6"
    background: "040312"
```

### `intro_slide`

Styling for the title/introduction slide.

```yaml
intro_slide:
  title:
    alignment: center
    colors:
      foreground: "ffffff"
    bold: true
    font_size: 2          # Kitty font size protocol
  
  subtitle:
    alignment: center
    colors:
      foreground: "aaaaaa"
    italics: true
  
  author:
    alignment: center
    positioning: page_bottom   # or below_title
    colors:
      foreground: "888888"
```

### `slide_title`

Styling for slide titles (setext headers).

```yaml
slide_title:
  prefix: "██"            # Prefix character(s)
  font_size: 2            # Font size (Kitty)
  padding_top: 1          # Lines before
  padding_bottom: 1       # Lines after
  separator: true         # Horizontal line after
  bold: true
  underlined: false
  italics: false
  colors:
    foreground: "beeeff"
    background: "feeedd"
  alignment: center
  margin:
    percent: 8
```

### `headings`

Styling for H1-H6.

```yaml
headings:
  h1:
    prefix: "██"
    colors:
      foreground: "beeeff"
    bold: true
    underlined: false
    italics: false
  
  h2:
    prefix: "▓▓▓"
    colors:
      foreground: "feeedd"
    bold: true
  
  h3:
    prefix: "▒▒▒▒"
    colors:
      foreground: "eeeeee"
  
  h4:
    prefix: "░░░░░"
  
  h5:
    bold: true
  
  h6:
    italics: true
```

### `paragraph`

```yaml
paragraph:
  colors:
    foreground: "e6e6e6"
  alignment: left
  margin:
    percent: 8
```

### `code`

Code block styling.

```yaml
code:
  # Block styling
  block:
    background: "1a1a2e"
    foreground: "eaeaea"
    padding: 1              # Lines of padding
    alignment: left
    margin:
      percent: 4
  
  # Inline code
  inline:
    background: "2a2a3e"
    foreground: "ff6b6b"
  
  # Line numbers
  line_numbers:
    foreground: "666666"
    background: "1a1a2e"
    padding_right: 2
  
  # Syntax highlighting colors
  syntax:
    keyword: "ff79c6"
    string: "f1fa8c"
    comment: "6272a4"
    function: "50fa7b"
    number: "bd93f9"
    type: "8be9fd"
    operator: "ff79c6"
```

### `list`

```yaml
list:
  marker:
    unordered: "•"        # or "-", "*", "▸"
    ordered: "."          # "1.", "2." etc
    colors:
      foreground: "ffffff"
  
  indentation: 2          # Spaces per level
  
  colors:
    foreground: "e6e6e6"
```

### `block_quote`

```yaml
block_quote:
  prefix: "▍ "
  colors:
    foreground: "aaaaaa"
    background: "1a1a2e"
  margin:
    percent: 8
  padding: 1
```

### `table`

```yaml
table:
  header:
    colors:
      foreground: "ffffff"
      background: "333333"
    bold: true
  
  rows:
    colors:
      foreground: "cccccc"
    alternating:
      colors:
        background: "1a1a2e"
  
  border:
    style: "simple"       # or "rounded", "heavy", "none"
    colors:
      foreground: "666666"
```

### `footer`

```yaml
footer:
  # Style: template, progress_bar, or empty
  style: template
  
  # For template style:
  left: "My **name** is {author}"
  center: "_{event}_"
  right: "{current_slide} / {total_slides}"
  height: 2
  
  colors:
    foreground: "888888"
  
  # For progress_bar style:
  # style: progress_bar
  # character: "█"
  
  # For no footer:
  # style: empty
```

**Template variables:**
- `{title}` - Presentation title
- `{subtitle}` - Presentation subtitle
- `{author}` - Author name
- `{event}` - Event name
- `{location}` - Location
- `{date}` - Date
- `{current_slide}` - Current slide number
- `{total_slides}` - Total slide count

**Markdown in templates:**
Templates support basic markdown: `**bold**`, `_italic_`, `[links](url)`

### `image`

```yaml
image:
  border: true
  border_style: "rounded"
  border_color: "666666"
  
  # Default sizing
  default_width: 50       # Percent
  max_height: 80          # Percent of terminal height
```

### `link`

```yaml
link:
  colors:
    foreground: "8be9fd"
  underlined: true
```

### `emphasis`

```yaml
emphasis:
  bold:
    bold: true
    colors:
      foreground: "ffffff"
  
  italic:
    italics: true
    colors:
      foreground: "aaaaaa"
  
  strikethrough:
    strikethrough: true
```

---

## Palette Section

Define reusable color classes.

```yaml
palette:
  classes:
    alert:
      foreground: "ff5555"
      background: "440000"
    
    success:
      foreground: "50fa7b"
      background: "004400"
    
    info:
      foreground: "8be9fd"
      background: "001144"
    
    warning:
      foreground: "f1fa8c"
      background: "444400"
```

Usage in presentation:

```markdown
<span class="alert">This is an alert!</span>
<span class="success">Success message</span>
```

---

## Complete Example: Dark Theme

```yaml
name: "Dark"
author: "ZIGPRESENTERM Team"
version: "1.0.0"

default:
  margin:
    left:
      percent: 8
    right:
      percent: 8
    top: 1
    bottom: 0
  colors:
    foreground: "e6e6e6"
    background: "0f0f1a"

intro_slide:
  title:
    alignment: center
    font_size: 2
    colors:
      foreground: "ffffff"
    bold: true
  
  subtitle:
    alignment: center
    colors:
      foreground: "aaaaaa"
    italics: true
  
  author:
    alignment: center
    positioning: page_bottom
    colors:
      foreground: "666666"

slide_title:
  prefix: ""
  font_size: 1
  padding_top: 1
  padding_bottom: 1
  separator: true
  bold: true
  colors:
    foreground: "ff79c6"
  alignment: left

headings:
  h1:
    prefix: ""
    colors:
      foreground: "ff79c6"
    bold: true
    font_size: 2
  
  h2:
    prefix: ""
    colors:
      foreground: "bd93f9"
    bold: true
  
  h3:
    colors:
      foreground: "8be9fd"
    bold: true
  
  h4:
    colors:
      foreground: "50fa7b"
  
  h5:
    colors:
      foreground: "f1fa8c"
  
  h6:
    colors:
      foreground: "ffb86c"
    italics: true

paragraph:
  colors:
    foreground: "e6e6e6"
  alignment: left

code:
  block:
    background: "1a1a2e"
    foreground: "f8f8f2"
    padding: 1
  
  inline:
    background: "2a2a3e"
    foreground: "ff79c6"
  
  line_numbers:
    foreground: "6272a4"
    background: "1a1a2e"
  
  syntax:
    keyword: "ff79c6"
    string: "f1fa8c"
    comment: "6272a4"
    function: "50fa7b"
    number: "bd93f9"
    type: "8be9fd"
    operator: "ff79c6"

list:
  marker:
    unordered: "•"
    colors:
      foreground: "ff79c6"

block_quote:
  prefix: "▍ "
  colors:
    foreground: "aaaaaa"
  border_left: true
  border_color: "ff79c6"

table:
  header:
    colors:
      foreground: "ffffff"
      background: "44475a"
    bold: true
  
  rows:
    alternating:
      colors:
        background: "1a1a2e"
  
  border:
    colors:
      foreground: "6272a4"

footer:
  style: template
  left: ""
  center: "{current_slide} / {total_slides}"
  right: ""
  height: 1
  colors:
    foreground: "6272a4"

link:
  colors:
    foreground: "8be9fd"
  underlined: true

palette:
  classes:
    alert:
      foreground: "ff5555"
    success:
      foreground: "50fa7b"
    info:
      foreground: "8be9fd"
    warning:
      foreground: "f1fa8c"
```

---

## JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ZIGPRESENTERM Theme",
  "type": "object",
  "required": ["name"],
  "properties": {
    "name": {"type": "string"},
    "author": {"type": "string"},
    "version": {"type": "string"},
    "default": {
      "type": "object",
      "properties": {
        "margin": {"$ref": "#/definitions/margin"},
        "colors": {"$ref": "#/definitions/colors"}
      }
    }
  },
  "definitions": {
    "color": {
      "type": "string",
      "pattern": "^[a-fA-F0-9]{6}$|^[a-z]+$|^terminal\.[a-z_]+$"
    },
    "colors": {
      "type": "object",
      "properties": {
        "foreground": {"$ref": "#/definitions/color"},
        "background": {"$ref": "#/definitions/color"}
      }
    },
    "margin": {
      "type": "object",
      "properties": {
        "left": {"$ref": "#/definitions/marginValue"},
        "right": {"$ref": "#/definitions/marginValue"},
        "top": {"type": "integer"},
        "bottom": {"type": "integer"}
      }
    },
    "marginValue": {
      "oneOf": [
        {"type": "integer"},
        {"type": "object", "properties": {
          "fixed": {"type": "integer"},
          "percent": {"type": "integer"}
        }}
      ]
    }
  }
}
```

---

## Changelog

- 2026-03-01: Initial theme format specification

---

*Theme Format Spec v1.0*
