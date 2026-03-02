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

### ✅ HIGH-3: Speaker Notes Not Implemented
**Status:** 🟢 Fixed  
**Component:** Parser/Core  
**Impact:** Medium

**Description:**  
HTML comments meant for speaker notes (`<!-- Speaker note: ... -->`) were stripped by the scanner.

**Fix:**
- Added `speaker_note` token type to `Token.zig`
- Modified `Scanner.zig` to recognize `<!-- Speaker note: ... -->` comments
- Added `speaker_notes` field to `AST.Slide` and `core.Slide`
- Updated `Parser.zig` to collect speaker notes for each slide
- Added `extractSpeakerNotes()` helper function
- Updated `Converter.zig` to pass notes through

**Usage:**
```markdown
# Slide Title
Content here
<!-- Speaker note: Remember to mention key points -->
```

**Note:** Multiple speaker notes on one slide are combined with newlines.

---

## 📝 Medium Priority Issues

### ✅ MED-1: Ordered Lists Marked as Unordered
**Status:** 🟢 Fixed  
**Component:** Parser/Scanner  
**Impact:** Medium

**Description:**  
Numbered lists (1., 2., 3.) were parsed but the `ordered` flag was hardcoded to `false`.

**Fix:**
- Added `ordered_list_item` token type to `Token.zig`
- Modified `Scanner.zig` to emit `.ordered_list_item` for numbered lists
- Updated `Parser.zig` `parseBlockElement()` to handle both token types
- Modified `parseList()` to accept `ordered` parameter

**Verification:**
```zig
// Input: "1. First\n2. Second"
// Result: list.ordered = true

// Input: "- First\n- Second"
// Result: list.ordered = false
```

---

### ✅ MED-2: Nested Lists Not Supported
**Status:** 🟢 Fixed  
**Component:** Parser/Scanner/Core  
**Impact:** Medium

**Description:**  
Nested list items (indented with 2+ spaces) were not properly parsed as children of parent items.

**Fix:**
- Added `indent` field to `Token` struct to track indentation level
- Added `calculateIndent()` function to `Scanner` to measure leading whitespace
- Updated `AST.ListItem` with `children: ?*List` field for nested lists
- Updated `core.ListItem` with `children: ?*List` field
- Rewrote `parseList()` to track base indentation and recursively parse nested items
- Updated `Converter` to handle nested list conversion

**Example:**
```markdown
- Parent
  - Child 1
  - Child 2
```

**Result:**
```zig
list.items[0].children = List{ // nested list
    .ordered = false,
    .items = [Child 1, Child 2]
}
```

---

### ✅ MED-3: Tables Not Supported
**Status:** 🟢 Fixed  
**Component:** Scanner/Parser/Core  
**Impact:** Medium

**Description:**  
Markdown tables were not recognized.

**Fix:**
- Added `table_row` and `table_separator` token types
- Added `isTableSeparator()` helper to Scanner
- Added `Table`, `TableCell`, and `Alignment` types to AST
- Added `parseTable()`, `parseTableRow()`, `parseTableAlignments()`, `parseTableCells()` functions
- Updated `parseBlockElement()` to handle table rows
- Added core `Table` type with HTML export support
- Added basic widget support (placeholder)

**Example:**
```markdown
| Name | Age |
|------|-----|
| John | 30  |
```

**Parsed Result:**
```zig
table.headers = ["Name", "Age"]
table.rows = [["John", "30"]]
table.alignments = [.default, .default]
```

**Workaround:** Use code blocks or lists to represent tabular data

---

### ✅ MED-4: Reference-Style Links Not Parsed
**Status:** 🟢 Fixed  
**Component:** Parser/Converter  
**Impact:** Low

**Description:**  
Reference-style links were not supported.

**Fix:**
- Added `link_ref_def` token type to Token.zig
- Added `isLinkRefDef()` method to Scanner
- Added `link_references: std.StringHashMap([]const u8)` to AST.Presentation
- Added `parseLinkRefDef()` to Parser to collect reference definitions
- Updated `AST.Link` with optional `ref_label` field
- Updated `parseInlineContent()` to handle `[text][label]` and `[text]` syntax
- Updated Converter to resolve references during conversion

**Example:**
```markdown
[example]: https://example.com

Click [here][example] or [example]
```

**Supported Formats:**
- `[text](url)` - inline links
- `[text][label]` - reference-style with explicit label
- `[text]` - reference-style with implicit label (text is the label)

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
| Ordered lists | ✅ | ✅ | ✅ | ✅ | Complete |
| Code blocks | ✅ | ✅ | ✅ | ✅ | Complete |
| Blockquotes | ✅ | ✅ | ✅ | ✅ | Complete |
| Thematic breaks | ✅ | ✅ | ✅ | ✅ | Complete |
| **Inline formatting** | ✅ | ✅ | ✅ | ⚠️ | **Parsed, needs render** |
| Bold/Strong | ✅ | ✅ | ✅ | ⚠️ | Parsed, needs render |
| Italic/Emphasis | ✅ | ✅ | ✅ | ⚠️ | Parsed, needs render |
| Inline code | ✅ | ✅ | ✅ | ⚠️ | Parsed, needs render |
| Links | ✅ | ✅ | ✅ | ⚠️ | Parsed, needs render |
| Images | ✅ | ✅ | ✅ | ⚠️ | Parsed, needs render |
| Speaker notes | ✅ | ✅ | ✅ | ⚠️ | Parsed (needs display UI) |
| Nested lists | ✅ | ✅ | ✅ | ⚠️ | Parsed (widget needs update) |
| Tables | ✅ | ✅ | ✅ | ⚠️ | Parsed (widget needs work) |
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
