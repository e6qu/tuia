# TUIA Demo

A showcase of TUIA features

<!-- note: Welcome to the TUIA demo! This presentation showcases all the major features. -->

---

## Text Formatting

**Bold text** for emphasis

*Italic text* for style

~~Strikethrough~~ for corrections

`Inline code` for technical terms

---

## Lists

Unordered lists:

- First item
- Second item
  - Nested item A
  - Nested item B
- Third item

Ordered lists:

1. Step one
2. Step two
3. Step three

---

## Code Highlighting

### Zig

```zig
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello, {s}!\n", .{"World"});
}
```

---

## More Languages

### Python

```python
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

print(f"Fib(10) = {fibonacci(10)}")
```

### JavaScript

```javascript
const greet = (name) => {
    console.log(`Hello, ${name}!`);
};

greet("World");
```

---

## Blockquotes

> "The best way to predict the future is to invent it."
>
> — Alan Kay

> Simplicity is the ultimate sophistication.

---

## Speaker Notes

This slide has speaker notes!

<!-- note: These are speaker notes. Press 'n' (configurable) to view them during the presentation. They're great for reminders and additional context that you don't want on the slide itself. -->

---

## Navigation Help

| Key | Action |
|-----|--------|
| j, ↓, Space | Next slide |
| k, ↑, Backspace | Previous slide |
| g | First slide |
| G | Last slide |
| 1-9 | Jump to slide |
| ? | Show help |
| q | Quit |

---

## The End

Thanks for trying TUIA!

**GitHub:** https://github.com/e6qu/tuia

<!-- note: Thank the audience and mention where to find more information. -->
