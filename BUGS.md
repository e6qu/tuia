# Bug Tracking

**Status:** Phase 16 — TUI testing bug sweep (complete)
**Open Bugs:** 0
**Total Fixed:** 57 (27 from Phase 1-12, 14 from Phase 13, 3 from Phase 14, 3 from Phase 15, 5 from Phase 15b, 5 from Phase 16)

---

## Open Bugs

None.

---

## Fixed in Phase 16 (TUI Testing Bug Sweep)

| Bug | Severity | Fix |
|-----|----------|-----|
| TUI-1 | HIGH | `Terminal.init` now checks `TUIA_TTY_FD` env var before opening `/dev/tty`, with `owned_fd` flag to guard close. Enables pty-based testing with `expect`. |
| TUI-2 | MEDIUM | `parseBlockquote` now exits on `.thematic_break`, preventing blockquotes from swallowing `---` slide separators |
| TUI-3 | MEDIUM | Resolved by TUI-2 fix — list items were appearing in wrong parsing context due to blockquote consuming slide separators |
| TUI-4 | LOW | Scanner heading token now consumes rest of line (like code blocks). `parseHeading` extracts text from token directly instead of calling `parseInlineText()` |
| TUI-5 | LOW | `HtmlExporter.writeHeader` now outputs `<meta name="author">` tag when author metadata is present |

## Previously Open Bugs (Phase 13 - Memory & Safety Audit)

### CRITICAL

#### CRIT-1: `getCurrentSlideIndex()` stub causes widget rebuild every frame (OOM)

**File:** `src/render/Renderer.zig:328-333`
**Type:** Unbounded allocation / Memory leak
**Impact:** Most likely cause of the OOM crash

`getCurrentSlideIndex()` always returns `0`. On any slide past the first, the condition at line 140-141 is always true, causing `setCurrentSlide()` to be called **every render frame**. Each call destroys and recreates the entire `SlideWidget` tree (heap allocs for all child widgets). This creates massive allocation churn and peak memory growth that will eventually OOM.

```zig
fn getCurrentSlideIndex(self: Self) usize {
    _ = self;
    return 0; // BUG: always triggers widget rebuild
}
```

**Fix:** Track the current slide index in Renderer state. Update it in `setCurrentSlide()`. Compare against the tracked index instead of this stub.

---

#### CRIT-2: `SlideWidget.deinit` double-frees shared slide data

**File:** `src/widgets/SlideWidget.zig:65` + `src/core/Presentation.zig:51-53`
**Type:** Double-free / Use-after-free

`Presentation.getSlide()` returns a `Slide` by value (a copy of the struct). The copy shares heap pointers (`elements`, etc.) with the original in `presentation.slides[]`. `SlideWidget.deinit()` calls `self.slide.deinit(self.allocator)` which frees those shared pointers. When the presentation is later freed or the same slide is accessed again, it's a double-free.

Combined with CRIT-1, this means every frame on slide 2+ frees the slide data, then the next frame accesses freed memory.

**Fix:** Either deep-clone the slide in `SlideWidget.init`, or borrow a pointer instead of taking ownership.

---

#### CRIT-3: `allocPrint` result leaked in `setMessage` calls

**File:** `src/App.zig:415, 426`
**Type:** Memory leak

`std.fmt.allocPrint` returns a heap-allocated string that is passed directly to `nav.setMessage()`. `setMessage` internally dupes the string, so the original allocation is never freed. Leaks memory every time the user presses `T` (toggle transitions) or `R` (remote error).

```zig
// Line 415 - leaks the allocPrint result
try nav.setMessage(self.allocator, try std.fmt.allocPrint(self.allocator, "Transitions {s}", .{status}), 60);
```

**Fix:** Capture the `allocPrint` result, `defer` free it, then pass to `setMessage`.

---

### HIGH

#### HIGH-1: `TextWidget.initThematicBreak` frees non-heap slice

**File:** `src/widgets/TextWidget.zig:67, 74-76`
**Type:** Invalid free / Undefined behavior

`initThematicBreak` sets `self.text = &.{}` (an empty slice literal — not heap-allocated). `deinit()` unconditionally calls `self.allocator.free(self.text)`. Freeing a non-heap pointer is UB and will likely panic under GPA.

**Fix:** Use `try allocator.alloc(u8, 0)` or skip the free when text is empty.

---

#### HIGH-2: `ImageLoader.loadFromFile` cache returns by value — double-free

**File:** `src/features/images/ImageLoader.zig:82-86`
**Type:** Double-free

When an image is found in cache, it's returned by value. The caller may call `image.deinit()` on it, freeing `image.data`. The cache still holds a reference to that same `data` pointer. When `ImageLoader.deinit()` iterates the cache and frees everything, it double-frees.

**Fix:** Return a pointer to the cached image (no caller ownership), or deep-clone on cache hit.

---

#### HIGH-3: CodeExecutor timeout kill logic is dead code

**File:** `src/features/executor/CodeExecutor.zig:176, 222`
**Type:** Logic bug / Zombie process

