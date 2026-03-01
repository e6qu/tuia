# ADR 001: Why Zig as Implementation Language

**Status:** ✅ Approved  
**Date:** 2026-03-01  
**Deciders:** @team  
**Consulted:** @community  

---

## Context

We need to choose a programming language for implementing ZIGPRESENTERM. The choice affects:
- Performance characteristics
- Binary size and distribution
- Development velocity
- Ecosystem maturity
- Team expertise

### Requirements

1. **Performance**: Fast startup (<50ms), smooth rendering (60fps)
2. **Binary size**: Single binary <10MB for easy distribution
3. **Memory safety**: No segfaults, no undefined behavior
4. **Cross-compilation**: Easy builds for Linux, macOS, Windows
5. **TUI ecosystem**: Libraries for terminal UI development
6. **Maintenance**: Code that can be maintained long-term

### Candidates Considered

1. **Go** - Mature, fast compile, large ecosystem
2. **Rust** - Memory safety, performance, large ecosystem
3. **Zig** - Simplicity, C interop, compile-time metaprogramming
4. **C** - Maximum portability, but unsafe
5. **Python** - Fast development, but slow, requires runtime

---

## Decision

We will use **Zig** as the implementation language.

---

## Consequences

### Positive

- **Binary size**: Zig produces small binaries (~1-3MB expected)
- **Performance**: Comparable to C/Rust, no GC pauses
- **Memory safety**: Compile-time checks, explicit allocators
- **C interop**: Easy integration with existing C libraries
- **Cross-compilation**: First-class support, no toolchains needed
- **Compile-time**: Metaprogramming for code generation
- **Single binary**: Easy distribution at conferences

### Negative

- **Ecosystem smaller** than Go/Rust
- **Learning curve** for team members new to Zig
- **Less mature** tooling (IDE support improving)
- **Smaller hiring pool** if team expands
- **Documentation** less comprehensive than established languages

### Neutral

- **Build system**: Zig's build system is powerful but unique
- **Package manager**: Still evolving

---

## Rationale

### Why Not Go?

Go was seriously considered due to:
- Excellent standard library
- Fast compile times
- Great tooling
- Large ecosystem (Textual for TUI)

**Rejected because:**
- GC pauses could affect smooth animations
- Larger binaries (10-20MB with Textual)
- CGO complexity for C library integration
- Less control over memory layout

### Why Not Rust?

Rust was seriously considered due to:
- Memory safety guarantees
- Performance
- Excellent ecosystem (Ratatui for TUI)
- Large community

**Rejected because:**
- Slower compile times affect iteration speed
- Steeper learning curve
- More complex async/await for event loops
- Heavier for a TUI application

### Why Not C?

C was considered for:
- Maximum portability
- Existing terminal libraries
- Easy distribution

**Rejected because:**
- No memory safety guarantees
- Higher defect rate
- More code for same functionality
- No modern language features

### Why Zig?

Zig was chosen because it offers:

1. **Right balance**: Safety without complexity
2. **Control**: Explicit memory management, no hidden costs
3. **Interoperability**: Easy C library usage (tree-sitter, etc.)
4. **Simplicity**: Readable, explicit code
5. **Future-proof**: Growing rapidly, backed by Zig Software Foundation
6. **TUI library**: libvaxis is modern and Zig-native

Specific advantages for this project:

```zig
// Arena allocation for parsing - efficient and safe
var arena = std.heap.ArenaAllocator.init(gpa);
defer arena.deinit();
const pres = try Parser.parse(arena.allocator(), source);
// All memory freed at once, no leaks possible

// Comptime for generating parsers
const TokenType = enum {
    heading,
    paragraph,
    // ...
};

// Easy C interop for syntax highlighting
const ts = @cImport({
    @cInclude("tree_sitter/api.h");
});
```

---

## Implications

### For Development

- Team needs to learn Zig (steep but short curve)
- Contribution barrier slightly higher
- Build times fast (faster than Rust, comparable to Go)

### For Users

- Smaller binary to download
- Faster startup
- Lower memory usage
- Single executable, no dependencies

### For Maintenance

- Explicit code is easier to debug
- No hidden allocations
- Fearless refactoring with compiler help

---

## Related Decisions

- [002-tui-framework.md](002-tui-framework.md) - TUI framework choice
- [004-memory-management.md](004-memory-management.md) - Memory strategy

---

## Notes

This decision can be revisited if:
- Zig ecosystem doesn't mature as expected
- Critical libraries remain unavailable
- Team productivity significantly impacted

However, given the project's scope (20 weeks), Zig is the right choice for balancing performance, safety, and simplicity.

---

*ADR 001 - Approved*
