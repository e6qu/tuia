# Do Next

> Upcoming work for TUIA

---

## 🛡️ Code Quality & Prevention (Priority)

Following the bug hunt phases 1-9, we're implementing stronger prevention measures:

### 1. Coding Standards Enhancement

Create `docs/CODING_STANDARDS.md` with enforced rules:

```zig
// REQUIRED: Bounds checking
if (index >= array.len) return error.IndexOutOfBounds;
const item = array[index];

// REQUIRED: Zero check before division
if (divisor == 0) return error.DivisionByZero;
const result = value / divisor;

// REQUIRED: Zero check before subtraction (unsigned)
if (value == 0) return error.Underflow;
const result = value - 1;

// REQUIRED: errdefer for cleanup
const ptr = try allocator.create(T);
errdefer allocator.destroy(ptr);

// REQUIRED: Never free string literals
if (!isStringLiteral(ptr)) allocator.free(ptr);
```

### 2. Static Analysis Integration

Add to CI pipeline:
- [ ] Zig fmt strict mode
- [ ] Custom lint rules for safety patterns
- [ ] Memory access pattern checks
- [ ] Bounds check verification

### 3. Testing Improvements

- [ ] Fuzz testing for parsers (input: random markdown)
- [ ] Property-based testing for math operations
- [ ] Stress tests for edge cases (empty inputs, zero values)
- [ ] Memory leak detection in CI (valgrind/drmemory)

### 4. Documentation Updates

- [ ] Add "Common Pitfalls" section to DEVELOPMENT.md
- [ ] Document bug patterns and how to avoid them
- [ ] Create code review checklist

---

## 🚀 Feature Enhancements (Future Versions)

### Version 1.1.0 Ideas
- [ ] PDF export improvements
- [ ] Additional themes
- [ ] Plugin system exploration
- [ ] Performance optimizations

### Version 1.2.0 Ideas
- [ ] More image protocol support
- [ ] Advanced transitions
- [ ] Remote control enhancements

---

## 📋 Maintenance Tasks

### Ongoing
- Monitor GitHub Issues for bug reports
- Keep dependencies updated (libvaxis, etc.)
- Review and merge community PRs

### Documentation
- Keep BUGS.md updated
- Update USER_GUIDE.md with new features
- Maintain API documentation

---

## 🐛 Bug Tracking

Current open bugs (see BUGS.md):
- HIGH-4: Memory leak in FrontMatter
- MED-2: HTTP Keep-Alive handling
- LOW-1/2/3: Minor parser improvements

**Priority:** Fix HIGH-4 before next release.

---

## 🎯 Success Criteria

- [ ] Zero critical bugs in production
- [ ] All new code follows safety standards
- [ ] CI catches 90%+ of common bugs
- [ ] Test coverage maintained >80%

---

*Last updated: 2026-03-03*