`exit_code` is `u32` initialized to `0`. The timeout kill check `if (exit_code == -1)` on line 222 can never be true for a `u32`. Timed-out child processes are never killed and become zombies.

**Fix:** Use `?u32` (optional) or a separate `exited: bool` flag.

---

#### HIGH-4: CodeExecutor pipe double-close on error path

**File:** `src/features/executor/CodeExecutor.zig:126-131, 166-167, 251-252`
**Type:** Resource leak / Double-close

The `errdefer` at lines 126-131 closes all 4 pipe FDs. After the parent closes write ends (lines 166-167), if an error occurs before lines 251-252, the `errdefer` fires and re-closes the already-closed write-end FDs. Double-closing can close an unrelated FD that reused the same number.

**Fix:** Set FDs to `-1` after closing, or restructure errdefer scopes.

---

### MEDIUM

#### MED-1: `ExecutionWidget.draw` frees string literal on error

**File:** `src/widgets/ExecutionWidget.zig:239-242`
**Type:** Invalid free

When `getStatusText()` fails, the catch block returns `"Error"` (a string literal). Line 242 then calls `self.allocator.free(status)` on it. Freeing a string literal is UB.

**Fix:** Don't free the fallback literal. Use a flag or optional to track whether `status` is heap-allocated.

---

#### MED-2: `convertBlockquoteContent` leaks `inlines` slice

**File:** `src/parser/Converter.zig:253-255`
**Type:** Memory leak

`convertInlines` returns a heap-allocated slice. Its elements are copied into `result` via `appendSlice`, but the outer slice itself is never freed. Compare with `convertListItemContent` (line 279) which correctly calls `allocator.free(inlines)`.

**Fix:** Add `allocator.free(inlines)` after the `appendSlice` call (same as `convertListItemContent`).

---

#### MED-3: CodeExecutor `waitpid` status check is wrong

**File:** `src/features/executor/CodeExecutor.zig:213-214`
**Type:** Logic bug

`waitpid` with `WNOHANG` returns `status == 0` both when the child exits with code 0 AND when the child hasn't exited yet. The code checks `if (wait_result.status != 0)` which fails to detect a child that exited successfully, and breaks the loop prematurely on the first iteration if the child hasn't exited (since `status == 0` means "keep going" but the code treats it as "not exited").

**Fix:** Check `wait_result.pid != 0` to determine if child exited. Use `W.EXITSTATUS()` to extract exit code.

---

#### MED-4: CodeExecutor timeout path doesn't drain remaining pipe data

**File:** `src/features/executor/CodeExecutor.zig:216-220`
**Type:** Data loss

When the child exits in the timeout path, the loop breaks immediately. Unread data still buffered in the pipes is lost. The no-timeout path (line 237-248) correctly drains remaining data.

**Fix:** After the child exits in the timeout path, drain both pipes before closing them.

---

#### MED-5: CodeExecutor heap-allocates read buffer every poll iteration

**File:** `src/features/executor/CodeExecutor.zig:194-195, 203-204`
**Type:** Performance / Unnecessary allocation

Inside the poll loop, `try self.allocator.alloc(u8, 4096)` is called every iteration with data. The no-timeout path (line 238) correctly uses a stack buffer `var buf: [4096]u8 = undefined`.

**Fix:** Use a stack buffer declared before the loop.

---

### LOW

#### LOW-1: `RevealJsExporter` doesn't HTML-escape URLs

**File:** `src/export/RevealJsExporter.zig` (image and link URL output)
**Type:** XSS / Injection

Image URLs and link URLs are written without HTML escaping. A URL containing `"` could break out of an HTML attribute.

**Fix:** Use `writeEscapedHtml` for URL attributes.

---

#### LOW-2: `BeamerExporter` doesn't LaTeX-escape URLs

**File:** `src/export/BeamerExporter.zig` (link URL output)
**Type:** Injection

Link URLs are written directly into LaTeX `\href{}`. URLs containing `#`, `%`, `&` produce invalid LaTeX.

**Fix:** Escape special LaTeX characters in URLs.

---

#### LOW-3: `Sandbox.createTempDir` uses CWD instead of `/tmp`

**File:** `src/features/executor/Sandbox.zig` (on `feature/tui-testing` branch)
**Type:** Resource leak / Cleanup issue

Temp directories are created in the current working directory. If `deinit` is never called (crash), `.tuia_sandbox_*` dirs accumulate in the user's project.

**Fix:** Use `/tmp` or `std.fs.tmpDir()`.

---

#### LOW-4: `parseStrong`/`parseEmphasis` don't unescape text before bold/italic

**File:** `src/parser/Parser.zig:731, 770`
**Type:** Inconsistency

Text flushed before bold/italic markers uses `allocator.dupe` instead of `unescapeText`. Escape sequences like `\*` in text before a bold marker aren't unescaped.

**Fix:** Use `unescapeText` instead of `allocator.dupe`.

---

## Fixed in Phase 13

