const rl = @import("raylib");
const std = @import("std");
const Vector2i = @import("Vector2i.zig");
const Textures = @import("Textures.zig");
const config = @import("config.zig");
const Map = @import("Map.zig");
const Item = @import("Item.zig");

const TileTag = enum(u8) {
    stone,
    conveyor,
    miner,
    collector,
};

pub const Tile = union(TileTag) {
    const Self = @This();

    const Conveyor = extern struct {
        pub const Direction = enum(u8) {
            up,
            down,
            left,
            right,
        };
        base_cooldown: f32 = 1.0,

        direction: Direction,

        cooldown: f32 = 1.0,
    };

    stone,
    conveyor: Conveyor,
    miner: extern struct {
        base_cooldown: f32 = 10.0,

        cooldown: f32 = 0.0,
    },
    collector,

    pub fn serialize(self: Self, writer: *std.Io.Writer) !void {
        try writer.writeInt(u8, @intFromEnum(self), .little);
        switch (self) {
            .conveyor => |conveyor| {
                try writer.writeStruct(conveyor, .little);
            },
            .miner => |miner| {
                try writer.writeStruct(miner, .little);
            },
            else => {},
        }
    }

    pub fn deserialize(reader: *std.Io.Reader) !Self {
        const tag: TileTag = @enumFromInt(try reader.takeInt(u8, .little));
        var self: Self = undefined;
        switch (tag) {
            inline else => |t| {
                self = @unionInit(Self, @tagName(t), undefined);
            },
        }

        switch (self) {
            .conveyor => {
                self.conveyor = try reader.takeStruct(@TypeOf(self.conveyor), .little);
            },
            .miner => {
                self.miner = try reader.takeStruct(@TypeOf(self.miner), .little);
            },
            else => {},
        }

        return self;
    }

    pub fn tick(self: *Self, map: *Map, position: Vector2i) void {
        switch (self.*) {
            .stone => {},
            .conveyor => {
                self.conveyor.cooldown -= config.one_tick_in_seconds;
                if (self.conveyor.cooldown <= 0) {
                    const new_position: Vector2i = switch (self.conveyor.direction) {
                        .up => .{
                            .x = position.x,
                            .y = position.y - 1,
                        },
                        .down => .{
                            .x = position.x,
                            .y = position.y + 1,
                        },
                        .left => .{
                            .x = position.x - 1,
                            .y = position.y,
                        },
                        .right => .{
                            .x = position.x + 1,
                            .y = position.y,
                        },
                    };
                    if (map.tiles.getPtr(new_position)) |tile| {
                        const is_allowed = switch (tile.*) {
                            .conveyor => true,
                            .collector => true,
                            else => false,
                        } and !map.items.contains(new_position);

                        if (is_allowed) {
                            if (map.items.fetchRemove(position)) |kv| {
                                map.items.put(new_position, kv.value) catch {};

                                if (tile.* == .conveyor) {
                                    // Reset the next conveyor's cooldown so that the item
                                    // doesn't move two times in one tick
                                    tile.conveyor.cooldown = tile.conveyor.base_cooldown;
                                }
                            }
                        }
                    }

                    self.conveyor.cooldown = self.conveyor.base_cooldown;
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
                                .kind = .stone,
                            };

                            map.items.put(item_position, item) catch {};

                            break;
                        }
                    }

                    self.miner.cooldown = self.miner.base_cooldown;
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
            .miner => {
                rl.drawTexturePro(
                    textures.miner,
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
            },
            .collector => {
                rl.drawTexturePro(
                    textures.collector,
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
            },
        }
    }
};
