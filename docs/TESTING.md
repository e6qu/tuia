# Testing TUIA

TUIA has three levels of testing: unit tests, integration tests, and TUI tests.

## Test Types

### 1. Unit Tests

Unit tests are embedded in source files and test individual functions.

```bash
zig build unit_test
```

### 2. Integration Tests

Integration tests are in `tests/` and test cross-module interactions (parser + converter + exporters).

```bash
zig build integration_test
```

### 3. TUI Tests

TUI tests use `expect` to drive the real terminal UI through a pty. They test startup, navigation, key handling, error cases, and export via CLI.

```bash
# Requires: expect (usually pre-installed on macOS/Linux)
expect scripts/test_tui.exp
```

The `TUIA_TTY_FD` environment variable is set by the test script so that tuia reads input from the pty instead of `/dev/tty`.

**25 tests** covering:
- Startup and quit (q, Ctrl-C)
- Navigation (j/k, arrows, space/backspace, g/G, number keys)
- Help toggle, rapid keystrokes, slide traversal
- Error handling (nonexistent file, unknown export format)
- All example files load without crash
- Small/wide terminal sizes
- CLI export (HTML, Reveal.js, Beamer, PDF)

## Pre-commit Hooks

Pre-commit hooks run `zig fmt`, lint, and unit tests automatically on every commit.

```bash
# Install (one-time)
pre-commit install

# Run manually
pre-commit run --all-files
```

## Test Fixtures

Test fixtures are in `tests/fixtures/`:

- `export_test_basic.md` — HTML export
- `export_test_elements.md` — Reveal.js export with all element types
- `export_test_latex.md` — Beamer/LaTeX export
- `export_test_special_chars.md` — LaTeX character escaping
- `export_test_table.md` — Table rendering
- `export_test_image.md` — Image handling
- `export_test_pdf.md` — PDF export
- `export_test_multi_format.md` — Round-trip across all formats

## CI Testing

Tests run automatically in GitHub Actions:

- **Unit/Integration Tests**: Run on every PR (Ubuntu + macOS)
- **TUI Tests**: Run via `expect` on Linux
- **Format Check**: `zig fmt --check`
- **Lint**: Build with no warnings
- **Cross-compilation**: x86_64-linux, aarch64-linux, x86_64-macos, aarch64-macos

## Platform Support

TUIA requires a POSIX system (Linux or macOS). Windows is not supported — the terminal layer uses `/dev/tty`, termios, ioctl, and SIGWINCH.

---

*Last updated: 2026-03-19*