| Bug | Severity | Fix |
|-----|----------|-----|
| CRIT-1 | CRITICAL | `Renderer.getCurrentSlideIndex()` now tracks real index instead of returning 0 |
| CRIT-2 | CRITICAL | `SlideWidget.deinit` no longer frees borrowed slide data (Presentation owns it) |
| CRIT-3 | CRITICAL | `App.zig` `allocPrint` results now freed after `setMessage` |
| HIGH-1 | HIGH | `TextWidget.initThematicBreak` uses heap-allocated empty slice instead of `&.{}` |
| HIGH-2 | HIGH | `ImageLoader.loadFromFile` returns `*const Image` (borrowed pointer) from cache |
| HIGH-3 | HIGH | CodeExecutor timeout uses `child_exited` flag instead of broken `u32 == -1` check |
| HIGH-4 | HIGH | CodeExecutor pipe FDs use `defer close` instead of fragile `errdefer` |
| MED-1 | MEDIUM | `ExecutionWidget.draw` no longer frees string literal on error path |
| MED-2 | MEDIUM | `convertBlockquoteContent` now frees `inlines` slice after `appendSlice` |
| MED-3 | MEDIUM | CodeExecutor uses `wait_result.pid != 0` instead of `status != 0` |
| MED-4 | MEDIUM | CodeExecutor timeout path now drains remaining pipe data after child exits |
| MED-5 | MEDIUM | CodeExecutor uses stack buffer instead of heap-alloc per poll iteration |
| COMPILE-1 | HIGH | Removed 13 `refAllDecls` calls causing exponential compiler memory usage |
| COMPILE-2 | HIGH | Fixed `Converter.zig` test accessing nonexistent `.heading.text` field |
| COMPILE-3 | MEDIUM | Fixed `Sandbox.zig` test passing wrong type to `checkCode` |
| API-1 | LOW | `Slide.getCodeBlocks` updated to new ArrayList API |

## Remaining Open Bugs

None — all bugs resolved.

## Fixed in Phase 15b (TUI Testing Bugs)

| Bug | Severity | Fix |
|-----|----------|-----|
| RENDER-1 | HIGH | `renderStatusBar` integer overflow when `win.height == 0` — added `if (win.height < 2) return` guard |
| RENDER-2 | HIGH | `render()` crashes on zero-size window — added `if (win.width == 0 or win.height == 0) return` guard |
| APP-1 | HIGH | `App.render` integer overflow: `win.height - 2` when height < 2 — added bounds check |
| PARSE-1 | CRITICAL | Infinite loop in `parseInlineContent`: 8 inline parsers failed to update `text_start` when flushing pending text, causing 40MB/s memory growth |
| PARSE-2 | HIGH | `parseFrontMatter` used byte offset as token count, over-skipping scanner past all content. Fixed by setting scanner position directly. |

## Fixed in Phase 15 (Final Bug Sweep)

| Bug | Severity | Fix |
|-----|----------|-----|
| COMPILE-4 | HIGH | Integration tests now use `src/root_integ.zig` (no `test{}` block) instead of `src/root.zig`, avoiding transitive unit test re-discovery. Also fixed infinite loop in `parseInlineContent` — 8 inline parsers failed to update `text_start` when flushing pending text, causing unbounded re-flushing of the same text (40MB/s memory growth). |
| LOW-1 | LOW | `RevealJsExporter` now HTML-escapes URLs in all image `src`, audio/video `src`, link `href`, and inline image `src` attributes |
| LOW-2 | LOW | `BeamerExporter` now LaTeX-escapes URLs in `\includegraphics{}`, `\href{}`, and inline `\includegraphics{}` |

## Fixed in Phase 14 (Fixed-Memory TUI Layer)

| Bug | Severity | Fix |
|-----|----------|-----|
| ALLOC-1 | HIGH | Terminal.zig: replaced per-frame `ArrayList(u8)` and per-resize `alloc/free` with single init-time allocation (2×32K cells ≈ 3MB) + fixed 64KB render buffer. Zero runtime allocations. |
| ALLOC-2 | MEDIUM | Renderer.zig: replaced `allocPrint` in `renderStatusBar()` and `renderDebug()` with stack `bufPrint` (64B + 256B + 32B). Zero runtime allocations in render path. |
| LATENT-1 | MEDIUM | Renderer.zig: `renderDebug()` referenced non-existent `.underline` field on Style struct (should be `.ul_style = .single`). Dead code — never called — but would fail to compile if used. |

## Previously Fixed (Phase 1-12)

**Total Fixed:** 27 (17 Critical, 6 High, 4 Medium/Low)

| Bug | Component | Fix |
|-----|-----------|-----|
| LOW-1 | Parser | Hard line breaks (`<br>`, two spaces) |
| LOW-2 | Parser | Escape sequence processing |
| LOW-3 | Scanner | Horizontal rules (`***`, `___`) |
| MED-2 | Remote | HTTP Keep-Alive with posix.shutdown |
| *(Phase 1-9)* | Various | 17 critical bugs (use-after-free, buffer overflows, integer underflows, etc.) |
| *(Phase 10-11)* | Various | 6 additional high-severity bugs |

---

*Last updated: 2026-03-18 (Phase 16 - TUI testing bug sweep complete, all 57 bugs fixed)*
