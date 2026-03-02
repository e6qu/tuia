# TUIA End-to-End Tests

This directory contains end-to-end tests for TUIA using [Microsoft TUI Test](https://github.com/microsoft/tui-test).

## Prerequisites

- Node.js 18+ 
- TUIA binary built (`zig build`)

## Setup

```bash
cd e2e
npm install
```

## Running Tests

```bash
# Run all tests
npm test

# Run tests with UI mode (for debugging)
npm run test:ui

# Run tests with debug output
npm run test:debug

# Run specific test file
npx tui-test tests/navigation.spec.ts
```

## Test Structure

- `tests/navigation.spec.ts` - Navigation key tests (j/k/g/G/?)
- `tests/snapshot.spec.ts` - Visual snapshot tests
- `tests/fixtures.ts` - Test utilities and sample presentations

## Snapshots

Snapshots are stored in the `snapshots/` directory. To update snapshots:

```bash
npx tui-test --update-snapshots
```

## Configuration

See `tui-test.config.ts` for test configuration including:
- Timeout settings
- Retry configuration
- Multiple shell support (bash, zsh)
- Reporter settings

## Writing New Tests

```typescript
import { test, expect } from '@microsoft/tui-test';
import { createTestPresentation, getTuiaBinary } from './fixtures.js';

test('my test', async ({ terminal }) => {
  const filePath = createTestPresentation('test', '# Hello\n\nWorld');
  
  await terminal.spawn(getTuiaBinary(), [filePath]);
  
  // Wait for content
  await expect(terminal.getByText('Hello')).toBeVisible();
  
  // Take screenshot
  const screenshot = await terminal.screenshot();
  await expect(screenshot).toMatchSnapshot('hello.png');
  
  // Clean up
  terminal.write('q');
  await terminal.waitForExit();
});
```

## CI Integration

The tests are configured to run in CI with the following features:
- Automatic retry on failure (flakiness handling)
- HTML report generation
- Screenshot capture on failure
- Trace recording for debugging
