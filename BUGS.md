# Known Bugs and Missing Features

> This document tracks bugs and missing features discovered during testing.

**Last Updated:** 2026-03-02  
**Status:** Active Development

---

## 🐛 Critical Bugs

### ✅ CRITICAL-1: Code Blocks Parsed as Paragraphs
**Status:** 🟢 Fixed  
**Component:** Parser  
**Impact:** High

**Description:**  
Code blocks (```) were being parsed as plain paragraphs instead of being preserved as code blocks with language metadata.

**Fix:** `src/parser/Parser.zig`
- Rewrote `parseCodeBlock()` to properly extract language and code content
- Added `extractLanguage()` helper to parse language from opener line
- Added `isCodeBlockEnd()` helper to detect closing ```
- Code content is preserved exactly with newlines

**Verification:**
```zig
// Input:
\```zig
\const x = 42;
\```

// Result:
code_block.language = "zig"
code_block.code = "const x = 42;"
```

---

## ⚠️ High Priority Issues

### ✅ HIGH-1: Inline Formatting Not Parsed
**Status:** 🟢 Fixed  
**Component:** Parser  
**Impact:** High

**Description:**  
Inline markdown formatting was not being parsed - bold, italic, inline code, links, and images appeared as literal text.

**Fix:** `src/parser/Parser.zig`
- Added `parseInlineContent()` function that processes inline markdown within text
- Supports:
  - `**bold**` → `Inline.strong`
  - `*italic*` → `Inline.emphasis`
  - `` `code` `` → `Inline.code`
  - `[text](url)` → `Inline.link`
  - `![alt](url)` → `Inline.image`

**Verification:**
```zig
// Input: "Hello **bold** world"
// Result: [text("Hello "), strong([text("bold")]), text(" world")]
```

---

### ✅ HIGH-2: Images Not Supported
**Status:** 🔴 Open  
**Component:** Scanner/Parser/Renderer  
**Impact:** High

**Description:**  
Image syntax `![alt text](url)` is not recognized by the scanner. While the AST and core types define `Image` structures, they are never populated.

**Locations:**
- `src/parser/Token.zig:26` - Token type exists
- `src/parser/AST.zig` - `Image` struct and `Inline.image` exist
- `src/core/Element.zig:10` - `Element.image` exists
- `src/parser/Scanner.zig` - No image tokenization

**Expected Behavior:**  
Images should be:
1. Tokenized by the scanner
2. Parsed into AST
3. Converted to core types
4. Rendered using appropriate protocol (Kitty/iTerm2/Sixel/ASCII)

**Workaround:** None

---

### HIGH-3: Speaker Notes Not Implemented
**Status:** 🔴 Open  
**Component:** Parser  
**Impact:** Medium

**Description:**  
HTML comments meant for speaker notes (`<!-- Speaker note: ... -->`) are stripped by the scanner but not preserved for display.

**Location:** `src/parser/Scanner.zig:41-43`
```zig
// Skip other HTML comments
_ = self.consumeUntil("-->");
return self.nextToken();
```

**Expected Behavior:**  
Speaker notes should be:
1. Preserved during parsing
2. Associated with the current slide
3. Displayable in a notes view (e.g., separate window or overlay)

**Workaround:** None

---

## 📝 Medium Priority Issues

### MED-1: Ordered Lists Marked as Unordered
**Status:** 🔴 Open  
**Component:** Parser  
**Impact:** Medium

**Description:**  
Numbered lists (1., 2., 3.) are parsed but the `ordered` flag is hardcoded to `false`.

**Location:** `src/parser/Parser.zig:203-206`
```zig
return .{ .list = .{
    .ordered = false,  // Should detect from input
    .items = try items.toOwnedSlice(self.allocator),
} };
```

**Expected Behavior:**  
Lists starting with numbers should have `ordered: true` and render with numbers instead of bullets.

**Workaround:** None

---

### MED-2: Nested Lists Not Supported
**Status:** 🔴 Open  
**Component:** Parser  
**Impact:** Medium

**Description:**  
Nested list items (indented with 2+ spaces) are not properly parsed as children of parent items.

**Example:**
```markdown
- Parent
  - Child 1
  - Child 2
```

**Expected Behavior:**  
Nested items should be represented hierarchically in the AST.

**Workaround:** Use flat lists only

---

### MED-3: Tables Not Supported
**Status:** 🔴 Open  
**Component:** Scanner/Parser  
**Impact:** Medium

**Description:**  
Markdown tables are not recognized:
```markdown
| Column 1 | Column 2 |
|----------|----------|
| Data 1   | Data 2   |
```

**Note:** This is not in the current AST or Token definitions.

**Expected Behavior:**  
Tables should be parsed and renderable.

**Workaround:** Use code blocks or lists to represent tabular data

---

### MED-4: Reference-Style Links Not Parsed
**Status:** 🔴 Open  
**Component:** Parser  
**Impact:** Low

**Description:**  
Reference-style links are not supported:
```markdown
[text][ref]

[ref]: https://example.com
```

**Expected Behavior:**  
References should be resolved and converted to regular links.

**Workaround:** Use inline links `[text](url)` (when inline links are implemented)

---

## 🔧 Low Priority Issues

### LOW-1: Hard Line Breaks Not Supported
**Status:** 🔴 Open  
**Component:** Parser  
**Impact:** Low

**Description:**  
Hard line breaks (two spaces + newline, or `<br/>`) are not converted to line breaks.

**Expected Behavior:**  
- `Line 1  \nLine 2` should render as two lines
- `Line 1<br/>Line 2` should render as two lines

**Workaround:** Use separate paragraphs

---

### LOW-2: Escape Sequences Not Processed
**Status:** 🔴 Open  
**Component:** Scanner/Parser  
**Impact:** Low

**Description:**  
Escaped characters (`\*`, `\``, `\\`) appear literally instead of being unescaped.

**Expected Behavior:**  
`\*text\*` should render as *text* (literal asterisks, not bold)

**Workaround:** None

---

### LOW-3: Horizontal Rules Variations
**Status:** 🟡 Partial  
**Component:** Scanner  
**Impact:** Low

**Description:**  
Only `---` is recognized as a thematic break. `***` and `___` are not recognized.

**Location:** `src/parser/Scanner.zig:54-58`

**Expected Behavior:**  
All three forms should produce `.thematic_break` tokens.

**Workaround:** Use `---` only

---

## ✅ Working Features

The following features have been verified to work:

### Parsing
- ✅ Front matter (YAML metadata: title, author, date, theme)
- ✅ Slide separation (`---`)
- ✅ Headings (levels 1-6)
- ✅ Paragraphs
- ✅ Basic unordered lists (`-`, `*`, `+`)
- ✅ Basic ordered lists (numbers - but rendered as unordered)
- ✅ Blockquotes (`>`)
- ✅ Thematic breaks (`---`)
- ✅ Blank line handling

### Core/Conversion
- ✅ AST to core type conversion
- ✅ Metadata preservation
- ✅ Slide structure preservation

### Rendering
- ✅ Basic slide display
- ✅ Navigation (j/k, arrow keys)
- ✅ Theme application

---

## Test Coverage

Run the feature showcase to verify current state:

```bash
# Build and test
zig build test

# Test specific file parsing
zig build && ./zig-out/bin/tuia examples/feature-showcase.md
```

---

## Feature Matrix

| Feature | Tokenize | Parse | Convert | Render | Status |
|---------|----------|-------|---------|--------|--------|
| Front matter | ✅ | ✅ | ✅ | ✅ | Complete |
| Headings | ✅ | ✅ | ✅ | ✅ | Complete |
| Paragraphs | ✅ | ✅ | ✅ | ✅ | Complete |
| Unordered lists | ✅ | ✅ | ✅ | ✅ | Complete |
| Ordered lists | ✅ | ⚠️ | ⚠️ | ⚠️ | Parser bug |
| Code blocks | ✅ | ✅ | ✅ | ✅ | Complete |
| Blockquotes | ✅ | ✅ | ✅ | ✅ | Complete |
| Thematic breaks | ✅ | ✅ | ✅ | ✅ | Complete |
| **Inline formatting** | ✅ | ✅ | ✅ | ⚠️ | **Parsed, needs render** |
| Bold/Strong | ✅ | ✅ | ✅ | ⚠️ | Parsed, needs render |
| Italic/Emphasis | ✅ | ✅ | ✅ | ⚠️ | Parsed, needs render |
| Inline code | ✅ | ✅ | ✅ | ⚠️ | Parsed, needs render |
| Links | ✅ | ✅ | ✅ | ⚠️ | Parsed, needs render |
| Images | ✅ | ✅ | ✅ | ⚠️ | Parsed, needs render |
| Speaker notes | ⚠️ | ❌ | ❌ | ❌ | Stripped by scanner |
| Nested lists | ❌ | ❌ | ❌ | ❌ | Not implemented |
| Tables | ❌ | ❌ | ❌ | ❌ | Not in spec |
| Hard breaks | ❌ | ❌ | ❌ | ❌ | Not implemented |

Legend: ✅ Complete | ⚠️ Partial/Buggy | ❌ Missing

---

## Related Files

- `src/parser/Scanner.zig` - Tokenization
- `src/parser/Token.zig` - Token definitions
- `src/parser/Parser.zig` - Parsing logic
- `src/parser/AST.zig` - AST types
- `src/parser/Converter.zig` - AST to core conversion
- `src/core/Element.zig` - Core element types
- `src/render/` - Rendering widgets

---

*This document should be updated as bugs are fixed or new issues are discovered.*
