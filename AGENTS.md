# AGENTS.md - AI Agent Workflow Guide

> This document guides AI agents (like Kimi Code CLI) working on the ZIGPRESENTERM project.

## Quick Reference

| Task | Read First | Check Before Commit |
|------|-----------|---------------------|
| New feature | PLAN.md, ACCEPTANCE_CRITERIA.md | Tests pass, fmt clean |
| Bug fix | Related code, DEFINITION_OF_DONE.md | Regression test added |
| Refactor | ARCHITECTURE.md | No behavior change |
| Docs | docs/ structure | Links work |

---

## Project Context

### What We're Building

**ZIGPRESENTERM** (working name: **tuia**) is a terminal presentation tool written in Zig:
- Renders Markdown as slideshows
- Supports images (Kitty/iTerm2/Sixel protocols)
- Executes code snippets
- Exports to PDF/HTML
- Built with libvaxis for TUI

### Technology Stack

- **Language:** Zig 0.15+
- **TUI Framework:** libvaxis (vxfw high-level API)
- **Build System:** Zig build (build.zig)
- **Testing:** Built-in zig test + custom harness
- **CI:** GitHub Actions

### Project State

**Current Phase:** Planning (Milestone 0)
- ✅ Research complete
- ✅ PLAN.md created
- 🔄 Specification in progress

---

## Workflow for AI Agents

### 1. Before Starting Work

#### 1.1 Read Relevant Documentation

Always read these before starting:
- [ ] `PLAN.md` - Understand milestones and phases
- [ ] `ACCEPTANCE_CRITERIA.md` - Know the bar for completion
- [ ] `DEFINITION_OF_DONE.md` - Understand exit criteria

For specific task types:
- **New feature:** Read architecture docs in `docs/architecture/`
- **Bug fix:** Read related code and tests
- **Refactor:** Read all affected module documentation

#### 1.2 Check Task Dependencies

```bash
# See if dependencies are complete
grep -r "depends on" tasks/ 2>/dev/null || echo "No task tracking yet"
```

#### 1.3 Understand Scope

| Work Type | Scope Limit |
|-----------|-------------|
| Single task | One bullet point in PLAN.md phases |
| Bug fix | Minimal change to fix issue |
| Refactor | One module or concern at a time |

**Never:** Combine multiple phases or major refactors in one change.

---

### 2. While Working

#### 2.1 Code Style

Follow Zig conventions:

```zig
// Naming
const MyStruct = struct {};     // Types: PascalCase
my_variable: i32,               // Variables: snake_case
MY_CONSTANT,                    // Constants: SCREAMING_SNAKE_CASE
myFunction(),                   // Functions: camelCase

// Formatting
// - 4 spaces indentation
// - 100 column limit
// - Trailing commas in multiline
const my_struct = .{
    .field_one = 1,
    .field_two = 2,  // <- trailing comma
};

// Error handling
// Use try for propagation
const result = try mightFail();

// Use catch for handling
const result = mightFail() catch |err| {
    log.err("Failed: {}", .{err});
    return error.Handled;
};

// Use errdefer for cleanup
const resource = try allocator.alloc(u8, 100);
errdefer allocator.free(resource);
```

#### 2.2 Testing

Every code change should have tests:

```zig
// In src/parser/Parser.zig or tests/parser_test.zig

test "parse simple slide" {
    const allocator = std.testing.allocator;
    const source = "# Title\n\nContent\n";
    
    var parser = Parser.init(allocator);
    const pres = try parser.parse(source);
    defer pres.deinit(allocator);
    
    try std.testing.expectEqual(@as(usize, 1), pres.slides.len);
    try std.testing.expectEqualStrings("Title", pres.slides[0].title);
}

test "parse error handling" {
    const allocator = std.testing.allocator;
    const invalid = "<!-- invalid -->\n";
    
    var parser = Parser.init(allocator);
    const result = parser.parse(invalid);
    
    try std.testing.expectError(error.InvalidDirective, result);
}
```

#### 2.3 Documentation

Add doc comments to all public APIs:

```zig
/// Parse markdown source into a Presentation.
///
/// This function takes ownership of no memory; the returned Presentation
/// contains allocated data that must be freed with `Presentation.deinit`.
///
/// Parameters:
///   - allocator: Allocator for all internal allocations
///   - source: Markdown source text
///
/// Returns:
///   Parsed Presentation on success
///
/// Errors:
///   - error.OutOfMemory: Allocation failed
///   - error.InvalidFrontMatter: YAML parsing failed
///
/// Example:
/// ```zig
/// var parser = Parser.init(allocator);
/// const pres = try parser.parse("# Hello");
/// defer pres.deinit(allocator);
/// ```
pub fn parse(allocator: Allocator, source: []const u8) ParseError!Presentation {
    // ...
}
```

---

### 3. Before Committing

#### 3.1 Mandatory Checks

Run these commands before every commit:

```bash
# 1. Format check
zig fmt --check src/

# 2. Build check
zig build

# 3. Test check
zig build test

# 4. Lint check (if available)
zig build verify 2>/dev/null || echo "No verify step"
```

**All must pass.** If they don't, fix before committing.

#### 3.2 Memory Check (for complex changes)

```bash
# Build with GPA leak detection
zig build test -Dleak-check=full

# Or for binary
zig build
valgrind --leak-check=full ./tuia examples/demo.md
```

#### 3.3 Update CHANGELOG

For user-visible changes:

```markdown
## [Unreleased]

### Added
- New feature X that does Y

### Fixed
- Bug where Z would happen

