const std = @import("std");
const rl = @import("raylib");
const Vector2i = @import("Vector2i.zig");
const Tile = @import("tile.zig").Tile;
const Item = @import("Item.zig");
const Textures = @import("Textures.zig");

const Self = @This();

gpa: std.mem.Allocator,
tiles: std.AutoHashMap(Vector2i, Tile),
items: std.AutoHashMap(Vector2i, Item),

pub fn init(gpa: std.mem.Allocator) Self {
    return .{
        .gpa = gpa,
        .tiles = .init(gpa),
        .items = .init(gpa),
    };
}

pub fn deinit(self: *Self) void {
    self.items.deinit();
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
        var it = self.items.iterator();
        while (it.next()) |item| {
            item.value_ptr.draw(item.key_ptr.*, textures);
        }
    }
}

pub fn tick(self: *Self) void {
    var it = self.tiles.iterator();
    while (it.next()) |tile| {
        tile.value_ptr.tick(self, tile.key_ptr.*);
    }
}
