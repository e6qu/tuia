# What We Did

> Chronicle of completed work on TUIA

---

## Milestone 0: Specification ✅

**Duration:** Week 1  
**Status:** Complete

### Deliverables
- 17 specification documents created:
  - Requirements, Architecture, API specs
  - ADRs (Architecture Decision Records)
  - File formats, Theme formats
  - Testing strategy, Keybindings

---

## Milestone 1: Foundation ✅

### Phase 1.1: Project Skeleton ✅

**Date:** 2026-03-01

- Created standard Zig project layout
- 50+ source files across modules:
  - `src/config/` - Configuration management
  - `src/core/` - Core presentation models
  - `src/parser/` - Markdown parsing
  - `src/render/` - Rendering engine
  - `src/widgets/` - UI widgets
  - `src/features/` - Images, executor, export, transitions
  - `src/infra/` - Infrastructure utilities
- `build.zig` with executable configuration
- Test structure with integration tests

### Phase 1.2: Build System & CI ✅

**Date:** 2026-03-01/02

- Cross-compilation for 5 targets:
  - x86_64-linux, aarch64-linux
  - x86_64-macos, aarch64-macos
  - x86_64-windows
- CI/CD Workflows:
  - `ci.yml` - Format, test, build, security scans
  - `security.yml` - Secret scanning, Trivy vulnerability scan
  - `pr.yml` - PR validation, binary size checks
  - `release.yml` - Multi-platform release automation
- `zig build verify` command working
- All CI checks passing

### Phase 1.3: Testing Framework ✅

**Date:** 2026-03-01

- Golden file testing utilities (`src/test_utils.zig`)
- 17 unit tests passing
- Integration test structure
- Memory leak detection with GPA
- Test fixtures directory

### Phase 1.4: Basic TUI Loop ✅

**Date:** 2026-03-02

- Added libvaxis 0.5.1 dependency
- Basic TUI event loop implementation:
  - Initialize vaxis TTY and screen
  - Handle keyboard events (Ctrl+C, 'q' to quit)
  - Handle window resize events
  - Render centered welcome message
  - Proper cleanup on exit
- CLI args support (`--help`, `--version`)

### Repository Cleanup ✅

**Date:** 2026-03-02

- Renamed project from `slidz` to `tuia`
- Fixed license references (AGPL-3.0)
- Clean commit history via PR workflow
- Branch protection enabled:
  - Required status checks
  - Linear history required
  - Force pushes disabled
- Single branch: `main` (local and remote)

---

## Current State

- **Binary:** `tuia` (~2.9MB)
- **Tests:** 17 passing
- **Build:** Cross-compilation working
- **CI:** All workflows passing
- **License:** AGPL-3.0
- **Repository:** Clean PR-based workflow

---

## Next Phase

**Phase 2.1: Markdown Parser** - See `DO_NEXT.md`
