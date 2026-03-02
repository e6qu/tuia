# Testing TUIA

TUIA has a comprehensive testing strategy including unit tests, integration tests, and end-to-end (E2E) tests.

## Test Types

### 1. Unit Tests

Unit tests are embedded in source files and run with `zig build test`.

```bash
# Run all unit tests
zig build test

# Run tests for a specific file
zig test src/parser/Parser.zig
```

### 2. Integration Tests

Integration tests are in the `tests/` directory and test module interactions.

```bash
# Run integration tests
zig build test
```

### 3. End-to-End Tests

E2E tests use [Microsoft TUI Test](https://github.com/microsoft/tui-test) to test the actual terminal UI.

```bash
cd e2e
npm install
npm test
```

## Snapshot Testing

### Zig Snapshot Testing

The Zig codebase includes snapshot testing utilities:

```zig
const tuia = @import("tuia");

// In your test
test "render output matches snapshot" {
    const output = try renderSomething(allocator);
    defer allocator.free(output);
    
    try tuia.test_utils.Snapshot.expectEqual(
        allocator,
        output,
        "render_test.snap",
        .{},
    );
}
```

Update snapshots:
```bash
ZIG_UPDATE_SNAPSHOTS=1 zig build test
```

### E2E Snapshot Testing

The E2E tests also use snapshot testing for visual regression:

```bash
cd e2e
npm test -- --update-snapshots
```

Snapshots are stored in:
- `e2e/snapshots/` - Visual screenshots from E2E tests
- `tests/__snapshots__/` - Text snapshots from Zig tests

## Writing E2E Tests

E2E tests are TypeScript files in `e2e/tests/`:

```typescript
import { test, expect } from '@microsoft/tui-test';

test('navigation works', async ({ terminal }) => {
  // Start TUIA
  await terminal.spawn('tuia', ['presentation.md']);
  
  // Wait for content
  await expect(terminal.getByText('Slide 1')).toBeVisible();
  
  // Interact
  terminal.write('j');
  
  // Assert
  await expect(terminal.getByText('Slide 2')).toBeVisible();
  
  // Screenshot for visual regression
  const screenshot = await terminal.screenshot();
  await expect(screenshot).toMatchSnapshot('slide-2.png');
});
```

## Test Fixtures

Test fixtures are in `tests/fixtures/`:

- `fixtures/*.md` - Sample presentations
- `fixtures/golden/*.txt` - Golden files for comparison

Create fixtures programmatically:

```typescript
import { createTestPresentation } from './fixtures.js';

const path = createTestPresentation('test', '# Hello\n\nWorld');
```

## CI Testing

Tests run automatically in GitHub Actions:

- **Unit/Integration Tests**: Run on every PR
- **E2E Tests**: Run on Ubuntu and macOS with bash and zsh
- **Snapshot Updates**: Can be triggered manually

### Debugging CI Failures

1. Download test results artifact from GitHub Actions
2. View HTML report in `test-results/html-report/`
3. Check traces in `test-results/traces/`

## Best Practices

1. **Unit tests**: Test pure functions, avoid I/O
2. **Integration tests**: Test module interactions
3. **E2E tests**: Test critical user journeys
4. **Snapshots**: Update intentionally, review carefully
5. **Fixtures**: Keep minimal but realistic
6. **Timeouts**: Use explicit waits, not fixed delays

## Troubleshooting

### Flaky Tests

If E2E tests are flaky:
- Increase timeout values
- Add explicit wait conditions
- Use `await terminal.waitForIdle()`
- Check for race conditions

### Snapshot Mismatches

If snapshots don't match:
1. Run locally with same terminal size (80x24)
2. Check for timing issues
3. Review visual differences carefully
4. Update only if changes are intentional
