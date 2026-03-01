# Testing Strategy

> Testing approach for ZIGPRESENTERM.

**Status:** 📝 Draft  
**Owner:** @team  
**Date:** 2026-03-01

---

## Testing Pyramid

```
       /\
      /  \     E2E Tests (few)
     /----\    
    /      \   Integration Tests
   /--------\  
  /          \ Unit Tests (many)
 /------------\
```

## Unit Tests

### Location

- Inline in source files: `src/parser/Parser.zig`
- Separate test files: `tests/parser_test.zig`

### Pattern

```zig
test "parse simple heading" {
    const allocator = std.testing.allocator;
    const source = "# Hello\n";
    
    var parser = Parser.init(allocator);
    const result = try parser.parse(source);
    defer result.deinit(allocator);
    
    try std.testing.expectEqual(@as(usize, 1), result.slides.len);
}
```

### Coverage Targets

| Component | Target Coverage |
|-----------|-----------------|
| Parser | 90% |
| Model | 85% |
| Layout | 80% |
| Widgets | 80% |
| Features | 75% |

## Integration Tests

### End-to-End Tests

```bash
# Test full presentation flow
slidz tests/fixtures/full_presentation.md --exit-immediately
```

### Golden File Testing

Compare output to expected:

```zig
test "render heading" {
    try expectRenderSnapshot(allocator, widget, "heading_simple");
    // Compares to tests/golden/heading_simple.txt
}
```

Update with: `ZIG_UPDATE_GOLDEN=1 zig build test`

## Property Tests

### Fuzzing

```zig
test "parse never crashes" {
    const fuzz = try std.testing.fuzzInput(.{});
    
    var parser = Parser.init(std.testing.allocator);
    _ = parser.parse(fuzz) catch {};
    // Should never panic
}
```

## Performance Tests

### Benchmarks

```zig
test "benchmark parse 100 slides" {
    const start = std.time.milliTimestamp();
    // ... parse
    const elapsed = std.time.milliTimestamp() - start;
    
    try std.testing.expect(elapsed < 100); // < 100ms
}
```

## Memory Safety Tests

### Leak Detection

```zig
test "no memory leaks" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(!gpa.detectLeaks());
    
    const allocator = gpa.allocator();
    // ... test code
}
```

## CI Testing

### Matrix

| OS | Zig Version | Test Suite |
|----|-------------|------------|
| Ubuntu | 0.15.0 | Full |
| macOS | 0.15.0 | Full |
| Windows | 0.15.0 | Unit only |

---

*Testing Strategy v0.1*
