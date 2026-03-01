# Do Next

> Upcoming work for TUIA

---

## Current Phase: 2.1 - Markdown Parser

**Goal:** Parse presenterm-compatible Markdown into an AST

### Tasks

| ID | Task | Description | Est. Hours |
|----|------|-------------|------------|
| 2.1.1 | Scanner | Tokenize markdown | 8 |
| 2.1.2 | Block Parser | Parse blocks (paragraphs, lists, code) | 8 |
| 2.1.3 | Inline Parser | Parse inline (emphasis, code, links) | 8 |
| 2.1.4 | Front Matter Parser | YAML front matter | 4 |
| 2.1.5 | Slide Splitter | Split by `<!-- end_slide -->` | 4 |

### Deliverables

- `src/parser/Parser.zig` - Main parser
- `src/parser/Scanner.zig` - Tokenizer
- `src/parser/Block.zig` - Block-level parsing
- `src/parser/Inline.zig` - Inline parsing
- `src/parser/FrontMatter.zig` - YAML front matter
- Tests for all parser components

### Acceptance Criteria

- [ ] Can parse basic Markdown (headings, paragraphs, lists)
- [ ] Can parse code blocks with language tags
- [ ] Can parse inline formatting (bold, italic, code)
- [ ] Can parse YAML front matter
- [ ] Can split content by slide delimiters
- [ ] All test cases in `tests/fixtures/markdown/` pass
- [ ] Parser handles invalid input gracefully

---

## Upcoming Phases

### Phase 2.2: Slide Model
- Element types (Text, Heading, CodeBlock, etc.)
- Slide struct
- Presentation struct
- Validation

### Phase 2.3: Widget System
- Widget interface
- Slide widget
- Text, Heading, Code widgets

### Phase 2.4: Theme Engine
- Theme data model
- YAML parser for themes
- Style application

---

## PR Workflow

All work must be done via PRs:

1. Create feature branch: `git checkout -b feature/phase-2.1-parser`
2. Make changes
3. Push branch: `git push -u origin feature/phase-2.1-parser`
4. Create PR via GitHub
5. Wait for CI checks
6. Merge via squash

---

## Document Updates Required After Each Phase

After completing a phase, update:

1. **`PLAN.md`** - Mark phase as complete
2. **`STATUS.md`** - Update current phase
3. **`WHAT_WE_DID.md`** - Add completed work
4. **`DO_NEXT.md`** - Update upcoming tasks

---

*Last Updated: 2026-03-02*
