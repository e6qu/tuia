# Acceptance Criteria

> Standard acceptance criteria for all tasks in the ZIGPRESENTERM project.

## Global Acceptance Criteria

Every task in this project must meet these criteria in addition to task-specific criteria.

---

## Code Quality Criteria

### AC-CODE-001: Code Compiles Without Warnings

**Given** the codebase  
**When** compiled with `zig build`  
**Then** no compiler warnings are produced

```bash
# Verification
zig build 2>&1 | grep -i warning && exit 1 || exit 0
```

### AC-CODE-002: Code is Properly Formatted

**Given** any source file  
**When** checked with `zig fmt`  
**Then** no formatting changes are required

```bash
# Verification
zig fmt --check src/
```

### AC-CODE-003: No Memory Leaks

**Given** the application  
**When** run through valgrind or GPA leak detection  
**Then** no memory leaks are detected

```bash
# Verification
zig build test -Dleak-check=full
# Or for binaries:
valgrind --leak-check=full --error-exitcode=1 ./tuia examples/demo.md
```

### AC-CODE-004: No Unsafe Code (Unless Justified)

**Given** the codebase  
**When** reviewed  
**Then** `@panic` and `unreachable` are only used in truly unreachable cases

**Exceptions:**
- C interop boundaries
- Performance-critical inner loops (with comment justification)

---

## Testing Criteria

### AC-TEST-001: Unit Tests Pass

**Given** the implementation  
**When** tests are run  
**Then** all unit tests pass

```bash
# Verification
zig build test
```

### AC-TEST-002: Minimum Coverage

**Given** the implementation  
**When** coverage is measured  
**Then** minimum 80% line coverage is achieved

| Component | Minimum Coverage |
|-----------|-----------------|
| Parser | 90% |
| Model | 85% |
| Renderer | 80% |
| Widgets | 80% |
| Features | 75% |

### AC-TEST-003: Edge Cases Covered

**Given** the implementation  
**When** edge cases are considered  
**Then** tests exist for:
- Empty inputs
- Maximum size inputs
- Invalid inputs
- Boundary conditions
- Null/optional values

### AC-TEST-004: Integration Tests Pass

**Given** the feature  
**When** integration tests run  
**Then** all end-to-end scenarios pass

---

## Documentation Criteria

### AC-DOC-001: Public API Documented

**Given** a public function or type  
**When** viewed in source  
**Then** it has a doc comment explaining:
- Purpose
- Parameters
- Return values
- Error conditions
- Usage example (for complex functions)

```zig
/// Parse a markdown presentation from source text.
///
/// The parser handles standard CommonMark with tuia extensions
/// including front matter, slide separators, and code attributes.
///
/// Parameters:
///   - allocator: Memory allocator for the parse
///   - source: Markdown source text
///
/// Returns:
///   - Parsed Presentation on success
///   - ParseError on invalid input
///
/// Errors:
///   - ParseError.InvalidFrontMatter: YAML parsing failed
///   - ParseError.OutOfMemory: Allocation failed
///
/// Example:
/// ```zig
/// const pres = try Parser.parse(allocator, "# Slide 1");
/// defer pres.deinit(allocator);
/// ```
pub fn parse(allocator: Allocator, source: []const u8) ParseError!Presentation {
    // ...
}
```

### AC-DOC-002: Complex Logic Explained

**Given** complex or non-obvious code  
**When** reviewed  
**Then** inline comments explain the "why" not just the "what"

```zig
// GOOD: Explains why
// We use a arena allocator here because all elements share the same
// lifetime as the presentation, and this is more efficient than
// individual allocations.
var arena = std.heap.ArenaAllocator.init(allocator);

// BAD: Just states what
// Initialize arena allocator
var arena = std.heap.ArenaAllocator.init(allocator);
```

### AC-DOC-003: CHANGELOG Updated

**Given** a user-visible change  
**When** the PR is submitted  
**Then** `CHANGELOG.md` is updated under the "Unreleased" section

---

## Performance Criteria

### AC-PERF-001: No Regressions

**Given** benchmarks  
**When** compared to previous version  
**Then** no >10% regression in any metric

### AC-PERF-002: Startup Time

**Given** the application  
**When** started  
**Then** initial render completes in <100ms (target: <50ms)

```bash
# Verification
hyperfine --warmup 3 './tuia examples/demo.md --exit-immediately'
```

### AC-PERF-003: Memory Usage

**Given** a 100-slide presentation  
**When** loaded  
**Then** memory usage is <50MB

---

## Security Criteria

### AC-SEC-001: No Secrets in Code

**Given** the codebase  
**When** scanned  
**Then** no secrets, keys, or credentials are present

```bash
# Verification
git-secrets --scan
# or
gitleaks detect
```

### AC-SEC-002: Safe Code Execution

**Given** the code execution feature  
**When** enabled  
**Then**:
- User must explicitly opt-in (-x flag)
- Warning is displayed before first execution
- Timeout prevents infinite loops
- Resource limits are enforced

---

## Task-Specific Criteria Templates

### Parser Tasks

**AC-PARSER-001: Valid Input Accepted**

**Given** valid input  
**When** parsed  
**Then** produces expected AST

**AC-PARSER-002: Invalid Input Rejected**

**Given** invalid input  
**When** parsed  
**Then** returns helpful error with line/column

**AC-PARSER-003: Roundtrip Preserved**

**Given** parsed then serialized content  
**When** compared to original  
**Then** semantic equivalence maintained

### Renderer Tasks

**AC-RENDER-001: Visual Output Correct**

**Given** a widget tree  
**When** rendered  
**Then** matches golden file (or manual verification)

**AC-RENDER-002: Terminal State Clean**

**Given** after rendering  
**When** application exits  
**Then** terminal is restored to original state

### Widget Tasks

**AC-WIDGET-001: Respects Constraints**

**Given** layout constraints  
**When** widget draws  
**Then** size does not exceed constraints

**AC-WIDGET-002: Handles Zero Size**

**Given** zero-size constraint  
**When** widget draws  
**Then** does not crash, returns empty surface

### Feature Tasks

**AC-FEAT-001: Feature Flag Work**

**Given** the feature  
**When** disabled  
**Then** application compiles and runs without it

---

## Review Checklist

### Before Submitting PR

- [ ] Code compiles without warnings
- [ ] All tests pass
- [ ] New tests added for new functionality
- [ ] Documentation updated
- [ ] CHANGELOG updated
- [ ] Manual testing performed
- [ ] Memory leaks checked
- [ ] Performance verified (if applicable)

### Reviewer Checklist

- [ ] Acceptance criteria met
- [ ] Code follows style guide
- [ ] Tests are comprehensive
- [ ] Documentation is clear
- [ ] No security concerns
- [ ] Performance acceptable

---

## Criteria Categories

| Category | Criteria IDs | Reviewer |
|----------|-------------|----------|
| Code Quality | AC-CODE-* | Static analysis + human |
| Testing | AC-TEST-* | CI + human |
| Documentation | AC-DOC-* | Human |
| Performance | AC-PERF-* | CI + human |
| Security | AC-SEC-* | CI + security review |

---

*Version: 1.0*  
*Applies to: All ZIGPRESENTERM tasks*
