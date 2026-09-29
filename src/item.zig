const Textures = @import("Textures.zig");
const Vector2i = @import("Vector2i.zig");
const util = @import("util.zig");
const rl = @import("raylib");
const std = @import("std");

pub const ItemType = enum(u8) {
    stone,
};

pub const ItemKind = union(ItemType) {
    stone,
};

pub const Item = struct {
    const Self = @This();

    count: u8 = 1,

    kind: ItemKind,

    pub fn serialize(self: Self, writer: *std.Io.Writer) !void {
        try writer.writeInt(u8, self.count, .little);
        try writer.writeInt(u8, @intFromEnum(self.kind), .little);
    }

    pub fn deserialize(reader: *std.Io.Reader) !Self {
        var self: Self = undefined;
        self.count = try reader.takeInt(u8, .little);
        self.kind = util.unionFromTag(ItemKind, ItemType, try reader.takeInt(u8, .little));
        return self;
    }

    pub fn getRectangle(self: Self) rl.Rectangle {
        return util.createRectangleAroundPoint(self.position, 32);
    }

    pub fn draw(self: Self, position: rl.Vector2, textures: *Textures) void {
        switch (self.kind) {
            .stone => {
                rl.drawTexture(
                    textures.stone_item,
                    @intFromFloat(position.x - 16),
                    @intFromFloat(position.y - 16),
                    .white,
                );
            },
        }
    }
};