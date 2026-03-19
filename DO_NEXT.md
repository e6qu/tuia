# Do Next

> Phase 18 — Fix rendering quality

---

## Context

Phase 17 made the app functional: it starts, renders text, navigates, and exits cleanly. But visual inspection via tmux screenshots revealed several rendering quality issues that should be addressed.

## Priority Issues

### 1. Help overlay doesn't render
- Pressing `?` toggles `nav.show_help` but the help widget content doesn't appear on screen
- The toggle logic works (pressing `?` twice returns to normal) but no visual change occurs
- Likely a rendering pipeline issue where the help widget draw is skipped or drawn behind the slide

### 2. Code blocks render without spaces
- Code content like `git clone https://...` renders as `gitclonehttps://...`
- The CodeWidget strips or fails to preserve whitespace between tokens
- Check how CodeWidget iterates over code content and writes characters

### 3. Transition animations broken
- Transitions are disabled by default (Phase 17 set `enabled: bool = false`)
- When enabled, they cause off-by-one slide rendering because the transition capture code calls `renderer.render()` on the main screen buffer BEFORE navigation
- Fix: transition capture should render to a separate buffer, not the main screen

### 4. Table rendering not implemented
- Tables show "[Table: render not yet implemented]" placeholder text
- Need a TableWidget that renders table cells with borders

### 5. Some inline formatting corruption
- Complex inline formatting (bold within text, links) occasionally shows garbled characters
- May be related to multi-byte UTF-8 grapheme handling in the static lookup table (only covers single bytes)

## What Not To Do

- Don't add new features until these rendering issues are fixed
- Don't "fix" things without running the app and visually verifying the output
- Use tmux capture-pane or expect tests to validate rendering changes

---

*Last updated: 2026-03-19*
