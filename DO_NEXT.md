# Do Next

> Upcoming work for TUIA

---

## Current Phase: 1.4 - Basic TUI Loop

**Goal:** Initialize libvaxis and create a basic TUI event loop

### Tasks

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 1.4.1 | Add libvaxis dependency | Update `build.zig.zon` with vaxis | 1 |
| 1.4.2 | Initialize vaxis | Basic terminal initialization | 2 |
| 1.4.3 | Event Loop | Input handling with vaxis events | 4 |
| 1.4.4 | Signal Handling | SIGINT, SIGWINCH handling | 2 |
| 1.4.5 | Cleanup | Proper terminal restoration | 2 |

### Acceptance Criteria
- [ ] App starts and exits cleanly
- [ ] Ctrl+C exits gracefully
- [ ] Terminal state restored on exit
- [ ] Resize handled without crash

### Implementation Notes

1. **Dependency:** Add to `build.zig.zon`:
```zig
.dependencies = .{
    .vaxis = .{
        .url = "git+https://github.com/rockorager/libvaxis.git#<commit-hash>",
        .hash = "...",
    },
}
```

2. **Main structure:**
```zig
const vaxis = @import("vaxis");

// Initialize vaxis
// Event loop
// Cleanup on exit
```

---

## Upcoming Phases

### Phase 1.x - Future Foundation Work
- Benchmark harness
- Property testing setup

### Phase 2.1: Markdown Parser
- Scanner/tokenizer
- Block parser (paragraphs, lists, code)
- Inline parser (emphasis, links)
- Front matter parser
- Slide splitter (`<!-- end_slide -->`)

### Phase 2.2: Slide Model
- Element types (Text, Heading, CodeBlock, etc.)
- Slide struct
- Presentation struct
- Validation

---

## PR Workflow

**Important:** All work from now on must be done via PRs:

1. Create feature branch: `git checkout -b feature/phase-1.4-tui`
2. Make changes
3. Push branch: `git push -u origin feature/phase-1.4-tui`
4. Create PR via GitHub
5. Wait for CI checks
6. Get review approval
7. Merge via squash

---

## Document Updates Required After Each Phase

After completing a phase, update:

1. **`PLAN.md`** - Mark phase as complete
2. **`STATUS.md`** - Update current phase
3. **`WHAT_WE_DID.md`** - Add completed work
4. **`DO_NEXT.md`** - Update upcoming tasks

---

*Last Updated: 2026-03-02*
