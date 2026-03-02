# Project Status

> Current status of TUIA (Terminal UI Application)

**Last Updated:** 2026-03-02  
**Current Phase:** 3.2 - Export Formats  
**Repository:** https://github.com/e6qu/tuia

---

## Quick Status

```
Milestone 0: Specification        ✅ COMPLETE
Milestone 1: Foundation           ✅ COMPLETE
  Phase 1.1-1.4                   ✅ COMPLETE
Milestone 2: Core Presentation    ✅ COMPLETE
  Phase 2.1: Markdown Parser      ✅ COMPLETE
  Phase 2.2: Slide Model          ✅ COMPLETE
  Phase 2.3: Widget System        ✅ COMPLETE
  Phase 2.4: Theme Engine         ✅ COMPLETE
  Phase 2.5: Navigation & Input   ✅ COMPLETE
  Phase 2.6: Code Highlighting    ✅ COMPLETE
Milestone 3: Advanced Features    🔄 IN PROGRESS
  Phase 3.1: Speaker Notes          ✅ COMPLETE
Milestone 4: Polish & Release     ⏳ PENDING
```

---

## ✅ Completed

### Phase 2.3: Widget System ✅

- Widget interface with VTable
- TextWidget (paragraphs with word wrap)
- HeadingWidget (styled headings)
- CodeWidget (code blocks with line numbers)
- SlideWidget (complete slide rendering)

---

## ✅ Completed

### Phase 2.4: Theme Engine ✅

- Theme struct with color definitions
- ElementStyle with fg/bg colors, bold/italic/underline
- Built-in dark and light themes
- ThemeLoader for YAML theme files
- Hex color parsing (#RRGGBB)
- Named color support (16 ANSI colors)

### Phase 2.5: Navigation & Input ✅

- Navigation state with slide tracking
- KeyBindings with vim-style shortcuts
- InputHandler for keyboard event processing
- HelpWidget for shortcut display
- StatusBar for slide info and messages
- Jump-to-slide functionality

### Phase 2.6: Code Highlighting ✅

- Token types for syntax highlighting (TokenKind enum)
- Language definitions for Zig, Python, JavaScript, TypeScript, Bash, JSON
- Keyword sets for each supported language
- Highlighter engine with tokenizer
- SyntaxColors in Theme for code highlighting
- Integration with dark and light themes

### Phase 3.1: Speaker Notes ✅

- Note model with content storage
- NotesCollection for managing slide notes
- NoteParser for extracting notes from markdown
- NoteWidget for displaying notes
- Support for <!-- note --> and <!-- endnote --> syntax

## ⏳ Current Phase: 3.2 - Export Formats

### Tasks

| ID | Task | Status |
|----|------|--------|
| 3.2.1 | HTML Export | ⏳ Pending |
| 3.2.2 | PDF Export | ⏳ Pending |
| 3.2.3 | Static Site | ⏳ Pending |

---

## Metrics

| Metric | Value | Target |
|--------|-------|--------|
| Binary size | ~3MB | <5MB ✅ |
| Test count | 20+ | 100+ 🔄 |
| Cross-compile | 5 targets | 5 targets ✅ |

---

## Document Tracking

| Document | Purpose | Update After Each Phase |
|----------|---------|------------------------|
| `PLAN.md` | Project roadmap | ✅ |
| `STATUS.md` | Current state | ✅ |
| `WHAT_WE_DID.md` | Completed work | ✅ |
| `DO_NEXT.md` | Upcoming tasks | ✅ |
| `AGENTS.md` | Agent workflow | Reference only |

---

*Ready for Phase 2.4: Theme Engine*
