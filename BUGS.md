# Known Bugs and Missing Features

> This document tracks bugs and missing features discovered during testing.

**Last Updated:** 2026-03-03  
**Status:** Active Development

---

## 🐛 Critical Bugs

### ✅ CRITICAL-13: Integer Underflow in Navigation.nextSlide() (Fixed)
**Status:** 🟢 Fixed  
**Component:** Navigation  
**Impact:** High

**Description:**  
In `Navigation.nextSlide()`, if `total_slides` is 0, the expression `self.total_slides - 1` causes an integer underflow (usize wraps to max value). This leads to incorrect navigation behavior when the presentation has no slides.

**Location:** `src/core/Navigation.zig:51`

**Fix:** Add check for total_slides == 0 before subtraction:
```zig
pub fn nextSlide(self: *Self) void {
    if (self.total_slides == 0) return;  // Add this check
    if (self.current_slide < self.total_slides - 1) {
        self.current_slide += 1;
    }
}
```

---

### ✅ CRITICAL-14: Integer Underflow in Navigation.isLastSlide() (Fixed)
**Status:** 🟢 Fixed  
**Component:** Navigation  
**Impact:** High

**Description:**  
In `Navigation.isLastSlide()`, if `total_slides` is 0, the expression `self.total_slides - 1` causes an integer underflow, returning incorrect results.

**Location:** `src/core/Navigation.zig:141`

**Fix:** Add check for total_slides == 0:
```zig
pub fn isLastSlide(self: Self) bool {
    if (self.total_slides == 0) return true;  // Add this check
    return self.current_slide >= self.total_slides - 1;
}
```

---

### ✅ CRITICAL-11: Use-After-Free in MediaPlayer.spawnMediaPlayer() (Fixed)
**Status:** 🟢 Fixed  
**Component:** Media Player  
**Impact:** High

**Description:**  
In `MediaPlayer.spawnMediaPlayer()`, the `args` array is freed with `defer allocator.free(args)` immediately after `std.process.Child.init()` returns. The `Child` struct stores a pointer to the args array, but the memory is freed before the function returns, causing a use-after-free when the child process tries to access the arguments.

**Location:** `src/features/media/MediaPlayer.zig:307-310`

**Fix:** Remove the `defer` that frees `args` - the Child process owns the args memory:
```zig
const args = try argv.toOwnedSlice(allocator);
// DON'T free args here - Child stores the pointer
// defer allocator.free(args);  // REMOVE THIS LINE

return std.process.Child.init(args, allocator);
```

---

### ✅ CRITICAL-12: Buffer Overflow in ConfigParser.parseBool() (Fixed)
**Status:** 🟢 Fixed  
**Component:** Configuration  
**Impact:** High

**Description:**  
In `ConfigParser.parseBool()`, if `value.len == 16`, the check `value.len > 16` returns false, but `lower_buf` only has 16 bytes (indices 0-15). The loop writes to `lower_buf[0..15]`, but this is still a buffer overflow risk because the condition should prevent any value of length 16 or more.

**Location:** `src/config/ConfigParser.zig:178-194`

**Fix:** Change the condition to `>= 16`:
```zig
fn parseBool(value: []const u8) bool {
    if (value.len >= 16) return false;  // Fix: was > 16
    // ... rest of function
}
```

---

### ✅ CRITICAL-6: HTML Not Escaped in HtmlExporter (XSS/Invalid HTML) (Fixed)
**Status:** 🟢 Fixed  
**Component:** HTML Export  
**Impact:** High

**Description:**  
The `HtmlExporter` outputs text content directly without escaping HTML special characters (`<`, `>`, `&`, `"`). This causes:
1. Invalid HTML when content contains special characters
2. Potential XSS vulnerabilities if user content is rendered
3. Broken rendering in browsers

**Locations:**
- `src/export/HtmlExporter.zig:140` - Heading text not escaped
- `src/export/HtmlExporter.zig:146` - Paragraph text not escaped  
- `src/export/HtmlExporter.zig:165` - List item text not escaped
- `src/export/HtmlExporter.zig:174` - Blockquote text not escaped
- `src/export/HtmlExporter.zig:181` - Image alt and URL not escaped
- `src/export/HtmlExporter.zig:190` - Table header text not escaped
- `src/export/HtmlExporter.zig:200` - Table cell text not escaped

**Fix:** Use `writeEscapedHtml()` function (already exists in file) for all text output:
```zig
// Instead of:
try writer.print("<{s}>{s}</{s}>\n", .{ tag, text, tag });

// Use:
try writer.print("<{s}>", .{tag});
try writeEscapedHtml(writer, text);
try writer.print("</{s}>\n", .{tag});
```

---

### ✅ CRITICAL-7: Empty Command Array Access in CodeExecutor (Fixed)
**Status:** 🟢 Fixed  
**Component:** Code Execution  
**Impact:** High

**Description:**  
In `CodeExecutor.runWithTimeout()`, the code accesses `argv[0].?` without checking if the `cmd` array is empty. If `runner.buildCommand()` returns an empty slice, this will cause a panic.

**Location:** `src/features/executor/CodeExecutor.zig:157`

