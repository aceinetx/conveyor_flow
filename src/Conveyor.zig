const Direction = @import("direction.zig").Direction;
const Item = @import("item.zig").Item;
const Tile = @import("tile.zig").Tile;
const Map = @import("Map.zig");
const Vector2i = @import("Vector2i.zig");
const util = @import("util.zig");
const std = @import("std");

const Self = @This();

direction: Direction,

item: ?Item = null,
move_progress: f32 = 0.0,

pub fn serialize(self: Self, writer: *std.Io.Writer) !void {
    try writer.writeInt(u8, @intFromEnum(self.direction), .little);
    try writer.writeByte(@intFromBool(self.item != null));
    if (self.item) |item| {
        try item.serialize(writer);
    }

    try writer.writeInt(u32, @bitCast(self.move_progress), .little);
}

pub fn deserialize(reader: *std.Io.Reader) !Self {
    var self: Self = undefined;

    self.direction = @enumFromInt(try reader.takeInt(u8, .little));
    if (try reader.takeByte() != 0) {
        self.item = try Item.deserialize(reader);
    }

    self.move_progress = @bitCast(try reader.takeInt(u32, .little));

    return self;
}