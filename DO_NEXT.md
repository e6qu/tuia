# Do Next

> Phase 27 — Config Wiring

---

## Context

Phase 26 complete — deleted 16 dead files, 4 dead functions (93 lines). Phase 27 wires parsed config fields to runtime behavior.

## Phase 27 Tasks

### Trivial (just read the field)
- `presentation.loop` — wrap around at last slide
- `presentation.show_slide_numbers` — conditionally hide "Slide N/M"
- `presentation.show_total_slides` — show "Slide N" vs "Slide N/M"
- `display.min_width/min_height` — show error if terminal too small
- `export.output_dir` — pass to exporters
- `executor.timeout_seconds` — pass to ExecutionConfig

### Small (a few lines of logic)
- `keys.*` (KeyConfig) — apply user key overrides to KeyBindings at startup
- `transitions.*` — pass enabled/type/duration to TransitionManager at startup
- `executor.allowed_languages` — check before executing
- `theme.use_terminal_background` — skip bg color in SGR

### Skip for now (need new features)
- `presentation.auto_advance_seconds` — needs timer
- `presentation.aspect_ratio` — needs layout engine
- `display.mouse` — needs mouse event parsing
- `watch.*` — needs Watcher
- `theme.custom_theme_path` — needs theme file parser

### Verify
- `zig build unit_test` — all tests pass
- `zig build` — clean build
- tmux screenshots showing config effects (loop, slide numbers)

---

*Last updated: 2026-03-20*
