//! Converts parser AST types to core types
const std = @import("std");
const AST = @import("AST.zig");
const core = @import("../core/root.zig");
const ElementMod = @import("../core/Element.zig");
const Presentation = @import("../core/Presentation.zig");

/// Convert AST Inline to core Inline
fn convertInline(allocator: std.mem.Allocator, ast_inline: AST.Inline, link_refs: *const std.StringHashMap([]const u8)) std.mem.Allocator.Error!ElementMod.Inline {
    return switch (ast_inline) {
        .text => |t| .{ .text = try allocator.dupe(u8, t) },
        .code => |c| .{ .code = try allocator.dupe(u8, c) },
        .emphasis => |e| {
            const inner = try convertInlines(allocator, e, link_refs);
            return .{ .italic = inner };
        },
        .strong => |s| {
            const inner = try convertInlines(allocator, s, link_refs);
            return .{ .bold = inner };
        },
        .link => |l| {
            // Resolve reference-style links
            var url = l.url;
            if (l.ref_label) |label| {
                if (link_refs.get(label)) |resolved_url| {
                    url = resolved_url;
                }
            }

            const content = try convertInlines(allocator, l.text, link_refs);
            errdefer allocator.free(content);

            return .{ .link = .{
                .content = content,
                .url = try allocator.dupe(u8, url),
            } };
        },
        .image => |img| {
            return .{ .image = .{
                .alt = try allocator.dupe(u8, img.alt),
                .url = try allocator.dupe(u8, img.url),
            } };
        },
        .line_break => .{ .text = try allocator.dupe(u8, " ") }, // Convert line break to space
    };
}

/// Convert multiple AST Inlines to core Inlines
fn convertInlines(allocator: std.mem.Allocator, ast_inlines: []const AST.Inline, link_refs: *const std.StringHashMap([]const u8)) std.mem.Allocator.Error![]ElementMod.Inline {
    var result = try allocator.alloc(ElementMod.Inline, ast_inlines.len);
    errdefer {
        for (result) |*item| item.deinit(allocator);
        allocator.free(result);
    }

    for (ast_inlines, 0..) |item, i| {
        result[i] = try convertInline(allocator, item, link_refs);
    }

    return result;
}

/// Convert AST Presentation to core Presentation
pub fn convertPresentation(allocator: std.mem.Allocator, ast_pres: AST.Presentation) !core.Presentation {
    // Store link references for use during conversion
    const link_refs = &ast_pres.link_references;

    // Convert metadata
    const metadata = if (ast_pres.metadata) |ast_fm|
        Presentation.Metadata{
            .title = if (ast_fm.title) |t| try allocator.dupe(u8, t) else null,
            .author = if (ast_fm.author) |a| try allocator.dupe(u8, a) else null,
            .date = if (ast_fm.date) |d| try allocator.dupe(u8, d) else null,
            .theme = if (ast_fm.theme) |th| try allocator.dupe(u8, th) else null,
        }
    else
        Presentation.Metadata{
            .title = null,
            .author = null,
            .date = null,
            .theme = null,
        };

    // Convert slides
    var slides = try allocator.alloc(core.Slide, ast_pres.slides.len);
    errdefer {
        for (slides) |*slide| {
            slide.deinit(allocator);
        }
        allocator.free(slides);
    }

    for (ast_pres.slides, 0..) |ast_slide, i| {
        slides[i] = try convertSlide(allocator, ast_slide, link_refs);
    }

    return core.Presentation{
        .allocator = allocator,
        .metadata = metadata,
        .slides = slides,
    };
}

/// Convert AST Slide to core Slide
fn convertSlide(allocator: std.mem.Allocator, ast_slide: AST.Slide, link_refs: *const std.StringHashMap([]const u8)) !core.Slide {
    var elements = try allocator.alloc(core.Element, ast_slide.elements.len);
    errdefer {
        for (elements) |*elem| {
            elem.deinit(allocator);
        }
        allocator.free(elements);
    }

    for (ast_slide.elements, 0..) |ast_elem, i| {
        elements[i] = try convertElement(allocator, ast_elem, link_refs);
    }

    // Convert speaker notes
    const speaker_notes = if (ast_slide.speaker_notes) |notes|
        try allocator.dupe(u8, notes)
    else
        null;
    errdefer if (speaker_notes) |sn| allocator.free(sn);

    return core.Slide{
        .elements = elements,
        .speaker_notes = speaker_notes,
    };
}

