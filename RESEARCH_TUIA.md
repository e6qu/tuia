# Research: TUI-Based Presentation Tools

This document contains research on Terminal User Interface (TUI) based presentation tools that work with Markdown, exploring both off-the-shelf solutions and frameworks that can be used to build custom solutions.

**Date:** 2026-03-01  
**Research Goals:**
- Find tools that create presentations from Markdown documents
- Support for TUI window fitting/verification
- Transitions and animations where possible
- Interactivity features
- Open-source/free software solutions
- Python or TypeScript/JavaScript options for custom development

---

## Table of Contents

1. [Existing Off-the-Shelf Solutions](#1-existing-off-the-shelf-solutions)
2. [Frameworks & Libraries for Custom Solutions](#2-frameworks--libraries-for-custom-solutions)
3. [Feature Comparison Matrix](#3-feature-comparison-matrix)
4. [Recommendations for Custom Implementation](#4-recommendations-for-custom-implementation)
5. [Summary & Conclusions](#5-summary--conclusions)

---

## 1. Existing Off-the-Shelf Solutions

### 1.1 presenterm (Rust) ⭐ Highly Recommended

**Repository:** https://github.com/mfontanini/presenterm

**Overview:** A powerful Rust-based markdown terminal slideshow tool with extensive features.

**Key Features:**
- ✅ Pure Markdown input with `---` slide separators
- ✅ Images and animated GIFs (Kitty, iTerm2, WezTerm, Ghostty, Foot terminals)
- ✅ Highly customizable themes (colors, margins, layouts, footers)
- ✅ Code highlighting for many programming languages
- ✅ Font sizes for supported terminals
- ✅ Selective/dynamic code highlighting (reveal code line-by-line)
- ✅ Column layouts
- ✅ Mermaid graph rendering
- ✅ D2 graph rendering
- ✅ LaTeX and Typst formula rendering
- ✅ Introduction slide generation
- ✅ **Snippet execution** for various languages (including pseudo-terminals)
- ✅ **Export to PDF and HTML**
- ✅ **Slide transitions**
- ✅ **Pause portions of slides** (incremental reveals)
- ✅ Custom key bindings
- ✅ Auto-reload on file changes (live development)
- ✅ **Speaker notes** support

**Window Fitting:** Built-in margins and layout control

**Animations/Transitions:** Yes - slide transitions and incremental reveals

**Interactivity:** Code execution within slides

**Installation:** `cargo install presenterm` or download binary

---

### 1.2 slides (Go) ⭐ Popular Choice

**Repository:** https://github.com/maaslalani/slides

**Overview:** A simple but effective terminal-based presentation tool written in Go.

**Key Features:**
- ✅ Markdown-based slides with `---` separators
- ✅ Syntax highlighting via Glamour
- ✅ **Code execution** (press `Ctrl+E` to run code blocks)
- ✅ **Pre-processing support** (pipe code blocks through external tools)
- ✅ Theme customization via JSON
- ✅ Live reload on file changes
- ✅ **SSH server mode** (`slides serve`) - present remotely
- ✅ Search functionality (`/`)
- ✅ Vim-style navigation (j/k, h/l, gg, G)

**Window Fitting:** Automatic text wrapping

**Animations/Transitions:** Limited - no fancy transitions

**Interactivity:** Code execution, live editing

**Installation:** `go install github.com/maaslalani/slides@latest`

**Themes:** Uses Glamour themes (JSON-based)

---

### 1.3 patat (Haskell) ⭐ Feature-Rich

**Repository:** https://github.com/jaspervdj/patat

**Overview:** A mature, feature-rich presentation tool that runs in any ANSI terminal. Built on Pandoc.

**Key Features:**
- ✅ Supports multiple input formats (Markdown, reST, Org-mode) via Pandoc
- ✅ **Code evaluation** - execute code snippets and display results
- ✅ Syntax highlighting for ~100 languages (Kate syntax files)
- ✅ Auto-reload on file changes (`--watch`)
- ✅ **Speaker notes** (display in second window/monitor)
- ✅ **Incremental slide display** (fragments)
- ✅ **Experimental images support**
- ✅ **Transition effects**
- ✅ Smart slide splitting (by headers or `---`)
- ✅ Auto-advancing with configurable delay
- ✅ **Centering and re-wrapping text** to terminal width
- ✅ Theming with 24-bit RGB support
- ✅ Highly portable (only requires ANSI terminal, no ncurses)
- ✅ Margins configuration (left, right, top)

**Window Fitting:** Automatic text wrapping with proper indentation; margin controls

**Animations/Transitions:** Yes - transition effects between slides

**Interactivity:** Code evaluation, auto-advance

**Installation:** Available via package managers (Homebrew, apt, nix, etc.)

**Configuration:** YAML-based configuration

---

### 1.4 lookatme (Python) ⭐ Extensible

**Repository:** https://github.com/d0c-s4vage/lookatme

**Overview:** An interactive, extensible, terminal-based markdown presentation tool written in Python.

**Key Features:**
- ✅ Markdown rendering
- ✅ **Live terminals embedded directly in slides**
- ✅ Syntax highlighting via Pygments
- ✅ Loading external files into code blocks
- ✅ **Extension system** (contrib extensions)
- ✅ Smart slide splitting
- ✅ Progressive slides with `<!-- stop -->` comments
- ✅ Live reload (`--live`)
- ✅ Multiple built-in themes (dark, light, dracula, gruvbox, nord, solarized, etc.)
- ✅ Built-in tutorial (`lookatme --tutorial`)

**Window Fitting:** Automatic wrapping

**Animations/Transitions:** Progressive reveal via comments

**Interactivity:** Embedded live terminals, extensible

**Installation:** `pip install lookatme`

**Extensions:**
- `lookatme.contrib.qrcode` - QR code rendering
- `lookatme.contrib.image_ueberzug` - Image rendering (Linux)
- `lookatme.contrib.render` - Graphviz/Mermaid rendering

---

### 1.5 prezo (Python + Textual) ⭐ Modern & Featureful

**Repository:** https://github.com/abilian/prezo

**Overview:** A modern TUI presentation tool built with Textual (Python).

**Key Features:**
- ✅ Markdown with MARP/Deckset conventions (`---` separators)
- ✅ **Column layouts** via Pandoc-style fenced divs (`::: columns`)
- ✅ **Incremental lists** (reveal items one at a time)
- ✅ Live reload (auto-refresh on file changes)
- ✅ **Keyboard navigation** (Vim-style, arrows, etc.)
- ✅ **Slide overview** (grid view with `o`)
- ✅ **Search** (`/`)
- ✅ **Table of contents** (`t`)
- ✅ **Go to slide** (`:`)
- ✅ **Presenter notes** toggle (`p`)
- ✅ **6 built-in themes** (dark, light, dracula, solarized-dark, nord, gruvbox)
- ✅ **Timer/Clock** with countdown (`c`, `s`)
- ✅ **Edit slides in $EDITOR** (`e`)
- ✅ **Export to PDF, HTML, PNG, SVG**
- ✅ **Image support** (inline, background, MARP layout directives)
- ✅ Native image viewing (iTerm2/Kitty protocols with `i`)
- ✅ Blackout/Whiteout modes (`b`/`w`)
- ✅ Command palette (`Ctrl+P`)
- ✅ Config file support (`~/.config/prezo/config.toml`)
- ✅ Recent files tracking
- ✅ Position memory per file

**Window Fitting:** Responsive layout system

**Animations/Transitions:** Theme switching, incremental reveals

**Interactivity:** Command palette, search, editable

**Installation:** `pip install prezo` or `uv tool install prezo`

**Export Dependencies:** `pip install prezo[export]` (cairosvg, pypdf)

---

### 1.6 WOPR (Node.js + Blessed)

**Repository:** https://github.com/yaronn/wopr

**Overview:** A markup language for creating rich terminal reports, presentations, and infographics using XML.

**Key Features:**
- ✅ XML-based markup (not Markdown)
- ✅ 12x12 grid layout system
- ✅ Multiple widgets (bar charts, line charts, gauges, maps, tables, etc.)
- ✅ Multi-page presentations
- ✅ Viewable via curl (online viewer) or local viewer
- ✅ Based on blessed-contrib

**Window Fitting:** Grid-based positioning

**Animations/Transitions:** Manual or auto-advance

**Interactivity:** Navigation keys

**Installation:** `npm install -g wopr`

**Note:** Uses XML, not Markdown. Good for dashboards/reports rather than traditional presentations.

---

### 1.7 MDPT - Markdown Presentation Tool (Rust + GPU)

**Repository:** Part of rust_pixel: https://github.com/zipxing/rust_pixel

**Overview:** A unique GPU-independent rendering TUI presentation tool that doesn't require a terminal emulator.

**Key Features:**
- ✅ Renders terminal-style UI directly in a GPU window
- ✅ No terminal emulator required
- ✅ Built on rust_pixel framework
- ✅ Cross-platform window using winit + wgpu

**Window Fitting:** Controlled GPU rendering

**Animations/Transitions:** N/A (early stage)

**Interactivity:** Basic navigation

**Note:** Very new/experimental approach. Renders TUI aesthetics in a native GPU window.

---

### 1.8 slidec (Python)

**Repository:** https://github.com/pwhybra/slidec

**Overview:** A simple Python tool to present markdown in your terminal as slides.

**Key Features:**
- ✅ Simple Markdown to slides
- ✅ Basic navigation
- ✅ Good for command-line demos with notes

**Note:** Minimal feature set compared to others.

---

### 1.9 Go present tool

**Repository:** Part of `golang.org/x/tools/cmd/present`

**Overview:** The original Go present tool - web-based but terminal-friendly.

**Key Features:**
- ✅ Markdown-like syntax
- ✅ Code execution
- ✅ Web-based display
- ✅ Syntax highlighting

**Note:** Web-based, not true TUI, but worth mentioning for Go developers.

---

## 2. Frameworks & Libraries for Custom Solutions

### 2.1 Python Ecosystem

#### Textual (https://textual.textualize.io/) ⭐ Recommended

**Overview:** A modern, web-inspired Rapid Application Development framework for Python TUIs.

**Features for Presentations:**
- ✅ Rich widget library (Markdown viewer, DataTable, Static, etc.)
- ✅ Built-in **Markdown widget** with full rendering support
- ✅ CSS-like styling system
- ✅ **Animations and transitions** built-in
- ✅ Layout system (vertical, horizontal, grid, layers)
- ✅ Keyboard and mouse input handling
- ✅ **Reactive programming model**
- ✅ Can run in terminal OR web browser (`textual serve`)
- ✅ Command palette built-in
- ✅ Comprehensive testing framework

**Markdown Support:** Native Markdown widget with full CommonMark support

**Use Case:** Building a custom presentation tool with full control over behavior

**Example approach:**
```python
from textual.app import App, ComposeResult
from textual.widgets import Markdown, Static, Header, Footer
from textual.containers import Vertical

class PresentationApp(App):
    CSS = """
    Screen { align: center middle; }
    Markdown { width: 80; height: 100%; }
    """
    
    def compose(self) -> ComposeResult:
        yield Header()
        yield Markdown(self.slides[self.current_slide])
        yield Footer()
```

---

#### Rich (https://rich.readthedocs.io/)

**Overview:** A Python library for rich text and beautiful formatting in the terminal.

**Features for Presentations:**
- ✅ **Markdown rendering** with `rich.markdown`
- ✅ Syntax highlighting (Pygments)
- ✅ Tables, panels, progress bars
- ✅ Text styling (colors, bold, italic)
- ✅ Console markup (inline styling)
- ✅ Screen control
- ✅ Low-level terminal control

**Use Case:** Building simple slide renderers, or as a base for more complex tools

**Limitation:** Not a full TUI framework - better for rendering than interactive apps

---

#### prompt_toolkit

**Overview:** A library for building powerful interactive command lines in Python.

**Features:**
- ✅ Full-screen applications
- ✅ Layout engine
- ✅ Input handling
- ✅ Syntax highlighting

**Use Case:** Lower-level control than Textual

---

#### blessed (Python port)

**Overview:** A thin, practical wrapper around terminal capabilities in Python.

**Features:**
- ✅ Terminal handling
- ✅ Colors and styles
- ✅ Keyboard input
- ✅ Screen buffering

**Use Case:** Low-level TUI building

---

### 2.2 Rust Ecosystem

#### Ratatui (https://ratatui.rs/) ⭐ Recommended

**Overview:** The successor to tui-rs - a Rust crate for cooking up terminal user interfaces.

**Features for Presentations:**
- ✅ Widget-based architecture
- ✅ Layout system (constraints-based)
- ✅ Built-in widgets (Paragraph, Block, List, etc.)
- ✅ **Canvas for custom drawing**
- ✅ Input handling via crossterm
- ✅ High performance
- ✅ Active development with large ecosystem

**Markdown Support:** Requires parsing via separate crate (e.g., `pulldown-cmark`)

**Example:** tui-slides crate exists for presentations

**Use Case:** High-performance TUI presentation tool in Rust

---

#### cursive

**Overview:** A ncurses-based TUI library for Rust.

**Features:**
- ✅ Higher-level abstraction than Ratatui
- ✅ Built-in views and dialogs

**Note:** Less active than Ratatui

---

### 2.3 TypeScript/JavaScript/Node.js Ecosystem

#### Ink (https://github.com/vadimdemedes/ink) ⭐ Recommended for React developers

**Overview:** React for interactive command-line apps.

**Features for Presentations:**
- ✅ **React components** in terminal
- ✅ JSX support
- ✅ Hooks (useInput, useApp, etc.)
- ✅ Flexbox-like layout (Yoga)
- ✅ Input handling
- ✅ Built-in components (Box, Text, Newline, Spacer, Static)
- ✅ Extensive ecosystem of Ink components

**Markdown Support:** Use `ink-markdown` or parse with `marked`

**Use Case:** Building React-based CLI presentation tools

**Example approach:**
```tsx
import { render, Box, Text, useInput } from 'ink';
import Markdown from 'ink-markdown';

function Slide({ content, onNext }) {
  useInput((input) => {
    if (input === ' ') onNext();
  });
  
  return (
    <Box borderStyle="round" padding={1}>
      <Markdown>{content}</Markdown>
    </Box>
  );
}
```

---

#### Blessed & Blessed-contrib

**Repository:** https://github.com/chjj/blessed, https://github.com/yaronn/blessed-contrib

**Features:**
- ✅ High-level terminal interface API
- ✅ Widgets (box, list, form, etc.)
- ✅ blessed-contrib adds: charts, gauges, maps, etc.
- ✅ Terminal dashboard capabilities

**Note:** Older, may have compatibility issues with modern Node.js

---

#### React Blessed / React TUI

**Overview:** React bindings for blessed.

**Features:**
- ✅ React components for blessed widgets
- ✅ Declarative TUI development

---

### 2.4 Go Ecosystem

#### tview (https://github.com/rivo/tview)

**Overview:** Terminal UI library for Go.

**Features:**
- ✅ Rich widgets
- ✅ Layout primitives
- ✅ Application framework

**Use Case:** Building TUI apps in Go

---

#### bubbletea (https://github.com/charmbracelet/bubbletea)

**Overview:** A powerful little TUI framework based on The Elm Architecture.

**Features:**
- ✅ Model-Update-View architecture
- ✅ Composable
- ✅ Lipgloss for styling
- ✅ Bubbles for common components

**Use Case:** Modern Go TUI development (the slides tool uses similar patterns)

---

## 3. Feature Comparison Matrix

| Tool | Language | Markdown | Images | Code Exec | Export | Transitions | Live Reload | Themes | Notes |
|------|----------|----------|--------|-----------|--------|-------------|-------------|--------|-------|
| presenterm | Rust | ✅ | ✅ GIF | ✅ | PDF/HTML | ✅ | ✅ | ✅ JSON | Most feature-rich |
| slides | Go | ✅ | ⚠️ partial | ✅ | ❌ | ❌ | ✅ | ✅ JSON | Simple, SSH mode |
| patat | Haskell | ✅+ | ⚠️ exp. | ✅ | ❌ | ✅ | ✅ | ✅ YAML | Pandoc-based |
| lookatme | Python | ✅ | ✅ ext | ❌ | ❌ | ⚠️ | ✅ | ✅ | Extensible |
| prezo | Python | ✅ | ✅ | ❌ | PDF/HTML/PNG/SVG | ⚠️ | ✅ | ✅ 6 built-in | Most modern Python |
| WOPR | Node.js | ❌ XML | ✅ charts | ❌ | ❌ | ⚠️ | ❌ | ❌ | Dashboard focus |
| MDPT | Rust | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | GPU rendering |
| Textual | Python | Lib | Via lib | DIY | DIY | ✅ | DIY | DIY | Framework |
| Ratatui | Rust | Via lib | Via lib | DIY | DIY | DIY | DIY | DIY | Framework |
| Ink | TypeScript | Via lib | Via lib | DIY | DIY | ✅ | DIY | DIY | React-based |

Legend: ✅ = Yes, ⚠️ = Partial/Limited, ❌ = No, DIY = Build yourself, Via lib = Via external library

---

## 4. Recommendations for Custom Implementation

### 4.1 If you want to build a custom Python solution:

**Recommended Stack:**
```
Textual + Markdown widget + optional rich extensions
```

**Why:**
- Textual has the best combination of features and ease of use
- Built-in Markdown widget handles parsing/rendering
- CSS-like styling system
- Animation/transition support
- Can run in browser via `textual serve`
- Excellent documentation

**Implementation Sketch:**
```python
import re
from textual.app import App, ComposeResult
from textual.widgets import Markdown, Static, Header, Footer
from textual.containers import Container
from textual.reactive import reactive

class TUIAPresenter(App):
    """Markdown-based TUI Presentation Tool"""
    
    CSS = """
    Screen { align: center middle; }
    #slide-container { 
        width: 80; 
        height: auto;
        max-height: 100%;
        border: solid green;
        padding: 1 2;
    }
    """
    
    current_slide = reactive(0)
    
    def __init__(self, markdown_file: str):
        self.slides = self._parse_slides(markdown_file)
        super().__init__()
    
    def _parse_slides(self, path: str) -> list[str]:
        with open(path) as f:
            content = f.read()
        return [s.strip() for s in re.split(r'\n---\n', content)]
    
    def compose(self) -> ComposeResult:
        yield Header()
        with Container(id="slide-container"):
            yield Markdown(self.slides[0], id="slide-content")
        yield Footer()
    
    def watch_current_slide(self, slide: int):
        self.query_one("#slide-content", Markdown).update(self.slides[slide])
        self.query_one(Header).title = f"Slide {slide + 1}/{len(self.slides)}"
    
    def on_key(self, event):
        if event.key == "right" and self.current_slide < len(self.slides) - 1:
            self.current_slide += 1
        elif event.key == "left" and self.current_slide > 0:
            self.current_slide -= 1
```

---

### 4.2 If you want to build a custom TypeScript/JavaScript solution:

**Recommended Stack:**
```
Ink + ink-markdown + react hooks
```

**Why:**
- React patterns familiar to many developers
- Ink has good component ecosystem
- Easy to add custom interactivity
- Good for CLI-distributed tools

**Implementation Sketch:**
```tsx
import React, { useState, useEffect } from 'react';
import { render, Box, Text, useInput, useApp } from 'ink';
import Markdown from 'ink-markdown';
import { readFileSync } from 'fs';

const Presentation = ({ file }: { file: string }) => {
  const content = readFileSync(file, 'utf-8');
  const slides = content.split(/\n---\n/);
  const [current, setCurrent] = useState(0);
  const { exit } = useApp();
  
  useInput((input, key) => {
    if (key.rightArrow || input === ' ') {
      setCurrent(c => Math.min(c + 1, slides.length - 1));
    } else if (key.leftArrow) {
      setCurrent(c => Math.max(c - 1, 0));
    } else if (input === 'q') {
      exit();
    }
  });
  
  return (
    <Box flexDirection="column" padding={1}>
      <Box borderStyle="round" padding={1}>
        <Markdown>{slides[current]}</Markdown>
      </Box>
      <Text>Slide {current + 1} of {slides.length}</Text>
    </Box>
  );
};
```

---

### 4.3 If you want to build a custom Rust solution:

**Recommended Stack:**
```
Ratatui + crossterm + pulldown-cmark (Markdown parser)
```

**Why:**
- High performance
- Full control over rendering
- Cross-platform
- Growing ecosystem

**Implementation Sketch:**
```rust
use ratatui::{
    backend::CrosstermBackend,
    widgets::{Block, Borders, Paragraph, Wrap},
    Terminal,
};
use crossterm::event::{self, Event, KeyCode};
use pulldown_cmark::{Parser, Options};

struct Presentation {
    slides: Vec<String>,
    current: usize,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let backend = CrosstermBackend::new(std::io::stderr());
    let mut terminal = Terminal::new(backend)?;
    
    // Parse slides from markdown...
    let slides = parse_slides("presentation.md")?;
    let mut pres = Presentation { slides, current: 0 };
    
    loop {
        terminal.draw(|f| {
            let size = f.area();
            let block = Block::default().borders(Borders::ALL);
            let paragraph = Paragraph::new(pres.slides[pres.current].clone())
                .block(block)
                .wrap(Wrap { trim: true });
            f.render_widget(paragraph, size);
        })?;
        
        if let Event::Key(key) = event::read()? {
            match key.code {
                KeyCode::Right => pres.current = (pres.current + 1).min(pres.slides.len() - 1),
                KeyCode::Left => pres.current = pres.current.saturating_sub(1),
                KeyCode::Char('q') => break,
                _ => {}
            }
        }
    }
    Ok(())
}
```

---

### 4.4 Window Size Verification

For any custom implementation, consider adding window size verification:

**Python (Textual):**
```python
from textual.geometry import Size

def check_window_size(self) -> bool:
    size = self.size
    min_width, min_height = 80, 24
    if size.width < min_width or size.height < min_height:
        self.notify(
            f"Terminal too small! Minimum: {min_width}x{min_height}",
            severity="error"
        )
        return False
    return True
```

**TypeScript (Ink):**
```tsx
import { useStdout } from 'ink';

const { stdout } = useStdout();
useEffect(() => {
  const checkSize = () => {
    if (stdout.columns < 80 || stdout.rows < 24) {
      console.error('Terminal too small!');
    }
  };
  stdout.on('resize', checkSize);
  return () => stdout.off('resize', checkSize);
}, []);
```

---

## 5. Summary & Conclusions

### Quick Recommendations:

**For immediate use without development:**
1. **presenterm** - Most features, great image support, exports
2. **patat** - Most mature, excellent Pandoc integration
3. **prezo** - Best Python-based option, modern UI

**For building a custom tool:**
- **Python:** Textual (easiest, most productive)
- **TypeScript:** Ink (if you know React)
- **Rust:** Ratatui (best performance, most control)

### Key Findings:

1. **Markdown as source is well-supported** - All major tools use `---` as slide separator
2. **Images are tricky in terminal** - Best support via Kitty/iTerm2 graphics protocols
3. **Code execution is rare** - Only presenterm, slides, and patat support it
4. **Export capabilities vary** - Only presenterm and prezo export to PDF/HTML
5. **Transitions are limited** - patat has the best transition effects
6. **Live reload is standard** - Most tools support file watching
7. **Speaker notes supported** - presenterm, patat, prezo

### Suggested Architecture for "TUIA" (TUI Assistant):

If building a new tool, consider this feature set:

```yaml
Core:
  - Markdown input with YAML frontmatter
  - Slide separator: ---
  - Auto window size validation
  - Live reload

Rendering:
  - Textual (Python) or Ratatui (Rust)
  - Syntax highlighting
  - Table support
  - Basic image support (Kitty/iTerm2)

Navigation:
  - Arrow keys, vim bindings
  - Go to slide number
  - Search slides
  - Slide overview/grid view

Interactivity:
  - Incremental reveals (pause comments)
  - Speaker notes (separate pane)
  - Timer/countdown

Customization:
  - Theme system
  - Config file support
  - Export to static HTML
```

---

*Research compiled on 2026-03-01*
