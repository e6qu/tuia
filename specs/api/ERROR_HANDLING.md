# Error Handling Strategy

> Error handling approach for ZIGPRESENTERM.

**Status:** 📝 Draft  
**Owner:** @team  
**Date:** 2026-03-01

---

## Principles

1. **Explicit errors** - All errors are part of the type system
2. **No panics** - Graceful degradation, never crash
3. **Helpful messages** - Users get actionable error messages
4. **Proper cleanup** - Resources freed even on error

## Error Hierarchy

```zig
// Module-specific error sets
pub const ParseError = error{
    InvalidSyntax,
    InvalidFrontMatter,
    UnexpectedEof,
    OutOfMemory,
};

pub const RenderError = error{
    TerminalTooSmall,
    ImageLoadFailed,
    ImageProtocolNotSupported,
    OutOfMemory,
};

pub const ConfigError = error{
    FileNotFound,
    InvalidYaml,
    InvalidValue,
    OutOfMemory,
};

// Combined application error
pub const AppError = ParseError || RenderError || ConfigError || error{
    UserInterrupt,
    ExecutionFailed,
    ExportFailed,
};
```

## Error Handling Patterns

### Try for Propagation

```zig
const presentation = try Parser.parse(allocator, source);
```

### Catch for Recovery

```zig
const presentation = Parser.parse(allocator, source) catch |err| {
    std.log.err("Failed to parse: {}", .{err});
    return error.ParseFailed;
};
```

### Errdefer for Cleanup

```zig
const resource = try allocator.create(Resource);
errdefer allocator.destroy(resource);

const data = try loadData();
errdefer data.deinit();
```

## User-Facing Errors

Errors shown to users should:
1. Be clear and concise
2. Include context (file, line number)
3. Suggest fixes
4. Not expose internal details

```
Error: Failed to parse presentation.md
   |
 5 | ---
   | ^^^
   = Invalid YAML in front matter: expected string, got number

Fix: Check that the 'title' field is a string.
```

---

*Error Handling Spec v0.1*