/// Convert AST Element to core Element
fn convertElement(allocator: std.mem.Allocator, ast_elem: AST.Element, link_refs: *const std.StringHashMap([]const u8)) !core.Element {
    return switch (ast_elem) {
        .heading => |h| .{
            .heading = .{
                .level = h.level,
                .content = try convertInlines(allocator, h.content, link_refs),
            },
        },
        .paragraph => |p| .{
            .paragraph = .{
                .content = try convertInlines(allocator, p.content, link_refs),
            },
        },
        .code_block => |cb| .{
            .code_block = .{
                .language = if (cb.language) |l| try allocator.dupe(u8, l) else null,
                .code = try allocator.dupe(u8, cb.code),
            },
        },
        .list => |l| .{
            .list = .{
                .ordered = l.ordered,
                .items = try convertListItems(allocator, l.items, link_refs),
            },
        },
        .blockquote => |bq| .{
            .blockquote = .{
                .content = try convertBlockquoteContent(allocator, bq, link_refs),
            },
        },
        .table => |t| .{
            .table = try convertTable(allocator, t, link_refs),
        },
        .thematic_break => .thematic_break,
    };
}

/// Convert inline elements to plain text (with link reference resolution)
fn inlineToTextWithLinks(allocator: std.mem.Allocator, inlines: []AST.Inline, link_refs: *const std.StringHashMap([]const u8)) ![]const u8 {
    // Simple implementation - just concatenate all text
    var result: std.ArrayList(u8) = .empty;
    defer result.deinit(allocator);

    for (inlines) |inline_elem| {
        switch (inline_elem) {
            .text => |t| try result.appendSlice(allocator, t),
            .code => |c| {
                try result.append(allocator, '`');
                try result.appendSlice(allocator, c);
                try result.append(allocator, '`');
            },
            .emphasis => |e| {
                try result.append(allocator, '*');
                const text = try inlineToTextWithLinks(allocator, e, link_refs);
                defer allocator.free(text);
                try result.appendSlice(allocator, text);
                try result.append(allocator, '*');
            },
            .strong => |s| {
                try result.appendSlice(allocator, "**");
                const text = try inlineToTextWithLinks(allocator, s, link_refs);
                defer allocator.free(text);
                try result.appendSlice(allocator, text);
                try result.appendSlice(allocator, "**");
            },
            .link => |l| {
                // Resolve reference-style links
                if (l.ref_label) |label| {
                    if (link_refs.get(label)) |url| {
                        try result.appendSlice(allocator, url);
                    } else {
                        // Reference not found, just show the text
                        const text = try inlineToTextWithLinks(allocator, l.text, link_refs);
                        defer allocator.free(text);
                        try result.appendSlice(allocator, text);
                    }
                } else {
                    try result.appendSlice(allocator, l.url);
                }
            },
            .image => |img| {
                try result.appendSlice(allocator, img.alt);
            },
            .line_break => try result.append(allocator, '\n'),
        }
    }

    return result.toOwnedSlice(allocator);
}

/// Convert blockquote to text (with link resolution)
fn blockquoteToTextWithLinks(allocator: std.mem.Allocator, bq: AST.Blockquote, link_refs: *const std.StringHashMap([]const u8)) ![]const u8 {
    // For simplicity, convert all elements to text
    var result: std.ArrayList(u8) = .empty;
    defer result.deinit(allocator);

    for (bq.content) |elem| {
        const text = switch (elem) {
            .paragraph => |p| try inlineToTextWithLinks(allocator, p.content, link_refs),
            else => try std.fmt.allocPrint(allocator, "[{s}]", .{@tagName(elem)}),
        };
        defer allocator.free(text);
        try result.appendSlice(allocator, text);
        try result.append(allocator, ' ');
    }

    return result.toOwnedSlice(allocator);
}

