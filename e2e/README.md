# E2E Tests for TUIA

This directory contains end-to-end tests using Microsoft TUI Test.

## Status

⚠️ **E2E tests are currently disabled in CI** due to compatibility issues between
libvaxis (the TUI library used by TUIA) and the PTY environment provided by
the test runner. The terminal buffer remains empty when running in CI.

## Running Locally

E2E tests can be run locally where a real terminal is available:

```bash
# Build TUIA first
zig build -Doptimize=ReleaseSafe

# Install dependencies
cd e2e
npm install

# Run tests
TUIA_BINARY=../zig-out/bin/tuia npm test
```

## Test Structure

- `tests/welcome.spec.ts` - Tests for welcome screen
- `tests/presentation.spec.ts` - Tests for presentation navigation
- `tests/fixtures/` - Test fixture files

## Known Issues

1. **CI Compatibility**: libvaxis requires a real TTY terminal and doesn't render
   in the PTY environment used by Microsoft TUI Test in CI.
   
2. **RC Version API**: The Microsoft TUI Test RC version has a limited API:
   - No `test.describe()` or `test.beforeAll()`/`test.afterAll()`
   - No `terminal.spawn()` per test - use `test.use()` at file level
   - No `terminal.waitForTimeout()` or `terminal.waitForExit()`

## Future Work

- Investigate alternative testing approaches for TUI applications
- Consider using expect/tcl or a custom test harness
- Wait for stable release of Microsoft TUI Test
