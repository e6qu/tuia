# Do Next

> Upcoming work for TUIA

---

## Current Phase: 2.4 - Theme Engine

**Goal:** Implement theme system for styling presentations

### Tasks

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 2.4.1 | Theme Struct | Define theme data model | 4 |
| 2.4.2 | YAML Parser | Parse theme files from YAML | 4 |
| 2.4.3 | Style Application | Apply styles to widgets | 6 |
| 2.4.4 | Built-in Themes | Dark and light themes | 4 |
| 2.4.5 | Custom Themes | Load user themes | 4 |

### Deliverables

- `src/render/Theme.zig` - Theme data model
- `src/render/ThemeLoader.zig` - YAML theme loading
- Dark theme (default)
- Light theme
- Theme application to widgets

### Acceptance Criteria

- [ ] Themes can be loaded from YAML files
- [ ] Dark and light built-in themes work
- [ ] Styles apply correctly to all element types
- [ ] Invalid theme files produce helpful errors
- [ ] Theme switching works at runtime

---

## Upcoming Phases

### Phase 2.5: Navigation & Input
- Key binding system
- Slide navigation (next/prev/jump)
- Help modal

### Phase 2.6: Code Highlighting
- Syntax highlighting for code blocks
- Support multiple languages

---

## Document Update Checklist

After each phase, update:
- [ ] `PLAN.md` - Mark phase complete
- [ ] `STATUS.md` - Update current status
- [ ] `WHAT_WE_DID.md` - Add completed work
- [ ] `DO_NEXT.md` - Set next phase

---

*Last Updated: 2026-03-02*
