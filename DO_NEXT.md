# Do Next

> Phase 22 — Visual debugging and polish

---

## Context

Phase 21 bug fixes merged (PR #59). Phase 22 debugging found and fixed 4 more issues:
- Code block double-spacing (blank_line tokens after each text token)
- Status bar duplicate (showSlideStatus redundantly set the same message)
- List parsing (blank_lines broke list item loop, preventing nesting and multi-item lists)
- Enter key parsed as Ctrl+M (Ctrl+letter handler fired before Enter handler in parseKey)

## Remaining Work

### 1. Verify light theme visually
- The light theme is defined with appropriate colors but hasn't been visually verified
- Need to check contrast, readability on light background
- tmux `capture-pane -p` strips colors — need to look at terminal directly or use `-e` flag

### 2. Test transitions more thoroughly
- Basic transition works (slide changes with animation)
- Need to verify no visual artifacts during transition
- Test rapid navigation (multiple j presses quickly)

### 3. Check edge cases
- Very long code blocks (scrolling/clipping)
- Very long list items (wrapping)
- Empty slides
- Slides with only headings

## What Not To Do

- Don't break the 126 passing tests
- Don't refactor unrelated code

---

*Last updated: 2026-03-20*
