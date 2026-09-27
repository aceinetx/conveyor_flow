const rl = @import("raylib");
const std = @import("std");
const Vector2i = @import("Vector2i.zig");
const Textures = @import("Textures.zig");
const config = @import("config.zig");
const Map = @import("Map.zig");
const Item = @import("Item.zig");

pub const Tile = union(enum(u8)) {
    const Self = @This();

    stone,
    conveyor: struct {
        pub const Direction = enum(u8) {
            up,
            down,
            left,
            right,
        };

        direction: Direction,
        cooldown: f32 = 1.0,
    },
    miner: struct {
        cooldown: f32 = 0.0,
    },
    collector,

    pub fn tick(self: *Self, map: *Map, position: Vector2i) void {
        switch (self.*) {
            .stone => {},
            .conveyor => {
                self.conveyor.cooldown -= config.one_tick_in_seconds;
                if (self.conveyor.cooldown <= 0) {
                    if (map.items.fetchRemove(position)) |kv| {
                        const new_position: Vector2i = switch (self.conveyor.direction) {
                            .up => .{
                                .x = kv.key.x,
                                .y = kv.key.y - 1,
                            },
                            .down => .{
                                .x = kv.key.x,
                                .y = kv.key.y + 1,
                            },
                            .left => .{
                                .x = kv.key.x - 1,
                                .y = kv.key.y,
                            },
                            .right => .{
                                .x = kv.key.x + 1,
                                .y = kv.key.y,
                            },
                        };

                        map.items.put(new_position, kv.value) catch {};

                        // Reset the next conveyor's cooldown so that the item
                        // doesn't move two times in one tick
                        if (map.tiles.getPtr(new_position)) |tile| {
                            if (tile.* == .conveyor) {
                                tile.conveyor.cooldown = 1.0;
                            }
                        }
                    }

                    self.conveyor.cooldown = 1.0;
                }
            },
            .miner => {
                self.miner.cooldown -= config.one_tick_in_seconds;

                if (self.miner.cooldown <= 0) {
                    const surrounding_positions = [_]Vector2i{
                        .{
                            .x = position.x,
                            .y = position.y - 1,
                        },
                        .{
                            .x = position.x - 1,
                            .y = position.y,
                        },
                        .{
                            .x = position.x,
                            .y = position.y + 1,
                        },
                        .{
                            .x = position.x + 1,
                            .y = position.y,
                        },
                    };

                    const has_source = for (surrounding_positions) |pos| {
                        if (map.tiles.get(pos)) |tile| {
                            if (tile == .stone) break true;
                        }
                    } else false;

                    if (has_source) {
                        for (surrounding_positions) |item_position| {
                            if (map.items.contains(item_position)) {
                                continue;
                            }

                            // Spawn only on an existing conveyor
                            if (map.tiles.get(item_position)) |tile| {
                                if (tile != .conveyor)
                                    continue;
                            } else continue;

                            const item = Item{
                                .kind = .testing,
                            };

                            map.items.put(item_position, item) catch {};

                            break;
                        }
                    }

                    self.miner.cooldown = 10;
                }
            },
            .collector => {
                if (map.items.fetchRemove(position)) |kv| {
                    _ = kv;
                }
            },
        }
    }

    pub fn right_click(self: *Self) void {
        switch (self.*) {
            .conveyor => {
                self.conveyor.direction = switch (self.conveyor.direction) {
                    .up => .left,
                    .left => .down,
                    .down => .right,
                    .right => .up,
                };
            },
            else => {},
        }
    }

    pub fn draw(self: Self, position: Vector2i, textures: *Textures) void {
        const rec = rl.Rectangle{
            .x = @floatFromInt(position.x * 32),
            .y = @floatFromInt(position.y * 32),
            .width = 32,
            .height = 32,
        };

        switch (self) {
            .stone => {
                rl.drawTexturePro(
                    textures.stone,
                    .{
                        .x = 0,
                        .y = 0,
                        .width = 32,
                        .height = 32,
                    },
                    rec,
                    .zero(),
                    0.0,
                    .gray,
                );
            },
            .conveyor => |conveyor| {
                const rotation: f32 = switch (conveyor.direction) {
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
            },
            .miner => |generator| {
                rl.drawTexturePro(
                    textures.placeholder,
                    .{
                        .x = 0,
                        .y = 0,
                        .width = 32,
                        .height = 32,
                    },
                    rec,
                    .zero(),
                    0.0,
                    .white,
                );

                const text = rl.textFormat("%.2f", .{generator.cooldown});
                rl.drawText(text, @intFromFloat(rec.x), @intFromFloat(rec.y), 5, .white);
            },
            .collector => {
                rl.drawTexturePro(
                    textures.placeholder,
                    .{
                        .x = 0,
                        .y = 0,
                        .width = 32,
                        .height = 32,
                    },
                    rec,
                    .zero(),
                    0.0,
                    .gray,
                );
            },
        }
    }
};
