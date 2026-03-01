# Specifications Index

> Central index for all ZIGPRESENTERM specifications.

## Quick Navigation

| Topic | Document | Status |
|-------|----------|--------|
| Requirements | [requirements/REQUIREMENTS.md](requirements/REQUIREMENTS.md) | 📝 Draft |
| Architecture | [architecture/ARCHITECTURE.md](architecture/ARCHITECTURE.md) | 📝 Draft |
| File Format | [formats/FILE_FORMAT.md](formats/FILE_FORMAT.md) | 📝 Draft |
| Theme Format | [formats/THEME_FORMAT.md](formats/THEME_FORMAT.md) | 📝 Draft |
| CLI | [api/CLI_SPEC.md](api/CLI_SPEC.md) | 📝 Draft |
| API | [api/API_SPEC.md](api/API_SPEC.md) | 📝 Draft |

**Legend:** 📝 Draft | 👁️ Review | ✅ Approved

---

## Specification Categories

### 1. Requirements (`requirements/`)

Defines what we're building.

| Document | Purpose | Audience |
|----------|---------|----------|
| [REQUIREMENTS.md](requirements/REQUIREMENTS.md) | Functional & non-functional requirements | All |
| [COMPATIBILITY.md](requirements/COMPATIBILITY.md) | Presenterm compatibility level | Developers |
| [USER_STORIES.md](requirements/USER_STORIES.md) | User stories and use cases | Product |

### 2. Architecture (`architecture/`)

Defines how the system is structured.

| Document | Purpose | Audience |
|----------|---------|----------|
| [ARCHITECTURE.md](architecture/ARCHITECTURE.md) | High-level system architecture | All |
| [COMPONENTS.md](architecture/COMPONENTS.md) | Component descriptions | Developers |
| [DATA_FLOW.md](architecture/DATA_FLOW.md) | Data flow diagrams | Developers |
| [SEQUENCE.md](architecture/SEQUENCE.md) | Sequence diagrams | Developers |

### 3. Architecture Decision Records (`adr/`)

Records major technical decisions.

| ADR | Topic | Status |
|-----|-------|--------|
| [001-why-zig.md](adr/001-why-zig.md) | Why Zig as implementation language | 📝 Draft |
| [002-tui-framework.md](adr/002-tui-framework.md) | TUI framework selection | 📝 Draft |
| [003-parser-strategy.md](adr/003-parser-strategy.md) | Markdown parsing approach | 📝 Draft |
| [004-memory-management.md](adr/004-memory-management.md) | Memory management strategy | 📝 Draft |
| [005-code-highlighting.md](adr/005-code-highlighting.md) | Syntax highlighting approach | 📝 Draft |
| [006-image-rendering.md](adr/006-image-rendering.md) | Image protocol strategy | 📝 Draft |

### 4. File Formats (`formats/`)

Defines all file formats.

| Document | Purpose | Audience |
|----------|---------|----------|
| [FILE_FORMAT.md](formats/FILE_FORMAT.md) | Markdown presentation format | Users |
| [THEME_FORMAT.md](formats/THEME_FORMAT.md) | Theme YAML specification | Users |
| [CONFIG_FORMAT.md](formats/CONFIG_FORMAT.md) | Configuration file format | Users |

### 5. API Specifications (`api/`)

Defines interfaces.

| Document | Purpose | Audience |
|----------|---------|----------|
| [CLI_SPEC.md](api/CLI_SPEC.md) | Command-line interface | Users |
| [API_SPEC.md](api/API_SPEC.md) | Public library API | Developers |
| [INTERNAL_API.md](api/INTERNAL_API.md) | Internal interfaces | Developers |
| [ERROR_HANDLING.md](api/ERROR_HANDLING.md) | Error handling strategy | Developers |

### 6. Testing (`testing/`)

Defines testing approach.

| Document | Purpose | Audience |
|----------|---------|----------|
| [TESTING_STRATEGY.md](testing/TESTING_STRATEGY.md) | Overall testing approach | Developers |
| [TEST_PLAN.md](testing/TEST_PLAN.md) | Detailed test plan | QA |
| [FIXTURES.md](testing/FIXTURES.md) | Test fixture specifications | Developers |

