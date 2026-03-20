# TUIA Project Plan

> Terminal UI Application - A presenterm-compatible presentation tool in Zig

**Version:** pre-release
**Status:** Planning stub completion
**Stack:** Zig 0.15.2, custom POSIX TUI layer

---

## Stub Audit Summary

A comprehensive audit found ~60 stubs, placeholders, and dead code items. They fall into three categories:

1. **Dead code to delete** — empty placeholder modules never imported, duplicate namespaces, dead functions
2. **Config wiring** — 18+ config fields parsed and editable but never applied at runtime
3. **Feature stubs** — real features with placeholder implementations (images, overview, transitions, media)

---

## Phase 26: Dead Code Cleanup

**Goal:** Remove all placeholder modules that are never imported, dead functions, and duplicate namespaces. Reduce codebase noise.

**Delete these empty/unreferenced placeholder modules:**
- `src/render/Layout.zig` — never imported
- `src/core/Engine.zig` — never imported
- `src/config/Loader.zig` — never imported
- `src/infra/Watcher.zig` — never imported (WatchConfig stays in Config.zig)
- `src/infra/fs.zig` — never imported
- `src/infra/logging.zig` — never imported
- `src/features/highlighter/` — entire directory (duplicate of `src/highlight/`)
- `src/features/images/Image.zig` — duplicate of ImageLoader types
- `src/features/images/Protocol.zig` — never imported
- `src/features/export/Exporter.zig` — never imported
- `src/features/export/HtmlExporter.zig` — duplicate of `src/export/HtmlExporter.zig`
- `src/features/export/root.zig` — never imported
- `src/features/transitions/Fade.zig` — never imported (logic is inline in Transition.zig)
- `src/parser/Command.zig` — never imported

**Remove dead functions:**
- `InputHandler.showSlideStatus()` — no longer called since Phase 22
- `Renderer.renderDebug()` — debug-only, never called
- `Renderer.initWithTheme()` — never called
- `Terminal.queryTerminal()` — documented no-op

**Update root.zig files** that reference deleted modules.

**Verification:** `zig build unit_test` + `zig build` must pass. tmux screenshot to confirm no regressions.

---

## Phase 27: Config Wiring

**Goal:** Make parsed config fields actually affect runtime behavior. Wire up the easy ones.

**Trivial (just read the field):**
- `presentation.loop` — wrap around at last slide instead of stopping
- `presentation.show_slide_numbers` — conditionally hide "Slide N/M" in status bar
- `presentation.show_total_slides` — show "Slide N" vs "Slide N/M"
- `display.min_width/min_height` — show error if terminal too small
- `export.output_dir` — pass to exporters as default output path
- `executor.timeout_seconds` — pass to ExecutionConfig

**Small (a few lines of logic):**
- `keys.*` (KeyConfig) — apply user key overrides to KeyBindings at startup
- `transitions.*` — pass enabled/type/duration to TransitionManager at startup
- `executor.allowed_languages` — check before executing
- `theme.use_terminal_background` — skip bg color in SGR output if set
- `display.truecolor` — fall back to 256-color index if disabled

**Skip for now (need new features):**
- `presentation.auto_advance_seconds` — needs timer infrastructure
- `presentation.aspect_ratio` — needs layout engine
- `display.mouse` — needs mouse event parsing
- `watch.*` — needs Watcher implementation
- `theme.custom_theme_path` — needs theme file parser

**Verification:** `zig build unit_test` + tmux screenshots showing config effects.

---

## Phase 28: Fix Transitions (Deep-Copy Grapheme Data)

**Goal:** Fix the dangling grapheme pointer bug and re-enable transitions by default.

**What to do:**
- In `CellBuffer.captureFromWindow()`, deep-copy each cell's `grapheme` slice into an arena allocator owned by the CellBuffer
- On CellBuffer.clear() or deinit(), free the arena
- Update CellBuffer.init() to create the arena
- Re-enable `TransitionConfig.enabled = true`
- Test all transition types (fade, slide, wipe, dissolve)

**Verification:** `zig build unit_test` + tmux screenshots showing smooth transitions without garbled characters.

---

## Phase 29: Slide Overview Mode

**Goal:** Implement the `o` key slide overview — show a thumbnail grid of all slides.

**What to do:**
- Create `OverviewWidget` that renders a grid of slide thumbnails
- Each thumbnail: render slide into a small sub-window, then scale down to grid cell
- Arrow keys navigate the grid, Enter selects a slide
- Escape/`o` exits overview back to normal mode
- Wire into Renderer: when `nav.show_overview`, render OverviewWidget instead of slide

**Verification:** `zig build unit_test` + tmux screenshots showing overview grid.

---

## Phase 30: Polish & Minor Stubs

**Goal:** Clean up remaining small stubs and polish.

- **Rust execution** — run compiled binary after `rustc`
- **PdfExporter.isAvailable()** — check if `pdflatex` is in PATH
- **StatusBar** — clean up unused `allocator` field
- **Per-slide drawings** — store drawing_cells per slide index instead of clearing
- **Theme picker** — enumerate themes dynamically instead of hardcoded list
- **RevealJsExporter** — use slide_num for section IDs

**Verification:** `zig build unit_test` + tmux screenshots.

---

## Future Work (Not Planned Yet)

These require significant new infrastructure or third-party dependencies:

- **Real image rendering** — needs PNG/JPEG decoder (zigimg) + Kitty/Sixel/iTerm2 protocol
- **File watcher / hot-reload** — needs kqueue/inotify abstraction
- **Media playback** — pause/resume via player IPC, volume control
- **Mouse support** — needs CSI mouse event parsing in Terminal
- **Auto-advance** — needs timer/interval in event loop
- **Network sandbox** — needs Linux namespace support
- **Container isolation** — SecurityLevel.maximum

---

## Completed Milestones

| Milestone | Status |
|-----------|--------|
| M0-M4: Full app from spec to v1.0 | Done |
| Phases 1-16: 57 component bugs | Done |
| Phase 17-20: Working TUI | Done |
| Phase 21-25: Visual polish + bug fixes (20 bugs) | Done |

---

## Metrics

| Metric | Value |
|--------|-------|
| Unit/Integration Tests | 126 (passing) |
| Open Bugs | 1 (transitions, Phase 28) |
| Total Bugs Fixed | 77 |

---

*See BUGS.md for bug history. See DO_NEXT.md for current phase. See WHAT_WE_DID.md for history.*
