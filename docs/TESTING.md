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

### 4. Manual tmux Testing

For visual debugging, launch tuia inside tmux and capture screenshots. This is essential for verifying colors, layout, and transitions that automated tests can't cover.

```bash
# Build
zig build

# Launch in tmux (100x35 is a good size)
tmux new-session -d -s tuia -x 100 -y 35
tmux send-keys -t tuia "./zig-out/bin/tuia examples/feature-showcase.md" Enter

# Wait for startup, then capture
sleep 2
tmux capture-pane -t tuia -p  # captures text (no ANSI colors)

# Navigate slides
tmux send-keys -t tuia j      # next slide
tmux send-keys -t tuia k      # prev slide
tmux send-keys -t tuia g      # first slide
tmux send-keys -t tuia G      # last slide

# Jump to slide N
tmux send-keys -t tuia 5      # enter "5"
tmux send-keys -t tuia C-m    # confirm (Enter)

# Theme picker
tmux send-keys -t tuia t      # open picker
tmux send-keys -t tuia j      # move to "light"
tmux send-keys -t tuia C-m    # apply

# Quit
tmux send-keys -t tuia q
tmux kill-session -t tuia
```

**Key gotchas learned from testing:**
- `tmux send-keys Enter` works to send a raw Enter key, but `C-m` is more explicit
- `tmux capture-pane -p` strips ANSI colors — you only see text layout. To verify colors, look at the terminal directly or use `tmux capture-pane -e -p` for ANSI escape sequences
- The `Terminal.parseKey()` function maps `0x0D`/`0x0A` to `Key.enter` — but the Ctrl+letter handler (`0x01..0x1A`) must come AFTER the Enter/Tab handlers, since `0x0D` = Ctrl+M and `0x09` = Ctrl+I
- Always `sleep` after `send-keys` before `capture-pane` — the app needs time to process the key and render
- When testing transitions, the event loop uses 16ms timeout polling for animation — normal blocking mode for idle

**What to check visually:**
- Heading hierarchy (h1 bold+underlined, h2 bold, h3-h6 progressively dimmer)
- Code blocks: single-spacing, indentation, syntax colors, border box
- Tables: unified box with header separator
- Lists: nested indentation, bullet/number styling
- Status bar: slide counter left, title center, messages right (timed expiry)
- Themes: dark (bright text on dark), light (dark text on light background)
- Wide characters: CJK/emoji fill 2 columns without artifacts

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
