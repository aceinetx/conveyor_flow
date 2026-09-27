const Vector2i = @import("Vector2i.zig");

pub const Direction = enum(u8) {
    up,
    down,
    left,
    right,

    pub fn toVector2i(self: @This()) Vector2i {
        return switch (self) {
            .up => .init(0, -1),
            .down => .init(0, 1),
            .left => .init(-1, 0),
            .right => .init(1, 0),
        };
    }

    pub fn isVertical(self: @This()) bool {
        return switch (self) {
            .up => true,
            .down => true,
            .left => false,
            .right => false,
        };
    }
};
