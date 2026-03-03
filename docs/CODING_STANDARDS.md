# TUIA Coding Standards

> Mandatory coding standards to prevent common bugs

**Version:** 1.0  
**Last Updated:** 2026-03-03

---

## Overview

After fixing 27 bugs in 9 bug hunt phases (including 17 critical bugs), we've identified common patterns that cause issues. These standards MUST be followed for all new code.

---

## 🛡️ Safety Rules (Mandatory)

### 1. Bounds Checking

**Rule:** Always check bounds before array/slice access.

```zig
// ❌ WRONG - Will panic on empty array
const first = items[0];

// ✅ CORRECT - Check bounds first
if (items.len == 0) return error.EmptyArray;
const first = items[0];
```

**Applies to:**
- Array indexing: `array[index]`
- Slice access: `slice[start..end]`
- String indexing: `string[i]`

---

### 2. Integer Underflow Prevention

**Rule:** Always check for zero before subtracting from unsigned integers.

```zig
// ❌ WRONG - Underflow when total_slides is 0
if (current_slide < total_slides - 1) { ... }

// ✅ CORRECT - Check for zero first
if (total_slides == 0) return;
if (current_slide < total_slides - 1) { ... }
```

**Applies to:**
- `usize`, `u32`, `u64`, and other unsigned types
- Any subtraction: `a - b` where b could equal a

---

### 3. Division by Zero Prevention

**Rule:** Always check divisor is non-zero before division.

```zig
// ❌ WRONG - Division by zero when width is 0
const result = value / width;

// ✅ CORRECT - Check divisor first
if (width == 0) return error.DivisionByZero;
const result = value / width;
```

**Applies to:**
- All division operations: `/`, `%`
- Calculations that could result in zero denominators

---

### 4. Memory Safety with errdefer

**Rule:** Use `errdefer` for all cleanup after allocation.

```zig
// ❌ WRONG - Leaks on error
const ptr = try allocator.create(T);
const inner = try allocator.alloc(u8, 100);  // If this fails, ptr leaks

// ✅ CORRECT - Proper cleanup on error
const ptr = try allocator.create(T);
errdefer allocator.destroy(ptr);
const inner = try allocator.alloc(u8, 100);
errdefer allocator.free(inner);
```

**Pattern for complex init:**
```zig
pub fn init(allocator: Allocator) !*Self {
    const self = try allocator.create(Self);
    errdefer allocator.destroy(self);
    
    self.data = try allocator.dupe(u8, "data");
    errdefer allocator.free(self.data);
    
    self.items = try allocator.alloc(Item, 10);
    errdefer allocator.free(self.items);
    
    return self;
}
```

---

### 5. String Literal Safety

**Rule:** Never free string literals or empty slices.

```zig
// ❌ WRONG - Freeing a string literal
self.text = "";  // Literal
deinit() {
    allocator.free(self.text);  // UNDEFINED BEHAVIOR!
}

// ✅ CORRECT - Use empty slice or track allocation
self.text = &.{};  // Empty slice, safe to not free
deinit() {
    // No need to free empty slice
}

// OR: Track whether allocated
self.text = if (allocated) value else &.{};
deinit() {
    if (self.text.len > 0) allocator.free(self.text);
}
```

**Best Practice:** Use `&.{}` for empty slices instead of `""`.

---

### 6. Null/Optional Safety

**Rule:** Always check optionals before unwrapping.

```zig
// ❌ WRONG - Will panic if null
const value = optional.?;

// ✅ CORRECT - Safe unwrap
if (optional) |value| {
    // Use value
} else {
    return error.NullValue;
}

// OR: Provide default
const value = optional orelse return error.NullValue;
```

---

### 7. Empty Array/Slice Handling

**Rule:** Check `.len == 0` before accessing elements.

```zig
// ❌ WRONG - Panic on empty
const first = items[0];
const last = items[items.len - 1];

// ✅ CORRECT - Check first
if (items.len == 0) return error.EmptyArray;
const first = items[0];
const last = items[items.len - 1];
```

---

## 📋 Code Review Checklist

Before submitting PR, verify:

- [ ] All array accesses have bounds checks
- [ ] All unsigned subtractions check for zero
- [ ] All divisions check for zero divisor
- [ ] All allocations have `errdefer` cleanup
- [ ] No string literals are freed
- [ ] All optionals checked before unwrap
- [ ] Empty arrays handled before element access
- [ ] Error unions used for fallible operations

---

## 🧪 Testing Requirements

### Edge Cases to Test

1. **Empty inputs:** `&[]`, `""`, `null`, `0`
2. **Boundary values:** `0`, `1`, `maxInt`, `maxInt - 1`
3. **Error paths:** Allocation failures, invalid inputs
4. **Large inputs:** Stress test with big data

### Example Test Template

```zig
test "function handles edge cases" {
    const allocator = testing.allocator;
    
    // Empty input
    try testing.expectError(error.EmptyInput, function(allocator, ""));
    
    // Single element
    const result1 = try function(allocator, "x");
    defer cleanup(result1);
    try testing.expectEqual(1, result1.len);
    
    // Maximum input
    const large = try allocator.alloc(u8, 10000);
    defer allocator.free(large);
    const result2 = try function(allocator, large);
    defer cleanup(result2);
}
```

---

## 🚨 Common Bug Patterns to Avoid

### Pattern 1: Use-After-Free
```zig
// ❌ WRONG
const ptr = try allocator.dupe(u8, "data");
defer allocator.free(ptr);
return ptr;  // Pointer freed when function returns!

// ✅ CORRECT
const ptr = try allocator.dupe(u8, "data");
// Let caller free, or use toOwnedSlice pattern
return ptr;
```

### Pattern 2: Double Free
```zig
// ❌ WRONG
const copy = try allocator.dupe(u8, original);
allocator.free(copy);
// ... later ...
allocator.free(copy);  // Double free!

// ✅ CORRECT
const copy = try allocator.dupe(u8, original);
defer allocator.free(copy);
// Use copy, freed automatically
```

### Pattern 3: Iterator Invalidation
```zig
// ❌ WRONG
for (array.items) |*item| {
    try array.append(new_item);  // May invalidate iterator!
}

// ✅ CORRECT
const count = array.items.len;
for (0..count) |i| {
    // Safe to modify during iteration
}
```

---

## 🔧 Static Analysis

The following patterns are checked in CI:

1. `array[index]` without bounds check
2. `value - 1` on unsigned without zero check
3. `a / b` without zero check on b
4. `allocator.free(literal)`
5. `optional.?` without null check
6. Missing `errdefer` after allocation

---

## 📚 References

- [Zig Documentation](https://ziglang.org/documentation/)
- [BUGS.md](../BUGS.md) - Complete bug history
- [PLAN.md](../PLAN.md) - Project plan with prevention measures

---

*These standards are enforced through code review and CI checks.*
