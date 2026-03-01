# ADR 004: Memory Management Strategy

**Status:** 📝 Draft  
**Date:** 2026-03-01

---

## Context

Zig requires explicit memory management. We need a consistent strategy.

## Strategy

### Per-Module Allocators

| Module | Allocator Type | Lifetime |
|--------|---------------|----------|
| Parser | Arena | Per-parse |
| Model | Arena | Presentation lifetime |
| Layout | Stack fallback | Per-render frame |
| Render | Stack fallback | Per-render frame |
| Engine | GPA | Application lifetime |

### Pattern

```zig
// Parser: Arena for entire parse
var arena = std.heap.ArenaAllocator.init(gpa);
defer arena.deinit();
const pres = try Parser.parse(arena.allocator(), source);

// Render: Stack space with heap fallback
var frame = std.heap.stackFallback(4096, gpa);
try render(frame.get(), pres);
```

## Rationale

- Predictable memory usage
- Fast deallocation (arena reset)
- Clear ownership
- Easy leak detection

---

*ADR 004 - Draft*
