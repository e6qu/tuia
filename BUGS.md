# Known Bugs and Missing Features

> This document tracks bugs and missing features discovered during testing.

**Last Updated:** 2026-03-03
**Open Bug Count:** 0  
**Status:** All Known Bugs Fixed

---

## 📊 Bug Summary

| Category | Open | Fixed (Recent) | Total |
|----------|------|----------------|-------|
| Critical | 0 | 17 | 17 |
| High | 0 | 6 | 6 |
| Medium | 0 | 6 | 6 |
| Low | 0 | 3 | 3 |

**Note:** HIGH-4 was verified as already protected by errdefer. LOW-2 and LOW-3 fixed in Phase 10. LOW-1 and MED-2 fixed in Phase 12.

**Recent Bug Hunts:** Phase 1-9 completed (17 critical bugs fixed)

---

## 🔴 Open Bugs (0 Remaining)

**All known bugs have been fixed!**

### HIGH-4: Memory Leak in FrontMatter.parseWithContent()
**Status:** ✅ Fixed (Code Review)  
**Component:** Parser  
**Impact:** Medium

**Description:**  
Initial analysis suggested a memory leak in error paths, but code review revealed that `parse()` already has proper `errdefer front_matter.deinit(allocator);` handling (line 40). This ensures cleanup of partially allocated fields if an allocation fails.

**Verification:**  
- Code review confirms `errdefer` is correctly placed
- All FrontMatter tests pass
- Valgrind shows no leaks in test scenarios

**Location:** `src/parser/FrontMatter.zig:40` (errdefer protection)

---

### MED-2: RemoteServer Does Not Handle HTTP Keep-Alive
**Status:** ✅ Fixed  
**Component:** Remote Control  
**Impact:** Low

**Description:**  
The RemoteServer sent `Connection: close` headers but did not properly shut down the write side of the connection before closing.

**Fix:**  
Used `posix.shutdown()` directly on the socket handle to shut down the send side of the connection after handling each request. This properly signals to clients that the server has finished sending data.

**Location:** `src/features/remote/RemoteServer.zig:131-134` (posix.shutdown call)

---

## 🔧 Low Priority Issues

### LOW-1: Hard Line Breaks Not Supported
**Status:** ✅ Fixed  
**Component:** Parser  
**Impact:** Low

Hard line breaks (two spaces + newline, or `<br/>`) were not converted to line breaks.

**Fix:** 
1. Scanner now detects two spaces at end of line and emits `line_break` token
2. Parser now handles `<br>`, `<br/>`, and `<br />` HTML tags as line breaks
3. Added `pending_line_break` state to Scanner for proper token sequencing

**Location:** 
- `src/parser/Scanner.zig` - Hard break detection (two spaces)
- `src/parser/Parser.zig` - HTML `<br>` tag parsing

---

### LOW-2: Escape Sequences Not Processed
**Status:** ✅ Fixed  
**Component:** Parser  
**Impact:** Low

Escaped characters (`\*`, `\``, `\\`) appear literally instead of being unescaped.

**Fix:** Added `unescapeText()` function in Parser.zig that processes escape sequences when creating text nodes. Handles: `\\`, `\*`, `\``, `\[`, `\]`, `\(`, `\)`, `\#`, `\+`, `\-`, `\.`, `\!`, `\<`, `\>`, `\_`.

**Location:** `src/parser/Parser.zig` (unescapeText function)

---

### LOW-3: Horizontal Rules Variations
**Status:** ✅ Fixed  
**Component:** Scanner  
**Impact:** Low

Only `---` is recognized as a thematic break. `***` and `___` are not recognized.

**Fix:** Added support for `***` and `___` as thematic breaks in Scanner.zig.

**Location:** `src/parser/Scanner.zig` (lines 83-95)

---

## ✅ Recently Fixed Bugs (Phase 1-9)

### Critical Bugs Fixed
- **CRITICAL-17:** CssGenerator RGB color handling
- **CRITICAL-15:** TextWidget freeing unallocated literal
- **CRITICAL-16:** CodeWidget division by zero
- **CRITICAL-13/14:** Navigation integer underflows
- **CRITICAL-11:** MediaPlayer use-after-free
- **CRITICAL-12:** ConfigParser buffer overflow
- **CRITICAL-6:** HTML escaping in HtmlExporter
- **CRITICAL-7:** Empty command array access
- **CRITICAL-8:** AsciiArt division by zero
- **CRITICAL-9:** TransitionManager empty buffer access
- **CRITICAL-10:** Parser bounds checks

### High/Medium Bugs Fixed
- **HIGH-5:** ConfigParser key binding memory leak
- **MED-5:** Renderer.setCurrentSlide() memory leak risk
- Plus 8 more historical fixes

See git history for complete fix details.

---

## 🛡️ Prevention Measures

To prevent similar bugs, we now enforce:

1. **Bounds Checking:** All array/slice accesses must check bounds
2. **Integer Safety:** Check for zero before subtraction/division
3. **Memory Safety:** Use `errdefer` for cleanup, verify allocations
4. **String Literal Safety:** Never free string literals
5. **Null Checks:** Verify optional values before unwrapping

### Automated Enforcement
- **Semgrep SAST:** 4 rule sets automatically scan all PRs
- **Custom Zig Linter:** AST-based pattern detection in CI
- **Valgrind:** Memory leak detection on every PR
- **Fuzzing:** Daily automated fuzzing runs

See `docs/CODING_STANDARDS.md` for detailed guidelines.

---

## ✅ Working Features

### Parsing
- ✅ Front matter (YAML metadata)
- ✅ Slide separation (`---`)
- ✅ Headings (levels 1-6)
- ✅ Paragraphs, lists, code blocks
- ✅ Blockquotes, thematic breaks

### Rendering
- ✅ Basic slide display
- ✅ Navigation (j/k, arrow keys)
- ✅ Theme application
- ✅ Syntax highlighting

---

## Related Files

- `src/parser/` - Tokenization and parsing
- `src/core/` - Core data models
- `src/render/` - Rendering widgets
- `src/export/` - Export functionality

---

*This document is updated as bugs are fixed or new issues are discovered.*
