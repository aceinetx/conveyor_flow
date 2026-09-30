const Direction = @import("../direction.zig").Direction;
const Item = @import("../item.zig").Item;
const Tile = @import("../tile.zig").Tile;
const Map = @import("../Map.zig");
const Textures = @import("../Textures.zig");
const Vector2i = @import("../Vector2i.zig");
const rl = @import("raylib");
const std = @import("std");

pub const Distributor = struct {
    const Self = @This();

    input_direction: Direction = .down,
    distribution_index: u8 = 0,

    // ----------------------------------------------------------

    pub fn serialize(self: Self, writer: *std.Io.Writer) !void {
        try writer.writeInt(u8, @intFromEnum(self.input_direction), .little);
    }

    pub fn deserialize(reader: *std.Io.Reader) !Self {
        var self: Self = undefined;

        self.input_direction = @enumFromInt(try reader.takeInt(u8, .little));

        return self;
    }

    // ----------------------------------------------------------

    pub fn acceptItem(self: *Self, super: *Tile, map: *Map, item: Item) bool {
        _ = super;
        _ = map;
        _ = item;

        self.distribution_index += 1;
        if (self.distribution_index >= 3)
            self.distribution_index = 0;

        return true;
    }

    // ----------------------------------------------------------

    pub fn tick(self: *Self, super: *Tile, map: *Map, position: Vector2i) void {
        _ = .{ self, super, map, position };
    }

    // ----------------------------------------------------------

    pub fn draw(self: Self, super: Tile, position: Vector2i, textures: *Textures) void {
        _ = .{ self, super, position, textures };

        const rec = Tile.getRectangle(position);

        const rotation: f32 = switch (self.input_direction) {
            .up => 180.0,
            .down => 0.0,
            .left => 0.0,
            .right => 0.0,
        };

        rl.drawTexturePro(
            textures.distributor,
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
};