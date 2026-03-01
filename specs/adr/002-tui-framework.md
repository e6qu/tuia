# ADR 002: TUI Framework Selection

**Status:** 📝 Draft  
**Date:** 2026-03-01  
**Deciders:** @team

---

## Context

Need to select a TUI framework for building the presentation interface.

## Options Considered

1. **libvaxis** - Modern Zig TUI library
2. **Direct terminal control** - ANSI escape codes
3. **C library via FFI** - ncurses, termbox

## Decision

Use **libvaxis** with the **vxfw** high-level API.

## Rationale

- Native Zig library
- Modern terminal protocol support (Kitty images, etc.)
- Flutter-like reactive framework (vxfw)
- Active development

## Consequences

- Dependency on external library
- API may change (pin to version)
- Need to learn vxfw patterns

---

*ADR 002 - Draft*
