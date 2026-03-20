---
title: TUIA Feature Showcase
author: TUIA Developer
date: 2026-03-02
theme: dark
---

# TUIA Feature Showcase

Welcome to the comprehensive feature demonstration!

<!-- Speaker note: This is the opening slide. Press 'j' to navigate forward. -->

---

# Text Formatting

## Inline Styles

Regular text, **bold text**, *italic text*, and `inline code`.

Combined formatting: ***bold italic***, `**code with stars**`.

### Nested Headings

#### Level 4 Heading

##### Level 5 Heading

<!-- Speaker note: All heading levels are supported and styled appropriately. -->

---

# Lists

## Unordered Lists

- First item
- Second item with **bold**
- Third item with `code`
  - Nested item (if supported)
  - Another nested item
- Fourth item

## Ordered Lists

1. First step
2. Second step with *emphasis*
3. Third step
4. Final step

<!-- Speaker note: Lists can contain inline formatting. -->

---

# Code Blocks

## Zig Code

```zig
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello, TUIA!\n", .{});
    
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    
    const allocator = gpa.allocator();
    const message = try allocator.dupe(u8, "Memory safe!");
    defer allocator.free(message);
    
    try stdout.print("{s}\n", .{message});
}
```

---

# Code Blocks (Continued)

## Python Code

```python
def fibonacci(n):
    """Generate Fibonacci sequence up to n."""
    a, b = 0, 1
    result = []
    while a < n:
        result.append(a)
        a, b = b, a + b
    return result

# Print first 10 Fibonacci numbers
print(fibonacci(100))
```

## JavaScript Code

```javascript
// Fetch data from API
async function fetchData(url) {
    try {
        const response = await fetch(url);
        const data = await response.json();
        console.log('Data:', data);
        return data;
    } catch (error) {
        console.error('Error:', error);
        throw error;
    }
}
```

---

# Blockquotes

> "The best way to predict the future is to invent it."
> — Alan Kay

> **Note:** This is a blockquote with formatting.
> It can span multiple lines.

<!-- Speaker note: Blockquotes are styled with distinctive borders. -->

---

# Thematic Breaks

Content before the break.

***

Content after the break.

---

# Special Characters

## Unicode Support

- Emojis: 🎉 🚀 💻 ✅
- Mathematical symbols: ∑ ∏ ∫ √
- Arrows: ← → ↑ ↓ ↔
- Box drawing: ┌─┐└┘│─
- Currency: $ € £ ¥

## Escape Sequences

- \*asterisks\* (not bold)
- \`backticks\` (not code)
- \\ backslash

---

# Tables (if supported)

| Feature | Status | Priority |
|---------|--------|----------|
| Markdown parsing | ✅ Done | High |
| Syntax highlighting | ✅ Done | High |
| Code execution | ✅ Done | Medium |
| Image support | ✅ Done | Medium |
| PDF export | 🚧 Planned | Low |

<!-- Speaker note: Tables may or may not be rendered depending on parser support. -->

---

# Code Execution Demo

## Python Script

```python
#!/usr/bin/env python3
print("Hello from executed code!")
print("1 + 2 =", 1 + 2)
```

Press **'e'** to execute this code block!

<!-- Speaker note: Press 'e' on this slide to run the Python code. -->

---

# Links and References

## URLs

- https://github.com/e6qu/tuia
- https://ziglang.org/

## Reference Links

Check out [Zig][zig-link] for more info.

[zig-link]: https://ziglang.org/

<!-- Speaker note: Links may be displayed as text or clickable depending on terminal support. -->

---

# Advanced Features

## Line Breaks

Line one  
Line two (double space for hard break)

Line one<br/>Line two (HTML br tag)

## Horizontal Rules

Three styles:

---

***

___

---

# Thank You!

## Questions?

**TUIA** — Terminal UI Application

Built with ❤️ using [Zig](https://ziglang.org/)

```
    _____ _   _ ___
   |_   _| | | |_ _|
     | | | | | || |
     | | | |_| || |
     |_|  \___/|___|
```

<!-- Speaker note: Thank you for using TUIA! Press 'q' to quit. -->

