# Do Next

> Phase 25 complete — execution overlay and transition fixes

---

## Known Issue

**Transition grapheme corruption** — transitions are disabled by default. CellBuffer holds dangling grapheme pointers. Needs deep-copy of grapheme data or a string arena. See BUGS.md.

## Future Work

- **Fix transitions properly** — deep-copy grapheme strings in CellBuffer.captureFromWindow(), or use arena allocator for transition buffers. Add more transition types.
- **Inline formatting in lists** — list items show plain text; could render InlineTextWidget per item
- **Slide overview mode** — `o` key bound but grid view not implemented
- **Image rendering** — Kitty/sixel protocol
- **Config file** — `~/.config/tuia/config.toml`
- **Mouse support** — click to navigate, scroll

---

*Last updated: 2026-03-20*
