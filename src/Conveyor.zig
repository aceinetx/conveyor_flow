const util = @import("util.zig");
const config = @import("config.zig");
const std = @import("std");
const Vector2i = @import("Vector2i.zig");
const rl = @import("raylib");
const Item = @import("item.zig").Item;
const Tile = @import("tile.zig").Tile;
const Map = @import("Map.zig");
const Direction = @import("direction.zig").Direction;

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

pub fn tick(self: *Self, super: *Tile, map: *Map, position: Vector2i) void {
    _ = super;

    if (self.item) |item| {
        self.move_progress += 0.5 * config.one_tick_in_seconds;

        if (self.move_progress >= 1) {
            // Transfer the item
            const tile_pos = position.add(self.direction.toVector2i());
            if (map.tiles.getPtr(tile_pos)) |tile| {
                const differentMainAxis =
                    if (tile.* == .conveyor)
                        self.direction.isVertical() != tile.conveyor.direction.isVertical()
                    else
                        false;

                // Prevent jitter when moving between different axised conveyors
                // Snaps the element in place to the next conveyor
                if (differentMainAxis and self.move_progress < 1.5 and tile.conveyor.item == null)
                    return;

                if (tile.acceptItem(item)) {
                    self.item = null;

                    // Make it so that the element's main axis matches with the next conveyor
                    if (tile.* == .conveyor and differentMainAxis) {
                        tile.conveyor.move_progress = 0.5;
                    }
                }
            }

            self.move_progress = 1;
        }
    }
}
