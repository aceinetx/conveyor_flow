const std = @import("std");
const rl = @import("raylib");
const Vector2i = @import("Vector2i.zig");
const Tile = @import("tile.zig").Tile;
const Textures = @import("Textures.zig");

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

pub fn set(self: *Self, position: Vector2i, tile: Tile) void {
    self.tiles.put(position, tile) catch {};
}

pub fn get(self: Self, position: Vector2i) ?Tile {
    return self.tiles.get(position);
}

pub fn getPtr(self: *Self, position: Vector2i) ?*Tile {
    return self.tiles.getPtr(position);
}

pub fn draw(self: Self, textures: *Textures) void {
    var it = self.tiles.iterator();
    while (it.next()) |tile| {
        tile.value_ptr.draw(tile.key_ptr.*, textures);
    }
}

pub fn tick(self: *Self) void {
    var it = self.tiles.iterator();
    while (it.next()) |tile| {
        tile.value_ptr.tick(tile.key_ptr.*);
    }
}
