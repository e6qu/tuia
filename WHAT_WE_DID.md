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

## Milestone 1: Foundation 🔄

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

### Repository Cleanup ✅

**Date:** 2026-03-02

- Renamed project from `slidz` to `tuia`
- Fixed license references (AGPL-3.0)
- Squashed all commits to single clean commit
- Branch protection enabled:
  - Required status checks (PR Checks, CI, Security Scans)
  - Required PR reviews (1 approval)
  - Linear history required
  - Force pushes disabled
- Single branch: `main` (local and remote)

---

## Current State

- **Binary:** `tuia` (~1.3MB)
- **Tests:** 17 passing
- **Build:** Cross-compilation working
- **CI:** All workflows passing
- **License:** AGPL-3.0
- **Repository:** Clean single-commit history

---

## Next Phase

**Phase 1.4: Basic TUI Loop** - See `DO_NEXT.md`
