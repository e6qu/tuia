# Do Next

> Phase 19 — Fix remaining rendering and layout issues

---

## Context

Phase 18 fixed code block rendering, help overlay, status bar, and unicode/emoji support. The app is functional with good rendering quality for most content. Several issues remain.

## Priority Issues

### 1. Code blocks don't render in multi-slide presentations
- Code blocks render correctly in single-slide files but disappear in multi-slide presentations
- The parser extracts code correctly (HTML export works), so the issue is in the TUI layout
- Likely in SlideWidget.draw() height/overflow calculations or Converter slide-splitting
- This is the most impactful remaining bug

### 2. Transition animations broken
- Transitions are disabled by default (Phase 17)
- The transition capture code in App.handleKey() renders to the main screen buffer BEFORE navigation
- Fix: render the "from" slide to a separate capture buffer instead of the main screen
- Then the transition manager can blend from/to slides independently

### 3. Inline formatting not processed
- `~~Strikethrough~~` shows raw markers instead of struck-through text
- `**Bold**` and `*italic*` markers may not be applying styles
- The parser produces Inline nodes with formatting, but the widget may not apply styles
- Check TextWidget and how it converts Inline nodes to styled text

### 4. Table rendering not implemented
- Tables show "[Table: render not yet implemented]" placeholder
- Need a TableWidget that renders table cells with borders
- The parser already produces table elements

### 5. Help overlay box corners
- The help overlay box corners show garbled characters (───╭ mismatch)
- Likely a double-width character issue with box-drawing characters

## What Not To Do

- Don't add new features until code blocks work in multi-slide presentations
- Always verify changes visually with tmux screenshots
- Don't "fix" things without running the app and checking the output

---

*Last updated: 2026-03-20*
