const Item = @import("item.zig").Item;
const Tile = @import("tile.zig").Tile;
const Textures = @import("Textures.zig");
const Vector2i = @import("Vector2i.zig");
const rl = @import("raylib");
const std = @import("std");

const Self = @This();

gpa: std.mem.Allocator,
tiles: std.AutoHashMap(Vector2i, Tile),

pub fn init(gpa: std.mem.Allocator) Self {
    return .{
        .gpa = gpa,
        .tiles = .init(gpa),
    };
}

pub fn deinit(self: *Self) void {
    self.tiles.deinit();
}

pub fn draw(self: Self, textures: *Textures) void {
    {
        var it = self.tiles.iterator();
        while (it.next()) |tile| {
            tile.value_ptr.draw(tile.key_ptr.*, textures);
        }
    }
    {
        var it = self.tiles.iterator();
        while (it.next()) |tile| {
            tile.value_ptr.drawPost(tile.key_ptr.*, textures);
        }
    }
}

pub fn tick(self: *Self) void {
    var it = self.tiles.iterator();
    while (it.next()) |tile| {
        tile.value_ptr.tick(self, tile.key_ptr.*);
    }
}

pub fn serialize(self: Self, writer: *std.Io.Writer) !void {
    try writer.writeInt(u32, self.tiles.count(), .little);

    {
        var it = self.tiles.iterator();
        while (it.next()) |tile| {
            try writer.writeInt(i64, tile.key_ptr.x, .little);
            try writer.writeInt(i64, tile.key_ptr.y, .little);
            try tile.value_ptr.serialize(writer);
        }
    }

    try writer.flush();
}

pub fn deserialize(gpa: std.mem.Allocator, reader: *std.Io.Reader) !Self {
    var self = Self.init(gpa);
    errdefer self.deinit();

    const tiles_count = try reader.takeInt(u32, .little);

    for (0..tiles_count) |_| {
        const pos = blk: {
            const x = try reader.takeInt(i64, .little);
            const y = try reader.takeInt(i64, .little);
            break :blk Vector2i.init(x, y);
        };
        const tile = try Tile.deserialize(reader);
        try self.tiles.put(pos, tile);
    }

    return self;
}