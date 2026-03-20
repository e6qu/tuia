# Gap Analysis

> Comparison of TUIA's current state vs. a fully-featured presenterm-compatible tool

**Date:** 2026-03-20 (updated after Phase 25)

---

## Feature Completeness

| Feature | Status | Notes |
|---------|--------|-------|
| Slide parsing (markdown) | ✅ Working | Headings, paragraphs, lists, code, blockquotes, tables, thematic breaks |
| Slide navigation (j/k/arrows/space) | ✅ Working | Smooth, no blocking |
| Slide jump (g/G/number+Enter) | ✅ Working | First/last/arbitrary slide |
| Bold/italic/code formatting | ✅ Working | ANSI bold, italic, code background |
| Strikethrough | ✅ Working | ANSI strikethrough |
| Combined formatting (***) | ✅ Working | Bold+italic parsed and rendered |
| Code blocks | ✅ Working | Syntax highlighting, indentation, single-spacing, box borders |
| Code execution | ✅ Working | `e` to execute, slide-specific panel, `E` to toggle |
| Tables | ✅ Working | Unified bordered rendering with header separator |
| Lists (nested) | ✅ Working | Depth-based indentation, ordered numbering |
| Blockquotes | ✅ Working | │ left border, separate blocks |
| Thematic breaks | ✅ Working | `***`/`___` render within slides, `---` separates |
| Escape sequences | ✅ Working | `\*`, `\[`, etc. |
| Unicode/CJK | ✅ Working | Proper 2-column width handling |
| Emoji | ✅ Working | Dingbats, variation selectors, skin tones |
| Help overlay | ✅ Working | `?` shows keyboard shortcuts |
| Theme switching | ✅ Working | Dark/light, live rebuild, theme-aware syntax |
| Status bar | ✅ Working | Slide counter, title, timed messages |
| Welcome screen | ✅ Working | Clean display when no file |
| Speaker notes | ✅ Working | Parsed and available |
| Exporters (HTML/Reveal/Beamer) | ✅ Working | CLI export |
| PDF export | ⚠️ Partial | Generates LaTeX; requires manual `pdflatex` |
| Transitions | ❌ Disabled | Dangling grapheme pointers in cell buffers (Phase 28) |
| Image rendering | ❌ Stub | 1x1 pixel placeholder; no real decoding or protocol support |
| Slide overview (o key) | ❌ Stub | State tracked, no widget rendered (Phase 29) |
| File hot-reload | ❌ Stub | Watcher module empty |
| Media playback | ❌ Stub | Stop works, pause/volume no-ops |
| Mouse support | ❌ Missing | No mouse event parsing |
| Config at runtime | ❌ Mostly unwired | 18+ fields parsed but ignored (Phase 27) |

---

## Dead Code / Cleanup Status

| Category | Count | Status |
|----------|-------|--------|
| Empty placeholder modules (never imported) | 14 | ✅ Deleted (Phase 26) |
| Dead functions (no callers) | 4 | ✅ Deleted (Phase 26) |
| Duplicate namespaces (features/export, features/highlighter) | 2 | ✅ Deleted (Phase 26) |
| Config fields parsed but unwired | 18+ | Phase 27: wire up |

---

## Comparison with presenterm

| Capability | presenterm | TUIA |
|-----------|-----------|------|
| Basic navigation | ✅ | ✅ |
| Code blocks + highlighting | ✅ | ✅ |
| Tables | ✅ | ✅ |
| Nested lists | ✅ | ✅ |
| Themes | ✅ | ✅ |
| Speaker notes | ✅ | ✅ |
| Transitions/animations | ✅ | ❌ Disabled (fixable) |
| Image support (kitty/sixel) | ✅ | ❌ Stub |
| PDF export | Plugin | ⚠️ LaTeX only |
| File hot-reload | ✅ | ❌ Stub |
| Mouse support | ✅ | ❌ Missing |
| Slide overview | ❌ | ❌ Stub |
| Code execution | ❌ | ✅ |

---

## Planned Fix Phases

| Phase | Focus | Key Items |
|-------|-------|-----------|
| 26 | Dead code cleanup | Delete 14 empty modules, 4 dead functions |
| 27 | Config wiring | Wire 18+ config fields to runtime |
| 28 | Fix transitions | Deep-copy grapheme data, re-enable |
| 29 | Slide overview | Thumbnail grid on `o` key |
| 30 | Minor polish | Rust exec, PDF check, per-slide drawings |

---

*Last updated: 2026-03-20*
