const std = @import("std");

/// Token types for Markdown parsing
pub const Token = struct {
    type: Type,
    text: []const u8,
    line: usize,
    col: usize,

    pub const Type = enum {
        // Block tokens
        heading, // # ## ###
        paragraph,
        code_block,
        blockquote,
        list_item,
        thematic_break, // ---
        blank_line,

        // Inline tokens
        text,
        emphasis, // * or _
        strong, // ** or __
        code, // `code`
        link, // [text](url)
        image, // ![alt](url)
        line_break,

        // Special
        end_slide, // <!-- end_slide -->
        front_matter_marker, // ---
        eof,
        invalid,
    };
};
