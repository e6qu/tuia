# ADR 003: Parser Strategy

**Status:** 📝 Draft  
**Date:** 2026-03-01

---

## Context

Need to parse Markdown with custom extensions (slide separators, code attributes, etc.).

## Options

1. **Custom parser** - Write our own
2. **Goldmark (Go via FFI)** - Popular Go parser
3. **Pulldown-cmark (Rust via FFI)** - Rust parser
4. **Tree-sitter markdown** - Grammar-based parsing

## Decision

Write a **custom parser** in Zig.

## Rationale

- No mature Zig markdown parser exists
- Extensions are specific to our use case
- Full control over error messages
- No FFI complexity
- Zig's parser combinators work well

## Consequences

- More code to maintain
- Need comprehensive tests
- Must handle all edge cases

---

*ADR 003 - Draft*
