const std = @import("std");
const Slide = @import("Slide.zig").Slide;

pub const Metadata = struct {
    title: ?[]const u8,
    author: ?[]const u8,
    date: ?[]const u8,
    theme: ?[]const u8,

    pub fn deinit(self: Metadata, allocator: std.mem.Allocator) void {
        if (self.title) |t| allocator.free(t);
        if (self.author) |a| allocator.free(a);
        if (self.date) |d| allocator.free(d);
        if (self.theme) |th| allocator.free(th);
    }
};

pub const Presentation = struct {
    allocator: std.mem.Allocator,
    metadata: Metadata,
    slides: []Slide,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, metadata: Metadata, slides: []const Slide) !Self {
        const slides_copy = try allocator.alloc(Slide, slides.len);
        @memcpy(slides_copy, slides);
        return .{
            .allocator = allocator,
            .metadata = metadata,
            .slides = slides_copy,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.slides) |slide| {
            slide.deinit(self.allocator);
        }
        self.allocator.free(self.slides);
        self.metadata.deinit(self.allocator);
    }

    pub fn slideCount(self: Self) usize {
        return self.slides.len;
    }

    pub fn isEmpty(self: Self) bool {
        return self.slides.len == 0;
    }

    pub fn getSlide(self: Self, index: usize) ?Slide {
        if (index >= self.slides.len) return null;
        return self.slides[index];
    }

    pub fn validate(self: Self) ValidationError!void {
        if (self.isEmpty()) {
            return ValidationError.NoSlides;
        }
        for (self.slides) |slide| {
            try slide.validate();
        }
    }

    pub fn debugPrint(self: Self, writer: anytype) !void {
        try writer.print("Presentation: {d} slides\n", .{self.slideCount()});
        for (self.slides, 0..) |slide, i| {
            const title = slide.getTitle() orelse "Untitled";
            try writer.print("  Slide {d}: {s}\n", .{ i + 1, title });
        }
    }
};

pub const ValidationError = error{
    NoSlides,
    EmptySlide,
    InvalidHeadingLevel,
};

pub const Builder = struct {
    allocator: std.mem.Allocator,
    metadata: Metadata,
    slides: std.ArrayList(Slide),

    pub fn init(allocator: std.mem.Allocator) Builder {
        return .{
            .allocator = allocator,
            .metadata = .{
                .title = null,
                .author = null,
                .date = null,
                .theme = null,
            },
            .slides = .empty,
        };
    }

    pub fn deinit(self: *Builder) void {
        for (self.slides.items) |slide| {
            slide.deinit(self.allocator);
        }
        self.slides.deinit(self.allocator);
        self.metadata.deinit(self.allocator);
    }

    pub fn withTitle(self: *Builder, title: []const u8) !*Builder {
        self.metadata.title = try self.allocator.dupe(u8, title);
        return self;
    }

    pub fn withAuthor(self: *Builder, author: []const u8) !*Builder {
        self.metadata.author = try self.allocator.dupe(u8, author);
        return self;
    }

    pub fn withTheme(self: *Builder, theme: []const u8) !*Builder {
        self.metadata.theme = try self.allocator.dupe(u8, theme);
        return self;
    }

    pub fn addSlide(self: *Builder, slide: Slide) !*Builder {
        try self.slides.append(self.allocator, slide);
        return self;
    }

    pub fn build(self: *Builder) !Presentation {
        const presentation = Presentation{
            .allocator = self.allocator,
            .metadata = self.metadata,
            .slides = try self.slides.toOwnedSlice(self.allocator),
        };
        self.metadata = .{
            .title = null,
            .author = null,
            .date = null,
            .theme = null,
        };
        return presentation;
    }
};

// Tests
test "Presentation validation" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Empty presentation should fail validation
    const empty_pres = Presentation{
        .allocator = allocator,
        .metadata = .{ .title = null, .author = null, .date = null, .theme = null },
        .slides = &.{},
    };
    try testing.expectError(ValidationError.NoSlides, empty_pres.validate());
}

test "Metadata deinit" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var metadata = Metadata{
        .title = try allocator.dupe(u8, "Test"),
        .author = try allocator.dupe(u8, "Author"),
        .date = null,
        .theme = try allocator.dupe(u8, "dark"),
    };
    metadata.deinit(allocator);
}
