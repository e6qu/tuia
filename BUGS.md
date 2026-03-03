# Known Bugs and Missing Features

> This document tracks bugs and missing features discovered during testing.

**Last Updated:** 2026-03-03  
**Status:** Active Development

---

## 🐛 Critical Bugs

### ✅ CRITICAL-1: Race Condition in RemoteServer.start() (Fixed)
**Status:** 🟢 Fixed  
**Component:** Remote Control  
**Impact:** Medium

**Description:**  
In `src/features/remote/RemoteServer.zig`, the `start()` method has a TOCTOU (Time-of-Check-Time-of-Use) race condition. The `running` flag is checked before acquiring the mutex, but then set while holding the mutex. This allows two threads to potentially both pass the initial check before either acquires the lock, resulting in spawning two server threads.

**Location:** `src/features/remote/RemoteServer.zig:32-40`

**Fix:** Move the mutex lock before the `running` check:
```zig
pub fn start(self: *Self, navigation: *Navigation) !void {
    self.mutex.lock();
    defer self.mutex.unlock();
    
    if (self.running) return;
    
    self.navigation = navigation;
    self.running = true;
    
    self.server_thread = try std.Thread.spawn(.{}, serverLoop, .{self});
}
```

---

### ✅ CRITICAL-2: ConfigEditor Memory Leak (Fixed)
**Status:** 🟢 Fixed  
**Component:** Config Editor  
**Impact:** Medium

**Description:**  
`ConfigEditor.deinit()` does not free the cloned theme name allocated in `init()`. The `config.theme.name` is duplicated with `allocator.dupe()` but never freed.

**Location:** `src/config/ConfigEditor.zig:76,81-83`

**Fix:** Add cleanup for theme name in `deinit()`:
```zig
pub fn deinit(self: *Self) void {
    self.allocator.free(self.config.theme.name);
    self.input_buffer.deinit(self.allocator);
}
```

---

### ✅ CRITICAL-3: Code Blocks Parsed as Paragraphs (Fixed)
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

### ✅ CRITICAL-3: Integer Underflow in HelpWidget.draw() (Fixed)
**Status:** 🟢 Fixed  
**Component:** HelpWidget  
**Impact:** High

**Description:**  
In `src/widgets/HelpWidget.zig`, the `draw()` function calculates `start_row` and `start_col` using subtraction that can underflow if the content is larger than the window:

```zig
const start_row = @divTrunc(win.height, 2) - @divTrunc(line_count, 2);
const start_col = @divTrunc(win.width, 2) - @divTrunc(max_width, 2);
```

If `line_count > win.height` or `max_width > win.width`, the subtraction will cause an integer underflow (panic in debug mode).

**Location:** `src/widgets/HelpWidget.zig:90-91`

**Fix:** Use saturating arithmetic or check bounds before subtraction:
```zig
const start_row = if (line_count > win.height) 0 else @divTrunc(win.height - line_count, 2);
const start_col = if (max_width > win.width) 0 else @divTrunc(win.width - max_width, 2);
```

---

### ✅ CRITICAL-4: Integer Underflow in PresentationOverlay.prevTheme() (Fixed)
**Status:** 🟢 Fixed  
**Component:** PresentationOverlay  
**Impact:** High

**Description:**  
In `src/widgets/PresentationOverlay.zig`, the `prevTheme()` function can cause an integer underflow if `theme_names.len` is 0:

```zig
self.current_theme_index = if (self.current_theme_index == 0)
    self.theme_names.len - 1  // Underflow if len is 0!
else
    self.current_theme_index - 1;
```

**Location:** `src/widgets/PresentationOverlay.zig:136-140`

**Fix:** Check for empty theme_names or use saturating subtraction:
```zig
pub fn prevTheme(self: *Self) void {
    if (self.theme_names.len == 0) return;
    self.current_theme_index = if (self.current_theme_index == 0)
        self.theme_names.len - 1
    else
        self.current_theme_index - 1;
}
```

---

