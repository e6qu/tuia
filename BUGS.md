# Known Bugs and Missing Features

> This document tracks bugs and missing features discovered during testing.

**Last Updated:** 2026-03-03
**Open Bug Count:** 5 (1 High, 1 Medium, 3 Low)  
**Status:** Active Development

---

## 📊 Bug Summary

| Category | Open | Fixed (Recent) | Total |
|----------|------|----------------|-------|
| Critical | 0 | 17 | 17 |
| High | 1 | 5 | 6 |
| Medium | 1 | 5 | 6 |
| Low | 3 | 0 | 3 |

**Recent Bug Hunts:** Phase 1-9 completed (17 critical bugs fixed)

---

## 🔴 Open Bugs

### HIGH-4: Memory Leak in FrontMatter.parseWithContent()
**Status:** 🔴 Open  
**Component:** Parser  
**Impact:** Medium

**Description:**  
In `FrontMatter.parseWithContent()`, if `parse()` returns an error after partially allocating front_matter fields, the allocated memory is not freed before the error propagates.

**Location:** `src/parser/FrontMatter.zig:100`

---

### MED-2: RemoteServer Does Not Handle HTTP Keep-Alive
**Status:** 🟡 Minor  
**Component:** Remote Control  
**Impact:** Low

**Description:**  
The RemoteServer sends `Connection: close` headers but does not properly handle connection shutdown. Modern browsers may try to reuse connections which could cause issues.

**Location:** `src/features/remote/RemoteServer.zig:168-174`

---

## 🔧 Low Priority Issues

### LOW-1: Hard Line Breaks Not Supported
**Status:** 🔴 Open  
**Component:** Parser  
**Impact:** Low

Hard line breaks (two spaces + newline, or `<br/>`) are not converted to line breaks.

---

### LOW-2: Escape Sequences Not Processed
**Status:** 🔴 Open  
**Component:** Scanner/Parser  
**Impact:** Low

Escaped characters (`\*`, `\``, `\\`) appear literally instead of being unescaped.

---

### LOW-3: Horizontal Rules Variations
**Status:** 🟡 Partial  
**Component:** Scanner  
**Impact:** Low

Only `---` is recognized as a thematic break. `***` and `___` are not recognized.

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