/// Convert blockquote content - concatenate all paragraph content
fn convertBlockquoteContent(allocator: std.mem.Allocator, bq: AST.Blockquote, link_refs: *const std.StringHashMap([]const u8)) ![]ElementMod.Inline {
    // For simplicity, collect all inline content from paragraphs
    var result: std.ArrayList(ElementMod.Inline) = .empty;
    errdefer {
        for (result.items) |*item| item.deinit(allocator);
        result.deinit(allocator);
    }

    for (bq.content) |elem| {
        switch (elem) {
            .paragraph => |p| {
                const inlines = try convertInlines(allocator, p.content, link_refs);
                errdefer allocator.free(inlines);
                try result.appendSlice(allocator, inlines);
                // Add space between paragraphs
                try result.append(allocator, .{ .text = try allocator.dupe(u8, " ") });
            },
            else => {},
        }
    }

    return try result.toOwnedSlice(allocator);
}

/// Convert list item content
fn convertListItemContent(allocator: std.mem.Allocator, elements: []const AST.Element, link_refs: *const std.StringHashMap([]const u8)) ![]ElementMod.Inline {
    var result: std.ArrayList(ElementMod.Inline) = .empty;
    errdefer {
        for (result.items) |*item| item.deinit(allocator);
        result.deinit(allocator);
    }

    for (elements) |elem| {
        switch (elem) {
            .paragraph => |p| {
                const inlines = try convertInlines(allocator, p.content, link_refs);
                errdefer allocator.free(inlines);
                try result.appendSlice(allocator, inlines);
                try result.append(allocator, .{ .text = try allocator.dupe(u8, " ") });
            },
            .heading => |h| {
                const inlines = try convertInlines(allocator, h.content, link_refs);
                errdefer allocator.free(inlines);
                try result.appendSlice(allocator, inlines);
                try result.append(allocator, .{ .text = try allocator.dupe(u8, " ") });
            },
            else => {},
        }
    }

    return try result.toOwnedSlice(allocator);
}

/// Convert list items
fn convertListItems(allocator: std.mem.Allocator, items: []AST.ListItem, link_refs: *const std.StringHashMap([]const u8)) ![]core.ListItem {
    var result = try allocator.alloc(core.ListItem, items.len);
    errdefer allocator.free(result);

    for (items, 0..) |item, i| {
        // Convert nested list if present
        var children: ?*ElementMod.List = null;
        if (item.children) |child_list| {
            children = try allocator.create(ElementMod.List);
            errdefer allocator.destroy(children.?);
            children.?.* = .{
                .ordered = child_list.ordered,
                .items = try convertListItems(allocator, child_list.items, link_refs),
            };
        }

        result[i] = .{
            .content = try convertListItemContent(allocator, item.content, link_refs),
            .children = children,
        };
    }

    return result;
}

/// Convert AST Table to core Table
fn convertTable(allocator: std.mem.Allocator, ast_table: AST.Table, link_refs: *const std.StringHashMap([]const u8)) !ElementMod.Table {
    // Convert headers (now as TableCell with content)
    var headers = try allocator.alloc(ElementMod.Table.TableCell, ast_table.headers.len);
    errdefer allocator.free(headers);
    for (ast_table.headers, 0..) |header, i| {
        // Parse header text as inline content (create simple text inline)
        var content = try allocator.alloc(ElementMod.Inline, 1);
        errdefer allocator.free(content);
        content[0] = .{ .text = try allocator.dupe(u8, header) };
        headers[i] = .{ .content = content };
    }

    // Convert alignments
    var alignments = try allocator.alloc(ElementMod.Table.Alignment, ast_table.alignments.len);
    errdefer allocator.free(alignments);
    for (ast_table.alignments, 0..) |a, i| {
        alignments[i] = switch (a) {
            .left => .left,
            .center => .center,
            .right => .right,
            .default => .default,
        };
    }

    // Convert rows
    var rows = try allocator.alloc([]ElementMod.Table.TableCell, ast_table.rows.len);
    errdefer {
        for (rows) |row| {
            for (row) |cell| {
                cell.deinit(allocator);
            }
            allocator.free(row);
        }
        allocator.free(rows);
    }

    for (ast_table.rows, 0..) |ast_row, i| {
        var cells = try allocator.alloc(ElementMod.Table.TableCell, ast_row.len);
        errdefer allocator.free(cells);

        for (ast_row, 0..) |ast_cell, j| {
            cells[j] = .{
                .content = try convertInlines(allocator, ast_cell.content, link_refs),
            };
        }

        rows[i] = cells;
    }

    return .{
        .headers = headers,
        .alignments = alignments,
        .rows = rows,
    };
}

