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
- 50+ source files across modules
- `build.zig` with executable configuration
- Test structure with integration tests

### Phase 1.2: Build System & CI ✅

**Date:** 2026-03-01/02

- Cross-compilation for 5 targets
- CI/CD Workflows (ci.yml, security.yml, pr.yml, release.yml)
- `zig build verify` command working
- All CI checks passing

### Phase 1.3: Testing Framework ✅

**Date:** 2026-03-01

- Golden file testing utilities
- 17+ unit tests passing
- Integration test structure
- Memory leak detection with GPA

### Phase 1.4: Basic TUI Loop ✅

**Date:** 2026-03-02

- Added libvaxis 0.5.1 dependency
- Basic TUI event loop implementation
- CLI args support (`--help`, `--version`)

---

## Milestone 2: Core Presentation 🔄

### Phase 2.1: Markdown Parser ✅

**Date:** 2026-03-02

- **Token.zig**: Token types for Markdown elements
- **Scanner.zig**: Tokenizer for markdown source
  - Handles headings, code blocks, lists, blockquotes
  - Recognizes end_slide comments
- **AST.zig**: AST types (Presentation, Slide, Element, Inline)
  - Full memory management with deinit
- **Parser.zig**: Main parser
  - Parses slides separated by `<!-- end_slide -->`
  - Block-level parsing (headings, paragraphs, lists)
  - Basic inline text parsing
- Tests for scanner and parser

---

## Current State

- **Binary:** `tuia` (~2.9MB)
- **Tests:** 17+ passing
- **Build:** Cross-compilation working
- **CI:** All workflows passing
- **License:** AGPL-3.0
- **Repository:** Clean PR-based workflow

---

## Next Phase

**Phase 2.2: Slide Model** - See `DO_NEXT.md`
