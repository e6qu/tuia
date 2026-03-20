# Do Next

> Phase 26 — Dead Code Cleanup

---

## Context

Comprehensive stub audit found ~60 stubs/placeholders. Phase 26 starts by deleting dead code: 14 empty placeholder modules never imported, 4 dead functions, and duplicate namespaces. This reduces noise before tackling real work in Phases 27-30.

## Phase 26 Tasks

### Delete empty placeholder modules (never imported)
- `src/render/Layout.zig`
- `src/core/Engine.zig`
- `src/config/Loader.zig`
- `src/infra/Watcher.zig`
- `src/infra/fs.zig`
- `src/infra/logging.zig`
- `src/features/highlighter/` (entire dir — duplicate of `src/highlight/`)
- `src/features/images/Image.zig` (duplicate)
- `src/features/images/Protocol.zig`
- `src/features/export/Exporter.zig`
- `src/features/export/HtmlExporter.zig` (duplicate of `src/export/`)
- `src/features/export/root.zig`
- `src/features/transitions/Fade.zig`
- `src/parser/Command.zig`

### Remove dead functions
- `InputHandler.showSlideStatus()` — no callers
- `Renderer.renderDebug()` — never called
- `Renderer.initWithTheme()` — never called
- `Terminal.queryTerminal()` — documented no-op

### Update root.zig files referencing deleted modules

### Verify
- `zig build unit_test` — all 126 tests pass
- `zig build` — clean build
- tmux screenshot — no regressions

---

*Last updated: 2026-03-20*
