//! Lightweight root for integration tests — no test blocks.
//! Imports specific source files instead of submodule root.zig aggregators,
//! which contain test{} blocks that would cause the test runner to discover
//! all unit tests transitively.

pub const core = struct {
    pub const Presentation = @import("core/Presentation.zig").Presentation;
};

// parser/root.zig has no test block, so safe to import directly
pub const parser = @import("parser/root.zig");

pub const render = struct {
    pub const Theme = @import("render/Theme.zig");
};

pub const export_ = struct {
    pub const HtmlExporter = @import("export/HtmlExporter.zig").HtmlExporter;
    pub const RevealJsExporter = @import("export/RevealJsExporter.zig").RevealJsExporter;
    pub const RevealJsConfig = @import("export/RevealJsExporter.zig").RevealJsConfig;
    pub const BeamerExporter = @import("export/BeamerExporter.zig").BeamerExporter;
    pub const PdfExporter = @import("export/PdfExporter.zig").PdfExporter;
};

pub const test_utils = @import("test_utils.zig");
pub const version = "1.0.0";
