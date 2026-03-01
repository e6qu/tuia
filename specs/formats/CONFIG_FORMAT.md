# Configuration File Format

> Configuration file format for ZIGPRESENTERM.

**Status:** 📝 Draft  
**Owner:** @team  
**Date:** 2026-03-01

---

## Location

Config files are searched in order:

1. `$SLIDZ_CONFIG` environment variable
2. `$XDG_CONFIG_HOME/slidz/config.yaml` (Linux/macOS)
3. `~/.config/slidz/config.yaml` (Linux/macOS)
4. `~/Library/Application Support/slidz/config.yaml` (macOS)
5. `%APPDATA%/slidz/config.yaml` (Windows)

## Structure

```yaml
# Configuration version (for migrations)
version: "1.0"

# Default settings
defaults:
  theme: "dark"
  image_protocol: "auto"
  
  # Terminal font size (Windows mostly)
  terminal_font_size: 16
  
  # Presentation dimensions
  max_columns: 100
  max_columns_alignment: center
  max_rows: 50
  
  # Validation
  validate_overflows: "when_developing"
  
  # Incremental lists
  incremental_lists:
    pause_before: true
    pause_after: true

# Key bindings
bindings:
  next: ["l", "j", "right", " " ]
  previous: ["h", "k", "left"]
  first_slide: ["gg"]
  last_slide: ["G"]
  exit: ["q", "ctrl+c"]

# Snippet execution
snippet:
  exec:
    enable: false
  exec_replace:
    enable: false

# Slide transitions
transition:
  enabled: true
  duration_ms: 750
  frames: 45
  style: "fade"
```

## Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `defaults.theme` | string | `"dark"` | Default theme name |
| `defaults.image_protocol` | string | `"auto"` | Image protocol (auto/kitty/iterm2/sixel) |
| `defaults.terminal_font_size` | int | `null` | Terminal font size |
| `defaults.max_columns` | int | `null` | Max columns |
| `defaults.validate_overflows` | string | `"never"` | When to validate (never/always/when_presenting/when_developing) |
| `bindings.*` | array | varies | Key bindings |
| `snippet.exec.enable` | bool | `false` | Enable code execution |
| `transition.enabled` | bool | `true` | Enable transitions |
| `transition.style` | string | `"fade"` | Transition style |

---

*Config Format Spec v0.1*