### Changed
- Behavior of W is now more intuitive
```

---

### 4. Committing

#### 4.1 Commit Message Format

Follow conventional commits:

```
<type>(<scope>): <description>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting (no code change)
- `refactor`: Code change (no behavior change)
- `test`: Adding/updating tests
- `chore`: Build/tooling changes

Examples:
```
feat(parser): add front matter parsing

Add YAML front matter parsing to extract title, author, date.
Supports both --- and +++ delimiters.

Closes #123
```

```
fix(render): handle zero-width terminals

Previously would panic when terminal width was 0.
Now returns error.TerminalTooSmall.

AC-PERF-002: Startup time remains <50ms
```

#### 4.2 Commit Granularity

| Change Size | Commit Count | Example |
|-------------|--------------|---------|
| Small fix | 1 commit | `fix: off-by-one in slide counting` |
| Feature | 1-3 commits | Separate parsing, rendering, tests |
| Large feature | Feature branch | Multiple commits, squash on merge |

---

### 5. After Committing

#### 5.1 Verify CI

Check that CI passes:

```bash
# If you have gh CLI
gh run list --limit 5

# Or check web interface
gh pr checks
```

#### 5.2 Handle Review

If changes requested:
1. Address each comment
2. Reply to each comment explaining change
3. Re-request review
4. Don't resolve comments yourself (let reviewer do it)

---

## Directory Structure Reference

```
tuia/
├── build.zig              # Build configuration
├── build.zig.zon          # Dependencies
├── src/
│   ├── main.zig           # Entry point
│   ├── root.zig           # Module exports
│   ├── cli.zig            # Command line parsing
│   ├── config/            # Configuration
│   ├── core/              # Core models
│   ├── parser/            # Markdown parsing
│   ├── render/            # Rendering
│   ├── widgets/           # UI widgets
│   ├── features/          # Images, execution, etc
│   └── infra/             # File watching, logging
├── tests/
│   ├── integration/       # Integration tests
│   ├── fixtures/          # Test data
│   └── golden/            # Golden files
├── examples/              # Example presentations
├── themes/                # Built-in themes
├── docs/                  # Documentation
│   ├── ARCHITECTURE.md
│   ├── API.md
│   └── specifications/
└── scripts/               # Helper scripts
```

---

## Common Tasks

### Adding a New Widget

1. Create `src/widgets/MyWidget.zig`
2. Implement Widget interface
3. Add unit tests in same file or `tests/widgets/MyWidget_test.zig`
4. Add to `src/widgets.zig` exports
5. Add example usage in `examples/`
6. Update documentation

### Adding a New Language for Highlighting

1. Add syntax definition to `src/features/highlight/languages/`
2. Add test file in `tests/fixtures/highlight/`
3. Update supported languages list
4. Verify with golden file test

### Adding a New Theme

1. Create `themes/mytheme.yaml`
2. Add screenshot/example
3. Update theme documentation
4. Test with `zigpresenterm -t mytheme examples/demo.md`

---

## Troubleshooting

### Build Failures

```bash
# Clean build
rm -rf zig-cache zig-out
zig build

# Verbose build
zig build --verbose

# Check Zig version
zig version  # Should be 0.15.0+
```

### Test Failures

```bash
# Run specific test
zig test src/parser/Parser.zig

# Run with filter
zig build test -Dtest-filter="parse slide"

# Update golden files
ZIG_UPDATE_GOLDEN=1 zig build test
```

### Memory Issues

```bash
# Check for leaks
zig build test -Dleak-check=full

# Debug allocator
zig build -Doptimize=Debug

# GDB debugging
gdb ./zig-out/bin/tuia
```

---

## Communication Guidelines

### When to Ask for Help

Ask when:
- Requirements are unclear
- Design decision needed (architecture)
- Security concern
- Performance concern
- Breaking change to API

Don't ask when:
- Clear from documentation
- Can be solved with quick search
- Minor style question (follow conventions)

### Updating Documentation

Always update docs when:
- Public API changes
- New feature added
- Behavior changes
- New dependency added

Never commit without:
- Checking if docs need updating
- Adding doc comments to new public APIs

---

## Checklist for AI Agents

Before submitting work:

```markdown
## Pre-Submission Checklist

### Code
- [ ] Implements all requirements from task
- [ ] Follows Zig style conventions
- [ ] No compiler warnings
- [ ] `zig fmt` clean
- [ ] All error paths handled
- [ ] No TODOs left (or documented)

### Testing
- [ ] Unit tests added
- [ ] Tests pass (`zig build test`)
- [ ] Edge cases covered
- [ ] Manual testing performed

### Quality
- [ ] Doc comments added
- [ ] Complex code explained
- [ ] CHANGELOG updated (if user-facing)
- [ ] No memory leaks

### Integration
- [ ] Builds on target platforms
- [ ] No conflicts with main
- [ ] CI will pass (predicted)
```

---

## Resources

### Documentation
- `PLAN.md` - Project roadmap
- `ACCEPTANCE_CRITERIA.md` - Quality criteria
- `DEFINITION_OF_DONE.md` - Exit criteria
- `docs/ARCHITECTURE.md` - System design
- `docs/API.md` - Public API reference

### External
- [Zig Language Reference](https://ziglang.org/documentation/master/)
- [libvaxis Documentation](https://github.com/rockorager/libvaxis)
- [Zig Style Guide](https://ziglang.org/documentation/master/#Style-Guide)

### Project-Specific
- `examples/demo.md` - Example presentation
- `themes/` - Theme examples
- `tests/fixtures/` - Test data examples

---

## Version

This guide applies to:
- **Project:** ZIGPRESENTERM / tuia
- **Phase:** Milestone 0-4
- **Stack:** Zig 0.15+, libvaxis
- **Last Updated:** 2026-03-01

---

*This document guides AI agents but applies to all contributors.*
