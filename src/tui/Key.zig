//! Keyboard input types and key constants

/// Keyboard event
pub const Key = struct {
    codepoint: u21 = 0,
    mods: Modifiers = .{},
    text: ?[]const u8 = null,
    shifted_codepoint: ?u21 = null,
    base_layout_codepoint: ?u21 = null,

    /// Modifier key state
    pub const Modifiers = packed struct(u8) {
        shift: bool = false,
        alt: bool = false,
        ctrl: bool = false,
        super: bool = false,
        hyper: bool = false,
        meta: bool = false,
        caps_lock: bool = false,
        num_lock: bool = false,
    };

    // Special key codepoints (matching kitty keyboard protocol values)
    pub const tab: u21 = 0x09;
    pub const enter: u21 = 0x0D;
    pub const escape: u21 = 0x1B;
    pub const space: u21 = 0x20;
    pub const backspace: u21 = 0x7F;

    pub const insert: u21 = 57348;
    pub const delete: u21 = 57349;
    pub const left: u21 = 57350;
    pub const right: u21 = 57351;
    pub const up: u21 = 57352;
    pub const down: u21 = 57353;
    pub const page_up: u21 = 57354;
    pub const page_down: u21 = 57355;
    pub const home: u21 = 57356;
    pub const end: u21 = 57357;

    pub const f1: u21 = 57364;
    pub const f2: u21 = 57365;
    pub const f3: u21 = 57366;
    pub const f4: u21 = 57367;
    pub const f5: u21 = 57368;
    pub const f6: u21 = 57369;
    pub const f7: u21 = 57370;
    pub const f8: u21 = 57371;
    pub const f9: u21 = 57372;
    pub const f10: u21 = 57373;
    pub const f11: u21 = 57374;
    pub const f12: u21 = 57375;
};