### 7. User Experience (`ux/`)

Defines UI/UX specifications.

| Document | Purpose | Audience |
|----------|---------|----------|
| [UI_SPEC.md](ux/UI_SPEC.md) | User interface specification | Designers |
| [KEYBINDINGS.md](ux/KEYBINDINGS.md) | Default key bindings | Users |
| [ACCESSIBILITY.md](ux/ACCESSIBILITY.md) | Accessibility considerations | All |

### 8. Development (`development/`)

Defines development workflow.

| Document | Purpose | Audience |
|----------|---------|----------|
| [CI_SPEC.md](development/CI_SPEC.md) | CI/CD specification | DevOps |
| [RELEASE_PROCESS.md](development/RELEASE_PROCESS.md) | Release checklist | Maintainers |
| [PERFORMANCE_BUDGETS.md](development/PERFORMANCE_BUDGETS.md) | Performance targets | Developers |

---

## Specification Lifecycle

```
Draft → Review → Approved → Implemented → Obsolete
```

### Status Meanings

| Status | Description | Can Change? |
|--------|-------------|-------------|
| 📝 **Draft** | Initial version, subject to change | Yes |
| 👁️ **Review** | Under review by team | Minor changes |
| ✅ **Approved** | Accepted specification | No without process |
| 🚧 **Implemented** | Code matches spec | Bug fixes only |
| 🗃️ **Obsolete** | Replaced by newer spec | No |

### Change Process

1. **Draft changes:** Free during initial writing
2. **Review changes:** Address feedback
3. **Approved changes:** Require ADR for significant changes
4. **Implementation changes:** Update spec to match reality

---

## Cross-Reference Map

```
REQUIREMENTS
    ├──→ ARCHITECTURE (how requirements are met)
    ├──→ FILE_FORMAT (user-facing requirements)
    └──→ CLI_SPEC (CLI requirements)

ARCHITECTURE
    ├──→ ADRs (decisions behind architecture)
    ├──→ COMPONENTS (detailed components)
    ├──→ DATA_FLOW (data movement)
    └──→ API_SPEC (interface definitions)

FILE_FORMAT
    ├──→ THEME_FORMAT (theme file spec)
    └──→ CONFIG_FORMAT (config file spec)

API_SPEC
    ├──→ ERROR_HANDLING (error strategy)
    └──→ INTERNAL_API (internal details)
```

---

## Reading Guide

### For New Team Members

Start here:
1. [REQUIREMENTS.md](requirements/REQUIREMENTS.md) - Understand goals
2. [ARCHITECTURE.md](architecture/ARCHITECTURE.md) - Understand system
3. [FILE_FORMAT.md](formats/FILE_FORMAT.md) - Understand user interface

### For Users

Read these:
1. [FILE_FORMAT.md](formats/FILE_FORMAT.md) - How to write presentations
2. [THEME_FORMAT.md](formats/THEME_FORMAT.md) - How to customize themes
3. [CLI_SPEC.md](api/CLI_SPEC.md) - How to use the CLI
4. [KEYBINDINGS.md](ux/KEYBINDINGS.md) - How to navigate

### For Contributors

Read everything in this order:
1. Requirements
2. Architecture + ADRs
3. API specifications
4. Testing strategy
5. CI specification

---

## Specification Template

New specifications should follow this template:

```markdown
# SPEC-XXX: Title

**Status:** Draft  
**Owner:** @username  
**Date:** YYYY-MM-DD  
**Related:** [Link to related specs]

## Summary

One paragraph summary.

## Motivation

Why this spec exists.

## Specification

### Section 1

Details.

## Examples

```
Example code/format
```

## Rationale

Why these decisions.

## Open Questions

- Question?

## Changelog

- YYYY-MM-DD: Initial version
```

---

*Specs Index v1.0*  
*Last Updated: 2026-03-01*