// ============================================================================
// Tests
// ============================================================================

test "convert simple presentation" {
    const allocator = std.testing.allocator;

    // Create a simple AST presentation
    var slides = try allocator.alloc(AST.Slide, 1);
    defer allocator.free(slides);

    var elements = try allocator.alloc(AST.Element, 2);
    defer allocator.free(elements);

    // Heading
    var heading_inlines = try allocator.alloc(AST.Inline, 1);
    defer allocator.free(heading_inlines);
    heading_inlines[0] = .{ .text = try allocator.dupe(u8, "Test Slide") };

    elements[0] = .{ .heading = .{ .level = 1, .content = heading_inlines } };

    // Paragraph
    var para_inlines = try allocator.alloc(AST.Inline, 1);
    defer allocator.free(para_inlines);
    para_inlines[0] = .{ .text = try allocator.dupe(u8, "This is a test paragraph.") };

    elements[1] = .{ .paragraph = .{ .content = para_inlines } };

    slides[0] = .{ .elements = elements };

    const ast_pres: AST.Presentation = .{
        .allocator = allocator,
        .metadata = null,
        .slides = slides,
    };

    // Convert to core presentation
    const core_pres = try convertPresentation(allocator, ast_pres);
    defer core_pres.deinit();

    // Verify
    try std.testing.expectEqual(@as(usize, 1), core_pres.slides.len);
    try std.testing.expectEqual(@as(usize, 2), core_pres.slides[0].elements.len);
    try std.testing.expectEqualStrings("Test Slide", core_pres.slides[0].elements[0].heading.text);
    try std.testing.expectEqualStrings("This is a test paragraph.", core_pres.slides[0].elements[1].paragraph.text);
}

test "convert presentation with metadata" {
    const allocator = std.testing.allocator;

    // Create AST presentation with metadata
    const fm = try allocator.create(AST.FrontMatter);
    defer allocator.destroy(fm);
    fm.* = .{
        .title = try allocator.dupe(u8, "My Presentation"),
        .author = try allocator.dupe(u8, "Test Author"),
        .date = try allocator.dupe(u8, "2026-03-02"),
        .theme = try allocator.dupe(u8, "dark"),
    };

    const ast_pres: AST.Presentation = .{
        .allocator = allocator,
        .metadata = fm,
        .slides = &.{},
    };

    // Convert to core presentation
    const core_pres = try convertPresentation(allocator, ast_pres);
    defer core_pres.deinit();

    // Verify metadata
    try std.testing.expectEqualStrings("My Presentation", core_pres.metadata.title.?);
    try std.testing.expectEqualStrings("Test Author", core_pres.metadata.author.?);
    try std.testing.expectEqualStrings("2026-03-02", core_pres.metadata.date.?);
    try std.testing.expectEqualStrings("dark", core_pres.metadata.theme.?);
}

test "convert code block" {
    const allocator = std.testing.allocator;

    // Create a slide with a code block
    var elements = try allocator.alloc(AST.Element, 1);
    defer allocator.free(elements);

    elements[0] = .{ .code_block = .{
        .language = try allocator.dupe(u8, "zig"),
        .code = try allocator.dupe(u8, "const x = 42;"),
    } };

    var slides = try allocator.alloc(AST.Slide, 1);
    defer allocator.free(slides);
    slides[0] = .{ .elements = elements };

    const ast_pres: AST.Presentation = .{
        .allocator = allocator,
        .metadata = null,
        .slides = slides,
    };

    // Convert
    const core_pres = try convertPresentation(allocator, ast_pres);
    defer core_pres.deinit();

    // Verify
    try std.testing.expectEqualStrings("zig", core_pres.slides[0].elements[0].code_block.language.?);
    try std.testing.expectEqualStrings("const x = 42;", core_pres.slides[0].elements[0].code_block.code);
}
