const Direction = @import("../direction.zig").Direction;
const Tile = @import("../tile.zig").Tile;
const Map = @import("../Map.zig");
const Textures = @import("../Textures.zig");
const Vector2i = @import("../Vector2i.zig");
const std = @import("std");

pub const Distributor = struct {
    const Self = @This();

    input_direction: Direction = .down,

    pub fn serialize(self: Self, writer: *std.Io.Writer) !void {
        try writer.writeInt(u8, @intFromEnum(self.input_direction), .little);
    }

    pub fn deserialize(reader: *std.Io.Reader) !Self {
        var self: Self = undefined;

        self.input_direction = @enumFromInt(try reader.takeInt(u8, .little));

        return self;
    }

    pub fn tick(self: *Self, super: *Tile, map: *Map, position: Vector2i) void {
        _ = .{ self, super, map, position };
    }

    pub fn draw(self: Self, super: Tile, position: Vector2i, textures: *Textures) void {
        _ = .{ self, super, position, textures };
    }
};
