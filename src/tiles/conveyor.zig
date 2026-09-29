const util = @import("../util.zig");
const Textures = @import("../Textures.zig");
const config = @import("../config.zig");
const std = @import("std");
const Vector2i = @import("../Vector2i.zig");
const rl = @import("raylib");
const Item = @import("../item.zig").Item;
const Tile = @import("../tile.zig").Tile;
const Map = @import("../Map.zig");
const Direction = @import("../direction.zig").Direction;

pub const Conveyor = struct {
    const Self = @This();

    direction: Direction,
    move_progress: f32 = 0.0,
    speed: f32 = 1.0,

    item: ?Item = null,

    pub fn serialize(self: Self, writer: *std.Io.Writer) !void {
        try writer.writeInt(u8, @intFromEnum(self.direction), .little);
        try writer.writeInt(u32, @bitCast(self.move_progress), .little);
        try writer.writeInt(u32, @bitCast(self.speed), .little);

        try writer.writeByte(@intFromBool(self.item != null));
        if (self.item) |item| {
            try item.serialize(writer);
        }
    }

    pub fn deserialize(reader: *std.Io.Reader) !Self {
        var self: Self = undefined;

        self.direction = @enumFromInt(try reader.takeInt(u8, .little));
        self.move_progress = @bitCast(try reader.takeInt(u32, .little));
        self.speed = @bitCast(try reader.takeInt(u32, .little));

        if (try reader.takeByte() != 0) {
            self.item = try Item.deserialize(reader);
        }

        return self;
    }

    pub fn tick(self: *Self, super: *Tile, map: *Map, position: Vector2i) void {
        _ = super;

        if (self.item) |item| {
            self.move_progress += 0.5 / self.speed * config.one_tick_in_seconds;

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

    pub fn draw(self: Self, super: Tile, position: Vector2i, textures: *Textures) void {
        _ = super;

        const rec = Tile.getRectangle(position);

        const rotation: f32 = switch (self.direction) {
            .up => -90,
            .down => 90,
            .left => 180,
            .right => 0,
        };

        rl.drawTexturePro(
            textures.conveyor,
            .{
                .x = 0,
                .y = 0,
                .width = 32,
                .height = 32,
            },
            .{
                .x = rec.x + 16,
                .y = rec.y + 16,
                .width = rec.width,
                .height = rec.height,
            },
            .init(rec.width / 2, rec.height / 2),
            rotation,
            .white,
        );
    }

    pub fn drawPost(self: Self, super: Tile, position: Vector2i, textures: *Textures) void {
        _ = super;

        const rec = Tile.getRectangle(position);

        if (self.item) |item| {
            const pos: rl.Vector2 = switch (self.direction) {
                .up => .init(
                    rec.x + 16,
                    rec.y + (32.0 * (1.0 - self.move_progress)),
                ),
                .down => .init(
                    rec.x + 16,
                    rec.y + (32.0 * (self.move_progress)),
                ),
                .left => .init(
                    rec.x + (32.0 * (1.0 - self.move_progress)),
                    rec.y + 16,
                ),
                .right => .init(
                    rec.x + (32.0 * (self.move_progress)),
                    rec.y + 16,
                ),
            };

            item.draw(pos, textures);
        }
    }
};
