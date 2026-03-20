# Do Next

> Phase 23 complete — all visual polish done

---

## Context

Phase 23 verified both dark and light themes work correctly. Theme switching rebuilds slide widgets at runtime. All libvaxis references removed. The TUI is fully functional with 0 open bugs.

## Potential Future Work

- **Code block theme-aware syntax colors** — currently uses hardcoded default colors for syntax highlighting; could use `ctx.theme.getSyntaxColor()` for light-theme-optimized palette
- **Inline formatting in lists** — list items currently show plain text (bold/italic markers stripped); could render InlineTextWidget per list item
- **Slide overview mode** — `o` key is bound but overview grid not implemented
- **Image rendering** — Kitty/sixel protocol support for inline images
- **Config file** — `~/.config/tuia/config.toml` for persistent settings

## What Not To Do

- Don't break the 126 passing tests
- Don't refactor working code without a clear bug or feature request

---

*Last updated: 2026-03-20*