**Fix:** Add validation before accessing argv:
```zig
if (cmd.len == 0) {
    std.process.exit(127);
}
std.posix.execvpeZ(argv[0].?, argv.ptr, envp) catch {};
```

---

### ✅ CRITICAL-8: Division by Zero in AsciiArt (Fixed)
**Status:** 🟢 Fixed  
**Component:** Image Rendering  
**Impact:** Medium

**Description:**  
The `AsciiArt.render()` function performs division without checking for zero values. If `image.width` is 0, or if `output_width` or `output_height` are 0, this will cause a division by zero panic.

**Locations:**
- `src/features/images/AsciiArt.zig:30` - Division by `image.width`
- `src/features/images/AsciiArt.zig:46` - Division by `output_width`
- `src/features/images/AsciiArt.zig:47` - Division by `output_height`

**Fix:** Add zero checks before division:
```zig
if (image.width == 0 or image.height == 0) return error.InvalidImage;
if (output_width == 0 or output_height == 0) return error.InvalidDimensions;
```

---

### ✅ CRITICAL-9: Empty Buffer Access in TransitionManager (Fixed)
**Status:** 🟢 Fixed  
**Component:** Transitions  
**Impact:** High

**Description:**  
In `App.zig`, when checking if transition buffer needs capturing, the code accesses `to_buf.cells[0]` without checking if the buffer is empty. If the window dimensions are 0 (minimized or edge case), the buffer will be empty and this will panic.

**Location:** `src/App.zig:521`

**Fix:** Add bounds check before accessing cells:
```zig
if (self.transition_manager.to_buffer) |to_buf| {
    if (to_buf.cells.len == 0) return;
    const first_cell = to_buf.cells[0];
    // ... rest of logic
}
```

---

### ✅ CRITICAL-10: Bounds Check Missing in Parser Inline Functions (Fixed)
**Status:** 🟢 Fixed  
**Component:** Parser  
**Impact:** High

**Description:**  
Multiple inline parsing functions access `text[pos]` without first checking if `pos < text.len`. If the input text is empty, this will cause a panic.

**Locations:**
- `src/parser/Parser.zig:672` - `parseEmphasis()` accesses `text[pos]` without bounds check
- `src/parser/Parser.zig:713` - `parseLinkOrImage()` accesses `text[pos]` without bounds check
- `src/parser/Parser.zig:733` - `parseImage()` accesses `text[pos]` without bounds check
- `src/parser/Parser.zig:782` - `parseLink()` accesses `text[pos]` without bounds check

**Fix:** Add bounds check at the start of each function:
```zig
fn parseEmphasis(...) ParseError!?AST.Inline {
    const pos = i.*;
    if (pos >= text.len) return null;  // Add this check
    if (text[pos] != '*') return null;
    // ... rest of function
}
```

---

## ⚠️ High Priority Issues

### 🔴 HIGH-4: Memory Leak in FrontMatter.parseWithContent()
**Status:** 🔴 Open  
**Component:** Parser  
**Impact:** Medium

**Description:**  
In `FrontMatter.parseWithContent()`, if `parse()` returns an error after partially allocating front_matter fields, the allocated memory is not freed before the error propagates.

**Location:** `src/parser/FrontMatter.zig:100`

**Fix:** Add errdefer to clean up on error:
```zig
const fm = try parse(allocator, source);
// If parse fails after allocating some fields, they're leaked

// Fix: Use errdefer in parse() or handle error cleanup
```

---

### ✅ HIGH-5: Memory Leak in ConfigParser Key Bindings (Fixed)
**Status:** 🟢 Fixed  
**Component:** Configuration  
**Impact:** Medium

**Description:**  
In `ConfigParser.parseKeysKey()`, key binding strings are allocated with `allocator.dupe()` but are never freed. The `Config.deinit()` only frees `theme.name` and `theme.custom_theme_path`, not key bindings.

**Location:** `src/config/ConfigParser.zig:116-132`

**Fix:** Add cleanup for key bindings in `Config.deinit()`:
```zig
// In Config.deinit():
if (self.keys.next_slide.ptr != "j".ptr) allocator.free(self.keys.next_slide);
if (self.keys.prev_slide.ptr != "k".ptr) allocator.free(self.keys.prev_slide);
// ... etc for all keys
```

---

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
**Status:** 🟢 Fixed  
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

## 📝 Medium Priority Issues

### ✅ MED-5: Memory Leak Risk in Renderer.setCurrentSlide() (Fixed)
**Status:** 🟢 Fixed  
**Component:** Rendering  
**Impact:** Medium

**Description:**  
In `Renderer.setCurrentSlide()`, if `SlideWidget.init()` fails after the old widget is deinit'd, the slide data is lost but the old widget was already freed. This could lead to memory issues or dangling pointers in error paths.

**Location:** `src/render/Renderer.zig:97-105`

**Fix:** Store old widget and only free after successful creation, or use errdefer:
```zig
pub fn setCurrentSlide(self: *Self, slide: Slide) !void {
    const old_widget = self.current_slide_widget;
    
    // Create new slide widget
    self.current_slide_widget = try SlideWidget.init(self.allocator, slide);
    
    // Only free old widget after successful creation
    if (old_widget) |widget| {
        widget.deinit();
    }
}
```

---

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
