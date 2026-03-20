# E2E Tests for TUIA

This directory contains end-to-end tests using Microsoft TUI Test and expect with real TTY.

## Test Approaches

### 1. Microsoft TUI Test (Experimental)

Uses `@microsoft/tui-test` for terminal testing. Currently limited in CI due to PTY compatibility issues.

**Status**: Basic smoke tests only - the terminal buffer remains empty in CI PTY environment.

### 2. Real TTY with expect (Working)

Uses `expect` with the `script` command to provide a real TTY for TUIA to render in.

**Status**: ✅ Fully working in CI with comprehensive tests.

## Running Tests

### Real TTY Tests (Recommended)

```bash
# Build TUIA first
zig build -Doptimize=ReleaseSafe

# Install expect (Ubuntu/Debian)
sudo apt-get install -y expect

# Run tests
export TUIA_BIN="$PWD/zig-out/bin/tuia"
export FIXTURE="$PWD/e2e/tests/fixtures/test-presentation.md"

# Run welcome screen test
expect /tmp/test_welcome.exp

# Run navigation test
expect /tmp/test_nav.exp
```

### Microsoft TUI Test (Local Only)

```bash
cd e2e
npm install
TUIA_BINARY=../zig-out/bin/tuia npm test
```

## CI Configuration

- **E2E Tests (Real TTY)**: Runs comprehensive tests using expect in a real TTY
- **E2E Tests (Microsoft TUI Test)**: Runs basic smoke tests (may have limited functionality)

## Test Coverage

### Real TTY Tests
- ✅ Welcome screen display
- ✅ Opening presentation files
- ✅ Navigation (j/k for next/previous slide)
- ✅ Jump commands (g/G for first/last slide)
- ✅ Help display (? key)

### Microsoft TUI Test
- ⚠️ Basic smoke tests only (start and quit)

## Fixtures

Test presentations are located in `tests/fixtures/`:
- `test-presentation.md` - Standard test presentation with multiple slides

## Known Limitations

### Microsoft TUI Test RC Version
The RC version has a limited API:
- No `test.describe()` or `test.beforeAll()`/`test.afterAll()`
- No `terminal.spawn()` per test - use `test.use()` at file level
- Some methods like `terminal.waitForTimeout()` are not available

### TTY Requirements
TUIA's terminal layer requires a real TTY/PTY to render correctly. The `script` command provides this in CI environments.
