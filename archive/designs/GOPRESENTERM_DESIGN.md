# Go Clean-Room Reimplementation of presenterm

> A theoretical architecture and implementation guide for building a presenterm-compatible (or inspired) presentation tool in Go.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Core Components](#core-components)
3. [Implementation Strategy](#implementation-strategy)
4. [Directory Structure](#directory-structure)
5. [Key Modules](#key-modules)
6. [Data Flow](#data-flow)
7. [External Dependencies](#external-dependencies)
8. [Phase-by-Phase Implementation Plan](#phase-by-phase-implementation-plan)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           GOPRESENTERM                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│  CLI Layer (cmd/)                                                            │
│  ├── Flag parsing (cobra or stdlib flag)                                     │
│  ├── Config loading (yaml)                                                   │
│  └── Entry point orchestration                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│  Core Engine (pkg/core/)                                                     │
│  ├── Presentation Model (AST-like structure)                                 │
│  ├── Event Loop (input handling)                                             │
│  ├── State Machine (slide navigation)                                        │
│  └── Lifecycle management (init, render, cleanup)                            │
├─────────────────────────────────────────────────────────────────────────────┤
│  Parser (pkg/parser/)                                                        │
│  ├── Markdown lexer                                                          │
│  ├── Front matter parser (yaml)                                              │
│  ├── Slide splitter (<!-- end_slide -->)                                     │
│  ├── Command parser (HTML comments)                                          │
│  └── Code block attribute parser                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  Renderer (pkg/render/)                                                      │
│  ├── Terminal abstraction (tcell or termenv)                                 │
│  ├── Layout engine (constraint-based)                                        │
│  ├── Text wrapping & alignment                                               │
│  ├── Theme application                                                       │
│  ├── Code highlighting (chroma)                                              │
│  └── Image rendering (kitty/iterm2/sixel)                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│  Widget System (pkg/widgets/)                                                │
│  ├── Slide widget                                                            │
│  ├── Code block widget                                                       │
│  ├── Image widget                                                            │
│  ├── Table widget                                                            │
│  ├── List widget                                                             │
│  └── Modal widgets (index, help)                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  Features (pkg/features/)                                                    │
│  ├── Image protocols (kitty, iterm2, sixel)                                  │
│  ├── Code execution (sandboxed)                                              │
│  ├── Diagram rendering (mermaid, d2)                                         │
│  ├── LaTeX/typst rendering                                                   │
│  ├── Slide transitions                                                       │
│  └── Export (pdf, html)                                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│  Infrastructure (pkg/infra/)                                                 │
│  ├── File watcher (fsnotify)                                                 │
│  ├── Config management                                                       │
│  ├── Logging                                                                 │
│  └── Error handling                                                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. Presentation Model

```go
// pkg/core/presentation.go

package core

import "time"

// Presentation is the root model
type Presentation struct {
    Metadata   FrontMatter
    Slides     []Slide
    Theme      Theme
    Config     Config
    
    // Runtime state
    CurrentSlide int
    Mode         PresentationMode
    
    // Execution state
    SnippetOutputs map[string]string
    
    // Modals
    ShowIndex    bool
    ShowHelp     bool
    ShowGrid     bool
}

type FrontMatter struct {
    Title       string
    SubTitle    string
    Author      string
    Authors     []string
    Date        string
    Event       string
    Location    string
    Theme       string
}

type PresentationMode int

const (
    ModeDevelopment PresentationMode = iota
    ModePresent
)

type Slide struct {
    Title       string
    Content     []Element
    Layout      *ColumnLayout
    SpeakerNotes string
    Index       int
}

// Element is a union type for all slide content
type Element interface {
    elementType() ElementType
}

type ElementType int

const (
    ElementText ElementType = iota
    ElementHeading
    ElementCode
    ElementList
    ElementTable
    ElementImage
    ElementBlockQuote
    ElementThematicBreak
    ElementPause
)
```

### 2. Layout Engine

```go
// pkg/render/layout.go

package render

import "image"

// LayoutEngine computes widget positions
type LayoutEngine struct {
    TerminalSize image.Point
    Theme        Theme
    MaxColumns   int
    MaxRows      int
}

// Constraint-based layout (similar to Flutter/Ratatui)
type Constraints struct {
    MinWidth, MaxWidth   int
    MinHeight, MaxHeight int
}

type Size struct {
    Width, Height int
}

type Position struct {
    X, Y int
}

type Rect struct {
    Position
    Size
}

// LayoutNode is a positioned element
type LayoutNode struct {
    Rect
    Content Element
    Children []LayoutNode
}

func (le *LayoutEngine) ComputeLayout(slide Slide) LayoutNode {
    // Calculate available space
    // Apply margins from theme
    // Position each element
    // Handle column layouts
}

// Column layout support
type ColumnLayout struct {
    Ratios []int  // e.g., [3, 2] means 3:2 ratio
    CurrentColumn int
}

func (le *LayoutEngine) ApplyColumnLayout(
    node *LayoutNode, 
    layout *ColumnLayout,
) {
    total := sum(layout.Ratios)
    availableWidth := node.Width
    
    x := node.X
    for i, ratio := range layout.Ratios {
        colWidth := availableWidth * ratio / total
        // Create child node for column
        node.Children[i] = LayoutNode{
            Rect: Rect{
                Position: Position{X: x, Y: node.Y},
                Size: Size{Width: colWidth, Height: node.Height},
            },
        }
        x += colWidth
    }
}
```

### 3. Terminal Abstraction

```go
// pkg/render/terminal.go

package render

import (
    "image"
    
    "github.com/gdamore/tcell/v2"
)

// Terminal handles low-level terminal operations
type Terminal struct {
    Screen tcell.Screen
    Size   image.Point
    
    // Capabilities
    SupportsTrueColor    bool
    SupportsKittyImages  bool
    SupportsItermImages  bool
    SupportsSixel        bool
    SupportsFontSizes    bool
}

func NewTerminal() (*Terminal, error) {
    screen, err := tcell.NewScreen()
    if err != nil {
        return nil, err
    }
    
    if err := screen.Init(); err != nil {
        return nil, err
    }
    
    t := &Terminal{
        Screen:            screen,
        SupportsTrueColor: screen.Colors() >= 256,
    }
    
    // Detect image protocols via environment/CSI queries
    t.detectImageProtocols()
    
    return t, nil
}

func (t *Terminal) detectImageProtocols() {
    // Check TERM, TERM_PROGRAM, etc.
    // Send CSI queries for kitty/iterm2 detection
    // Check for sixel support
}

func (t *Terminal) DrawText(x, y int, text string, style Style) {
    // Convert our Style to tcell.Style
    ts := tcell.StyleDefault.
        Foreground(tcell.ColorHex(style.Foreground)).
        Background(tcell.ColorHex(style.Background)).
        Bold(style.Bold).
        Italic(style.Italic).
        Underline(style.Underlined)
    
    for i, r := range text {
        t.Screen.SetContent(x+i, y, r, nil, ts)
    }
}

func (t *Terminal) DrawImage(x, y int, img Image) error {
    switch img.Protocol {
    case ImageProtocolKitty:
        return t.drawKittyImage(x, y, img)
    case ImageProtocolIterm2:
        return t.drawItermImage(x, y, img)
    case ImageProtocolSixel:
        return t.drawSixelImage(x, y, img)
    case ImageProtocolASCII:
        return t.drawASCIIImage(x, y, img)
    default:
        return ErrUnsupportedImageProtocol
    }
}

func (t *Terminal) SetFontSize(size int) error {
    if !t.SupportsFontSizes {
        return ErrFontSizeNotSupported
    }
    // Send kitty font size OSC sequence
    return nil
}

func (t *Terminal) Clear() {
    t.Screen.Clear()
}

func (t *Terminal) Present() {
    t.Screen.Show()
}

func (t *Terminal) Size() (int, int) {
    return t.Screen.Size()
}

func (t *Terminal) Close() {
    t.Screen.Fini()
}
```

---

## Implementation Strategy

### Design Philosophy

1. **Clean separation of concerns**: Parser → Model → Layout → Render
2. **Interface-driven design**: Easy to test and mock
3. **Event-driven architecture**: Handle async events (input, file changes)
4. **Plugin architecture**: Extensible for code executors, image protocols

### Technology Choices

| Component | Primary Choice | Alternatives |
|-----------|---------------|--------------|
| Terminal library | `tcell` | `termenv`, `lipgloss` |
| Markdown parser | `goldmark` | `blackfriday`, custom |
| YAML parsing | `gopkg.in/yaml.v3` | - |
| Syntax highlighting | `github.com/alecthomas/chroma` | `highlighting` goldmark ext |
| File watching | `fsnotify` | polling |
| CLI framework | `cobra` | `urfave/cli`, stdlib |
| Logging | `slog` (std) | `zap`, `logrus` |
| Image processing | `image` (std) + `imaging` | - |
| PDF export | `gofpdf` + `chromedp` | `weasyprint` wrapper |
| Config | `koanf` | `viper` |

---

## Directory Structure

```
gopresenterm/
├── cmd/
│   └── gopresenterm/
│       └── main.go              # Entry point
├── pkg/
│   ├── core/
│   │   ├── presentation.go      # Core data models
│   │   ├── engine.go            # Main presentation engine
│   │   ├── state.go             # State machine
│   │   └── events.go            # Event definitions
│   ├── parser/
│   │   ├── markdown.go          # Goldmark-based parser
│   │   ├── frontmatter.go       # YAML front matter
│   │   ├── commands.go          # HTML comment commands
│   │   ├── code_attributes.go   # Code block +exec, +line_numbers, etc
│   │   └── highlight.go         // Dynamic highlighting {1-4|6-8}
│   ├── render/
│   │   ├── terminal.go          # Tcell abstraction
│   │   ├── layout.go            # Constraint-based layout
│   │   ├── renderer.go          # Main render coordinator
│   │   ├── theme.go             # Theme application
│   │   ├── text.go              # Text wrapping, alignment
│   │   └── export.go            # PDF/HTML export
│   ├── widgets/
│   │   ├── widget.go            # Widget interface
│   │   ├── slide.go             # Slide container
│   │   ├── text.go              # Text blocks
│   │   ├── code.go              # Code blocks with syntax highlighting
│   │   ├── image.go             # Image widgets
│   │   ├── list.go              # List widgets
│   │   ├── table.go             # Table widgets
│   │   ├── modal_index.go       # Slide index modal
│   │   └── modal_help.go        # Help modal
│   ├── features/
│   │   ├── images/
│   │   │   ├── protocol.go      # Image protocol interface
│   │   │   ├── kitty.go         # Kitty graphics protocol
│   │   │   ├── iterm2.go        # iTerm2 image protocol
│   │   │   ├── sixel.go         # Sixel support
│   │   │   └── ascii.go         # ASCII fallback
│   │   ├── executor/
│   │   │   ├── executor.go      # Code execution interface
│   │   │   ├── sandbox.go       # Execution sandboxing
│   │   │   ├── runners.go       # Language-specific runners
│   │   │   └── pty.go           # PTY support
│   │   ├── diagrams/
│   │   │   ├── mermaid.go       # Mermaid diagram rendering
│   │   │   └── d2.go            # D2 diagram rendering
│   │   ├── math/
│   │   │   ├── latex.go         # LaTeX formula rendering
│   │   │   └── typst.go         # Typst formula rendering
│   │   └── transitions/
│   │       ├── transition.go    # Transition interface
│   │       ├── fade.go          # Fade transition
│   │       ├── slide.go         # Slide horizontal
│   │       └── collapse.go      # Collapse horizontal
│   ├── theme/
│   │   ├── theme.go             # Theme data model
│   │   ├── loader.go            # Theme loading
│   │   ├── builtin.go           # Built-in themes (embedded)
│   │   └── colors.go            # Color utilities
│   ├── config/
│   │   ├── config.go            # Configuration model
│   │   ├── loader.go            # Config loading
│   │   └── defaults.go          # Default values
│   └── infra/
│       ├── watcher.go           # File watching
│       ├── logger.go            # Logging setup
│       └── errors.go            # Error types
├── internal/
│   └── utils/
│       ├── strings.go           # String utilities
│       ├── path.go              # Path utilities
│       └── math.go              # Math utilities
├── themes/                      # Built-in theme files
│   ├── dark.yaml
│   ├── light.yaml
│   └── ...
├── examples/                    # Example presentations
│   └── demo.md
├── go.mod
├── go.sum
├── Makefile
└── README.md
```

---

## Key Modules

### 1. Parser Module

```go
// pkg/parser/markdown.go

package parser

import (
    "github.com/yuin/goldmark"
    "github.com/yuin/goldmark/ast"
    "github.com/yuin/goldmark/text"
)

// Parser converts markdown to Presentation
type Parser struct {
    md goldmark.Markdown
}

func New() *Parser {
    return &Parser{
        md: goldmark.New(
            goldmark.WithExtensions(
                // Add extensions as needed
            ),
        ),
    }
}

func (p *Parser) Parse(source []byte, path string) (*core.Presentation, error) {
    // 1. Extract front matter
    fm, remaining := extractFrontMatter(source)
    
    // 2. Split into slides
    slides := splitSlides(remaining)
    
    // 3. Parse each slide
    var parsedSlides []core.Slide
    for i, slideSource := range slides {
        slide, err := p.parseSlide(slideSource, i)
        if err != nil {
            return nil, err
        }
        parsedSlides = append(parsedSlides, slide)
    }
    
    return &core.Presentation{
        Metadata: fm,
        Slides:   parsedSlides,
    }, nil
}

func splitSlides(source []byte) [][]byte {
    // Split by <!-- end_slide -->
    // Handle <!-- end_slide_shorthand: true --> config for ---
}

func (p *Parser) parseSlide(source []byte, index int) (core.Slide, error) {
    // Parse markdown AST
    doc := p.md.Parser().Parse(text.NewReader(source))
    
    var elements []core.Element
    var layout *core.ColumnLayout
    
    // Walk AST
    ast.Walk(doc, func(n ast.Node, entering bool) (ast.WalkStatus, error) {
        if !entering {
            return ast.WalkContinue, nil
        }
        
        switch node := n.(type) {
        case *ast.Heading:
            elements = append(elements, p.parseHeading(node, source))
        case *ast.FencedCodeBlock:
            elements = append(elements, p.parseCodeBlock(node, source))
        case *ast.List:
            elements = append(elements, p.parseList(node, source))
        case *ast.Table:
            elements = append(elements, p.parseTable(node, source))
        case *ast.Image:
            elements = append(elements, p.parseImage(node, source))
        case *ast.HTMLBlock:
            // Check for comment commands
            cmd := parseCommentCommand(node, source)
            if cmd != nil {
                switch c := cmd.(type) {
                case *ColumnLayoutCommand:
                    layout = c.ToLayout()
                case *PauseCommand:
                    elements = append(elements, core.Pause{})
                // ... etc
                }
            }
        }
        return ast.WalkContinue, nil
    })
    
    return core.Slide{
        Content: elements,
        Layout:  layout,
        Index:   index,
    }, nil
}
```

### 2. Code Execution Module

```go
// pkg/features/executor/executor.go

package executor

import (
    "context"
    "os/exec"
    "time"
)

// Executor runs code snippets
type Executor interface {
    Execute(ctx context.Context, req ExecuteRequest) (*ExecuteResult, error)
    Supports(language string) bool
}

// ExecuteRequest is a code execution request
type ExecuteRequest struct {
    Language    string
    Code        string
    UsePTY      bool
    PTYSize     *Size
    Alternative string // e.g., "rust-script"
}

type ExecuteResult struct {
    Stdout   string
    Stderr   string
    ExitCode int
    Duration time.Duration
}

// Registry of executors
type Registry struct {
    executors map[string]Executor
}

func NewRegistry() *Registry {
    r := &Registry{executors: make(map[string]Executor)}
    
    // Register built-in executors
    r.Register("bash", &ShellExecutor{shell: "bash"})
    r.Register("python", &PythonExecutor{})
    r.Register("rust", &RustExecutor{})
    r.Register("go", &GoExecutor{})
    // ... more
    
    return r
}

func (r *Registry) Register(language string, e Executor) {
    r.executors[language] = e
}

func (r *Registry) Get(language string) (Executor, bool) {
    e, ok := r.executors[language]
    return e, ok
}

// ShellExecutor implementation
type ShellExecutor struct {
    shell string
}

func (se *ShellExecutor) Execute(ctx context.Context, req ExecuteRequest) (*ExecuteResult, error) {
    if req.UsePTY {
        return se.executeWithPTY(ctx, req)
    }
    
    cmd := exec.CommandContext(ctx, se.shell, "-c", req.Code)
    
    output, err := cmd.CombinedOutput()
    
    exitCode := 0
    if exitErr, ok := err.(*exec.ExitError); ok {
        exitCode = exitErr.ExitCode()
    }
    
    return &ExecuteResult{
        Stdout:   string(output),
        ExitCode: exitCode,
    }, nil
}

func (se *ShellExecutor) Supports(language string) bool {
    return language == se.shell || language == "sh"
}
```

### 3. Image Protocol Module

```go
// pkg/features/images/protocol.go

package images

import (
    "fmt"
    "image"
)

// Protocol represents an image rendering protocol
type Protocol interface {
    Name() string
    Render(img image.Image, options RenderOptions) ([]byte, error)
    Supported() bool
}

// RenderOptions for image rendering
type RenderOptions struct {
    Width    int     // Terminal columns
    Height   int     // Terminal rows
    MaxWidth *int    // Optional max width percentage
}

// ProtocolType identifies image protocols
type ProtocolType int

const (
    ProtocolNone ProtocolType = iota
    ProtocolKitty
    ProtocolIterm2
    ProtocolSixel
    ProtocolASCII
)

// Manager handles image protocol selection
type Manager struct {
    preferred ProtocolType
    protocols map[ProtocolType]Protocol
}

func NewManager(preferred ProtocolType) *Manager {
    m := &Manager{
        preferred: preferred,
        protocols: make(map[ProtocolType]Protocol),
    }
    
    // Register protocols
    m.protocols[ProtocolKitty] = &KittyProtocol{}
    m.protocols[ProtocolIterm2] = &Iterm2Protocol{}
    m.protocols[ProtocolSixel] = &SixelProtocol{}
    m.protocols[ProtocolASCII] = &ASCIIProtocol{}
    
    return m
}

func (m *Manager) Select() Protocol {
    if m.preferred != ProtocolNone {
        if p := m.protocols[m.preferred]; p.Supported() {
            return p
        }
    }
    
    // Auto-detect
    for _, proto := range []ProtocolType{
        ProtocolKitty, ProtocolIterm2, ProtocolSixel,
    } {
        if p := m.protocols[proto]; p.Supported() {
            return p
        }
    }
    
    // Fallback to ASCII
    return m.protocols[ProtocolASCII]
}

// KittyProtocol implements kitty graphics protocol
// https://sw.kovidgoyal.net/kitty/graphics-protocol/
type KittyProtocol struct{}

func (k *KittyProtocol) Name() string { return "kitty" }

func (k *KittyProtocol) Render(img image.Image, opts RenderOptions) ([]byte, error) {
    // Resize image to fit terminal
    resized := resizeImage(img, opts)
    
    // Encode as PNG
    var buf bytes.Buffer
    if err := png.Encode(&buf, resized); err != nil {
        return nil, err
    }
    
    data := buf.Bytes()
    
    // Build kitty escape sequence
    // Format: _Ga=T,f=100,s=<w>,v=<h>,<base64 data>_G\\
    
    const chunkSize = 4096
    var result strings.Builder
    
    encoded := base64.StdEncoding.EncodeToString(data)
    
    bounds := resized.Bounds()
    header := fmt.Sprintf("_Ga=T,f=100,s=%d,v=%d;",
        bounds.Dx(), bounds.Dy())
    
    // Split into chunks if necessary
    for i := 0; i < len(encoded); i += chunkSize {
        end := i + chunkSize
        if end > len(encoded) {
            end = len(encoded)
        }
        
        chunk := encoded[i:end]
        if i == 0 {
            result.WriteString("\x1b" + header + chunk)
        } else {
            result.WriteString("\x1b_Gm=1;" + chunk)
        }
        
        if end < len(encoded) {
            result.WriteString("\x1b\\")
        } else {
            result.WriteString("\x1b\\")
        }
    }
    
    return []byte(result.String()), nil
}

func (k *KittyProtocol) Supported() bool {
    // Check TERM, KITTY_WINDOW_ID, etc.
    return os.Getenv("TERM") == "xterm-kitty" ||
           os.Getenv("KITTY_WINDOW_ID") != ""
}
```

### 4. Theme System

```go
// pkg/theme/theme.go

package theme

// Theme defines presentation styling
type Theme struct {
    Name    string
    Default Style `yaml:"default"`
    
    IntroSlide IntroSlideStyle `yaml:"intro_slide"`
    SlideTitle HeadingStyle    `yaml:"slide_title"`
    Headings   HeadingsStyle    `yaml:"headings"`
    Footer     FooterStyle      `yaml:"footer"`
    BlockQuote BlockQuoteStyle  `yaml:"block_quote"`
    List       ListStyle        `yaml:"list"`
    Table      TableStyle       `yaml:"table"`
    Code       CodeStyle        `yaml:"code"`
    
    Palette Palette `yaml:"palette"`
}

type Style struct {
    Colors    Colors  `yaml:"colors"`
    Alignment Alignment `yaml:"alignment"`
    Margin    Margin  `yaml:"margin"`
}

type Colors struct {
    Foreground string `yaml:"foreground"`
    Background string `yaml:"background"`
}

type Alignment struct {
    Type       string  `yaml:"type"` // left, center, right
    Fixed      int     `yaml:"fixed,omitempty"`
    Percent    int     `yaml:"percent,omitempty"`
    MinimumSize int    `yaml:"minimum_size,omitempty"`
}

type Margin struct {
    Left  int `yaml:"left"`
    Right int `yaml:"right"`
    Top   int `yaml:"top"`
    Bottom int `yaml:"bottom"`
}

type HeadingStyle struct {
    Style    `yaml:",inline"`
    Prefix   string `yaml:"prefix"`
    FontSize int    `yaml:"font_size"`
    PaddingTop    int  `yaml:"padding_top"`
    PaddingBottom int  `yaml:"padding_bottom"`
    Separator     bool `yaml:"separator"`
    Bold          bool `yaml:"bold"`
    Underlined    bool `yaml:"underlined"`
    Italics       bool `yaml:"italics"`
}

type FooterStyle struct {
    Style  `yaml:",inline"`
    Type   string            `yaml:"style"` // template, progress_bar, empty
    Left   string            `yaml:"left,omitempty"`
    Center string            `yaml:"center,omitempty"`
    Right  string            `yaml:"right,omitempty"`
    Height int               `yaml:"height"`
}

type Palette struct {
    Classes map[string]Colors `yaml:"classes"`
}

// Loader loads themes from files
type Loader struct {
    builtin map[string]Theme
    paths   []string
}

func NewLoader() *Loader {
    l := &Loader{
        builtin: make(map[string]Theme),
        paths: []string{
            "~/.config/gopresenterm/themes/",
            "/usr/share/gopresenterm/themes/",
        },
    }
    
    // Load built-in themes (embedded)
    l.loadBuiltin()
    
    return l
}

func (l *Loader) Load(name string) (Theme, error) {
    // 1. Check builtins
    if t, ok := l.builtin[name]; ok {
        return t, nil
    }
    
    // 2. Search paths
    for _, path := range l.paths {
        expanded := expandPath(path)
        file := filepath.Join(expanded, name+".yaml")
        if _, err := os.Stat(file); err == nil {
            return l.loadFromFile(file)
        }
    }
    
    return Theme{}, ErrThemeNotFound
}

//go:embed themes/*.yaml
var builtinThemes embed.FS

func (l *Loader) loadBuiltin() {
    entries, _ := builtinThemes.ReadDir("themes")
    for _, entry := range entries {
        data, _ := builtinThemes.ReadFile("themes/" + entry.Name())
        var theme Theme
        yaml.Unmarshal(data, &theme)
        l.builtin[theme.Name] = theme
    }
}
```

### 5. Event Loop & Input Handling

```go
// pkg/core/engine.go

package core

import (
    "context"
    
    "github.com/gdamore/tcell/v2"
)

// Engine is the main presentation engine
type Engine struct {
    presentation *Presentation
    terminal     *render.Terminal
    renderer     *render.Renderer
    config       config.Config
    
    // State
    running      bool
    needsRender  bool
    
    // Async handlers
    fileWatcher  *infra.FileWatcher
    executor     *executor.Registry
    
    // Channels
    events       chan Event
    commands     chan Command
}

// Event represents a user or system event
type Event interface {
    eventType() string
}

type KeyEvent struct {
    Key  tcell.Key
    Rune rune
    Mod  tcell.ModMask
}

type ResizeEvent struct {
    Width, Height int
}

type FileChangeEvent struct {
    Path string
}

type Command interface {
    commandType() string
}

type NavigateCommand struct {
    Direction Direction
}

type Direction int

const (
    DirNext Direction = iota
    DirPrevious
    DirFirst
    DirLast
    DirGoTo
)

func NewEngine(pres *Presentation, term *render.Terminal, cfg config.Config) *Engine {
    return &Engine{
        presentation: pres,
        terminal:     term,
        renderer:     render.NewRenderer(term, cfg),
        config:       cfg,
        events:       make(chan Event, 10),
        commands:     make(chan Command, 10),
    }
}

func (e *Engine) Run(ctx context.Context) error {
    e.running = true
    defer e.terminal.Close()
    
    // Start event collectors
    go e.collectInput()
    if e.config.HotReload {
        go e.watchFile()
    }
    
    // Initial render
    e.render()
    
    // Main event loop
    for e.running {
        select {
        case <-ctx.Done():
            return ctx.Err()
            
        case evt := <-e.events:
            e.handleEvent(evt)
            
        case cmd := <-e.commands:
            e.handleCommand(cmd)
        }
        
        if e.needsRender {
            e.render()
            e.needsRender = false
        }
    }
    
    return nil
}

func (e *Engine) collectInput() {
    for e.running {
        ev := e.terminal.Screen.PollEvent()
        
        switch event := ev.(type) {
        case *tcell.EventKey:
            e.events <- KeyEvent{
                Key:  event.Key(),
                Rune: event.Rune(),
                Mod:  event.Modifiers(),
            }
            
        case *tcell.EventResize:
            w, h := event.Size()
            e.events <- ResizeEvent{Width: w, Height: h}
        }
    }
}

func (e *Engine) handleEvent(evt Event) {
    switch e := evt.(type) {
    case KeyEvent:
        e.handleKey(e)
    case ResizeEvent:
        e.terminal.Size = image.Point{X: e.Width, Y: e.Height}
        e.needsRender = true
    case FileChangeEvent:
        e.reloadPresentation()
    }
}

func (e *Engine) handleKey(evt KeyEvent) {
    // Map key to action using config
    action := e.config.Bindings.Lookup(evt)
    
    switch action {
    case ActionNext:
        e.commands <- NavigateCommand{Direction: DirNext}
    case ActionPrevious:
        e.commands <- NavigateCommand{Direction: DirPrevious}
    case ActionFirst:
        e.commands <- NavigateCommand{Direction: DirFirst}
    case ActionLast:
        e.commands <- NavigateCommand{Direction: DirLast}
    case ActionExecute:
        e.executeCurrentSnippet()
    case ActionToggleIndex:
        e.presentation.ShowIndex = !e.presentation.ShowIndex
        e.needsRender = true
    case ActionToggleHelp:
        e.presentation.ShowHelp = !e.presentation.ShowHelp
        e.needsRender = true
    case ActionExit:
        e.running = false
    }
}

func (e *Engine) render() {
    e.terminal.Clear()
    
    // Get current slide
    slide := e.presentation.Slides[e.presentation.CurrentSlide]
    
    // Build widget tree
    root := e.buildWidgetTree(slide)
    
    // Compute layout
    layout := e.renderer.Layout(root)
    
    // Render
    e.renderer.Render(layout)
    
    e.terminal.Present()
}

func (e *Engine) buildWidgetTree(slide Slide) widgets.Widget {
    // Create slide container
    slideWidget := widgets.NewSlide()
    
    // Add content widgets
    for _, elem := range slide.Content {
        w := e.elementToWidget(elem)
        slideWidget.AddChild(w)
    }
    
    // Add footer if enabled
    if e.presentation.Theme.Footer.Type != "empty" {
        footer := e.buildFooter()
        slideWidget.SetFooter(footer)
    }
    
    return slideWidget
}
```

---

## Data Flow

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Markdown   │───▶│   Parser    │───▶│   Layout    │───▶│   Render    │
│   Source    │    │             │    │   Engine    │    │   Terminal  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                          │                                    │
                          ▼                                    ▼
                   ┌─────────────┐                      ┌─────────────┐
                   │Presentation │                      │   Output    │
                   │    Model    │                      │   Buffer    │
                   └─────────────┘                      └─────────────┘
```

### Rendering Pipeline

```go
// 1. Parse Phase
source → []byte
       ↓
frontMatter → FrontMatter
       ↓
slideSplit → [][]byte
       ↓
for each slide:
    markdown → goldmark.AST
       ↓
    AST → []Element
       ↓
    commands → Layout/Pause/etc
       ↓
Presentation{Slides: []Slide}

// 2. Layout Phase
Presentation.Slides[i]
       ↓
LayoutEngine.Compute()
       ↓
LayoutNode tree with absolute positions

// 3. Render Phase
LayoutNode
       ↓
Theme.Apply()
       ↓
Terminal.DrawText/DrawImage
       ↓
Screen.Show()
```

---

## External Dependencies

### Go Module Requirements

```go
// go.mod

module github.com/user/gopresenterm

go 1.23

require (
    // Terminal handling
    github.com/gdamore/tcell/v2 v2.7.0
    
    // Markdown parsing
    github.com/yuin/goldmark v1.6.0
    
    // Syntax highlighting
    github.com/alecthomas/chroma/v2 v2.12.0
    
    // YAML parsing
    gopkg.in/yaml.v3 v3.0.1
    
    // File watching
    github.com/fsnotify/fsnotify v1.7.0
    
    // Image processing
    github.com/disintegration/imaging v1.6.2
    
    // CLI
    github.com/spf13/cobra v1.8.0
    
    // Config management
    github.com/knadh/koanf/parsers/yaml v0.1.0
    github.com/knadh/koanf/providers/file v0.1.0
    github.com/knadh/koanf/v2 v2.0.1
    
    // Embedded files
    // (uses go:embed from stdlib)
    
    // Testing
    github.com/stretchr/testify v1.8.4
)
```

### Optional External Tools

| Feature | Tool | Installation |
|---------|------|--------------|
| PDF export | Chrome/Chromium | System package |
| Mermaid | `mmdc` (mermaid-cli) | `npm install -g @mermaid-js/mermaid-cli` |
| D2 | `d2` | `go install oss.terrastruct.com/d2@latest` |
| LaTeX | `pdflatex`, `dvipng` | TeX Live |
| Typst | `typst` | `cargo install typst-cli` |
| Rust-script | `rust-script` | `cargo install rust-script` |

---

## Phase-by-Phase Implementation Plan

### Phase 1: Foundation (MVP)

**Goal:** Basic slide navigation with text rendering

**Deliverables:**
- [ ] Project structure
- [ ] Terminal abstraction with tcell
- [ ] Markdown parser (goldmark)
- [ ] Basic slide model
- [ ] Text rendering with wrapping
- [ ] Simple navigation (next/prev)
- [ ] Hardcoded theme

**Timeline:** 1-2 weeks

---

### Phase 2: Core Features

**Goal:** Presentable basic tool

**Deliverables:**
- [ ] YAML front matter parsing
- [ ] Theme system with YAML config
- [ ] Code syntax highlighting (chroma)
- [ ] Headings and lists
- [ ] Block quotes and tables
- [ ] Basic footer support
- [ ] Slide index modal
- [ ] Help modal
- [ ] Configuration file support

**Timeline:** 2-3 weeks

---

### Phase 3: Advanced Markdown

**Goal:** Full markdown support

**Deliverables:**
- [ ] Column layouts
- [ ] Pause/incremental reveals
- [ ] Incremental lists
- [ ] HTML comment commands
- [ ] Font sizes (kitty)
- [ ] Speaker notes
- [ ] Hot reload (fsnotify)

**Timeline:** 2 weeks

---

### Phase 4: Images & Media

**Goal:** Visual content support

**Deliverables:**
- [ ] Kitty graphics protocol
- [ ] iTerm2 image protocol
- [ ] Sixel support
- [ ] ASCII fallback
- [ ] Image sizing options
- [ ] Animated GIF support
- [ ] Footer images

**Timeline:** 2-3 weeks

---

### Phase 5: Code Execution

**Goal:** Interactive code demos

**Deliverables:**
- [ ] Code execution framework
- [ ] Sandboxed execution
- [ ] PTY support for interactive programs
- [ ] Output capture and display
- [ ] Snippet output placement
- [ ] Language runners (bash, python, rust, go, etc.)
- [ ] Alternative executor support (rust-script, pytest, uv)

**Timeline:** 2-3 weeks

---

### Phase 6: Diagrams & Math

**Goal:** Rich content rendering

**Deliverables:**
- [ ] Mermaid diagram integration
- [ ] D2 diagram integration
- [ ] LaTeX formula rendering
- [ ] Typst formula rendering
- [ ] Cache rendered images

**Timeline:** 2 weeks

---

### Phase 7: Polish Features

**Goal:** Professional tool

**Deliverables:**
- [ ] Slide transitions (fade, slide, collapse)
- [ ] Export to PDF (chromedp)
- [ ] Export to HTML
- [ ] Window overflow validation
- [ ] Custom key bindings
- [ ] Visual grid toggle
- [ ] Comprehensive testing

**Timeline:** 2-3 weeks

---

### Phase 8: Distribution

**Goal:** Ready for users

**Deliverables:**
- [ ] Documentation
- [ ] Example presentations
- [ ] Homebrew formula
- [ ] AUR package
- [ ] Nix flake
- [ ] Scoop manifest
- [ ] CI/CD (GitHub Actions)

**Timeline:** 1 week

---

## Total Estimated Timeline

**Full implementation:** 14-19 weeks (~4-5 months) for a single developer working part-time.

**MVP usable tool:** 3-4 weeks.

---

## Design Decisions & Trade-offs

### 1. Terminal Library Choice: tcell vs alternatives

**tcell:**
- ✅ Mature, widely used
- ✅ Cross-platform
- ✅ Event handling
- ❌ Lower-level (more code needed)

**Alternative: bubbletea (Bubbles ecosystem)**
- ✅ Elm architecture (nice for state management)
- ✅ Lipgloss for styling
- ✅ Growing ecosystem
- ❌ Less control over low-level terminal

**Decision:** Use tcell for maximum control, especially for image protocols.

### 2. Markdown Parser: goldmark vs custom

**goldmark:**
- ✅ Fast, extensible
- ✅ CommonMark compliant
- ✅ Good AST
- ❌ May need workarounds for some features

**Decision:** goldmark with custom extensions for comment commands.

### 3. Image Protocol Priority

1. Try Kitty (best features)
2. Fall back to iTerm2 (macOS)
3. Fall back to Sixel (broad support)
4. ASCII art fallback

### 4. Code Execution Security

- Disabled by default
- Requires explicit `-x` or `-X` flag
- Configurable in config file
- Sandboxed where possible (containers, firejail - future)

---

## Testing Strategy

```go
// Unit tests for each package
// Integration tests for full presentations
// Golden file testing for render output

func TestSlideRendering(t *testing.T) {
    tests := []struct {
        name     string
        markdown string
        expected string // golden file
    }{
        {
            name: "simple slide",
            markdown: "# Title\n\nContent\n",
            expected: "testdata/simple_slide.golden",
        },
        // ...
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // Parse
            // Render to buffer
            // Compare with golden
        })
    }
}
```

---

## Future Considerations

1. **Plugin system** for custom renderers/executors
2. **Remote presentation** mode (SSH, web)
3. **Collaborative editing** (CRDT-based)
4. **VS Code extension** for live preview
5. **Mobile companion app** for remote control
6. **AI-assisted** slide generation
7. **Video export** (asciinema integration)

---

*Design document for Go clean-room reimplementation of presenterm*
*This is a theoretical architecture for educational/development purposes*
