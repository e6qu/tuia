# Do Next

> Upcoming work for TUIA

---

## Current Phase: 2.2 - Slide Model

**Goal:** Define and implement the slide presentation model

### Tasks

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 2.2.1 | Element Types | Define all AST element types | 4 |
| 2.2.2 | Slide Struct | Slide representation | 2 |
| 2.2.3 | Presentation Struct | Root model with metadata | 2 |
| 2.2.4 | Validation | Validate model invariants | 4 |
| 2.2.5 | Serialization | Debug printing | 2 |

### Deliverables

- `src/core/Slide.zig` - Slide model
- `src/core/Presentation.zig` - Root presentation model
- `src/core/Element.zig` - Element types (refined from AST)
- Validation functions
- Debug print/format functions

### Acceptance Criteria

- [ ] All element types defined (Heading, Paragraph, CodeBlock, List, etc.)
- [ ] Slide can contain multiple elements
- [ ] Presentation can contain multiple slides with metadata
- [ ] Model validation catches invalid states
- [ ] Can serialize to string for debugging

---

## Upcoming Phases

### Phase 2.3: Widget System
- Widget interface
- Slide widget
- Text, Heading, Code widgets

### Phase 2.4: Theme Engine
- Theme data model
- YAML parser for themes
- Style application

### Phase 2.5: Navigation & Input
- Key binding system
- Slide navigation
- Jump to slide

---

## PR Workflow

All work must be done via PRs:

1. Create feature branch: `git checkout -b feature/phase-2.2-slide-model`
2. Make changes
3. Push branch: `git push -u origin feature/phase-2.2-slide-model`
4. Create PR via GitHub
5. Wait for CI checks
6. You merge when CI passes

---

## Document Updates Required After Each Phase

After completing a phase, update:

1. **`PLAN.md`** - Mark phase as complete
2. **`STATUS.md`** - Update current phase
3. **`WHAT_WE_DID.md`** - Add completed work
4. **`DO_NEXT.md`** - Update upcoming tasks

---

*Last Updated: 2026-03-02*