### ✅ CRITICAL-5: Integer Underflow in Renderer.drawWelcomeScreen() (Fixed)
**Status:** 🟢 Fixed  
**Component:** Renderer  
**Impact:** Medium

**Description:**  
In `src/render/Renderer.zig`, the `drawWelcomeScreen()` function uses `center_row - 1` which can underflow if `win.height` is 0 or 1:

```zig
const center_row = @divTrunc(win.height, 2);
_ = win.writeCell(col, center_row - 1, .{...});
```

**Location:** `src/render/Renderer.zig:203, 208`

**Fix:** Check window height before subtraction or use saturating arithmetic.

---

## ⚠️ High Priority Issues

### ✅ HIGH-1: MediaPlayer Thread Safety Issue (Fixed)
**Status:** 🟢 Fixed  
**Component:** Media Player  
**Impact:** Medium

**Description:**  
In `src/features/media/MediaPlayer.zig`, the `MediaPlayback.monitorPlayback()` function modifies `self.state` and `self.process` without any synchronization. If the main thread calls `stop()` while the monitor thread is running, there's a race condition accessing these shared fields.

**Location:** `src/features/media/MediaPlayer.zig:108-115`

**Fix:** Add a mutex to protect shared state:
```zig
pub const MediaPlayback = struct {
    // ... existing fields ...
    mutex: std.Thread.Mutex = .{},
    
    fn monitorPlayback(self: *Self) void {
        if (self.process) |*proc| {
            _ = proc.wait() catch {};
        }
        
        self.mutex.lock();
        self.state = .stopped;
        self.process = null;
        self.mutex.unlock();
    }
}
```

---

### ✅ HIGH-2: PdfExporter Path Extension Handling Bug (Fixed)
**Status:** 🟢 Fixed (Already correct in code)  
**Component:** PDF Export  
**Impact:** Low

**Description:**  
In `PdfExporter.getTexPath()`, if the input path contains `.pdf` anywhere in the path (not just at the end), it will incorrectly replace it. For example, `/my.pdf.files/doc.pdf` becomes `/my.tex.files/doc.tex` instead of `/my.pdf.files/doc.tex`.

**Location:** `src/export/PdfExporter.zig:99-103`

**Fix:** Use `std.mem.endsWith()` check instead of checking the whole string:
```zig
fn getTexPath(self: Self, pdf_path: []const u8) ![]const u8 {
    if (std.mem.endsWith(u8, pdf_path, ".pdf")) {
        const base = pdf_path[0 .. pdf_path.len - 4];
        return try std.mem.concat(self.allocator, u8, &.{ base, ".tex" });
    }
    return try std.mem.concat(self.allocator, u8, &.{ pdf_path, ".tex" });
}
```

---

### ✅ HIGH-3: Inline Formatting Not Parsed (Fixed)
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

### ✅ MED-1: ConfigEditor Incomplete Implementation (Fixed)
**Status:** 🟢 Fixed  
**Component:** Config Editor  
**Impact:** Medium

**Description:**  
`ConfigEditor` has incomplete functionality:
1. Only the `theme` and `presentation` sections have editable fields implemented in `confirmEdit()` - `display` and `transitions` sections do nothing when edited.
2. `getFieldCount()` returns hardcoded values but not all fields are actually editable.
3. Boolean fields show "yes/no" but can only be edited by typing numbers (for auto_advance_seconds).
4. No way to persist changes to config file - `dirty` flag is set but never used to save.

**Location:** `src/config/ConfigEditor.zig:145-164`

**Workaround:** None - the editor is for viewing only in practice.

---

### 🟡 MED-2: RemoteServer Does Not Handle HTTP Keep-Alive
**Status:** 🟡 Minor  
**Component:** Remote Control  
**Impact:** Low

**Description:**  
The RemoteServer sends `Connection: close` headers but does not properly handle connection shutdown. Modern browsers may try to reuse connections which could cause issues.

**Location:** `src/features/remote/RemoteServer.zig:168-174`

**Fix:** Properly close connection or implement HTTP/1.1 keep-alive handling.

---

### ✅ MED-3: Ordered Lists Marked as Unordered (Fixed)
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
