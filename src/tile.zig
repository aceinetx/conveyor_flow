const rl = @import("raylib");
const util = @import("util.zig");
const std = @import("std");
const Vector2i = @import("Vector2i.zig");
const Textures = @import("Textures.zig");
const config = @import("config.zig");
const Map = @import("Map.zig");
const Item = @import("item.zig").Item;
const Conveyor = @import("Conveyor.zig");

const TileType = enum(u8) {
    stone,
    conveyor,
    miner,
    collector,
};

pub const Tile = union(TileType) {
    const Self = @This();

    stone,
    conveyor: Conveyor,
    miner: extern struct {
        base_cooldown: f32 = 10.0,

        cooldown: f32 = 0.0,
    },
    collector,

    // ----------------------------------------------------------

    pub fn serialize(self: Self, writer: *std.Io.Writer) !void {
        try writer.writeInt(u8, @intFromEnum(self), .little);
        switch (self) {
            .conveyor => |conveyor| {
                try conveyor.serialize(writer);
            },
            .miner => |miner| {
                try writer.writeStruct(miner, .little);
            },
            else => {},
        }
    }

    pub fn deserialize(reader: *std.Io.Reader) !Self {
        var self: Self = util.unionFromTag(Self, TileType, try reader.takeInt(u8, .little));

        switch (self) {
            .conveyor => {
                self.conveyor = try Conveyor.deserialize(reader);
            },
            .miner => {
                self.miner = try reader.takeStruct(@TypeOf(self.miner), .little);
            },
            else => {},
        }

        return self;
    }

    // ----------------------------------------------------------

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

    // ----------------------------------------------------------

    pub fn acceptItem(self: *Self, item: Item) bool {
        switch (self.*) {
            .conveyor => {
                if (self.conveyor.item == null) {
                    self.conveyor.item = item;
                    self.conveyor.move_progress = 0.0;
                    std.log.debug("conveyor accepted item: {}", .{item});
                    return true;
                }
            },
            .collector => {
                return true;
            },
            else => {},
        }
        return false;
    }

    // ----------------------------------------------------------

    pub fn tick(self: *Self, map: *Map, position: Vector2i) void {
        switch (self.*) {
            .stone => {},
            .conveyor => {
                self.conveyor.tick(self, map, position);
            },
            .miner => {
                self.miner.cooldown -= config.one_tick_in_seconds;

                if (self.miner.cooldown <= 0) {
                    self.miner.cooldown = 0;

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
                            if (map.tiles.getPtr(item_position)) |tile| {
                                const item = Item{
                                    .kind = .stone,
                                };
                                if (tile.acceptItem(item)) {
                                    // Success
                                    self.miner.cooldown = self.miner.base_cooldown;
                                    break;
                                }
                            }
                        }
                    }
                }
            },
            .collector => {},
        }
    }

    // ----------------------------------------------------------

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

    pub fn drawPost(self: Self, position: Vector2i, textures: *Textures) void {
        const rec = rl.Rectangle{
            .x = @floatFromInt(position.x * 32),
            .y = @floatFromInt(position.y * 32),
            .width = 32,
            .height = 32,
        };

        switch (self) {
            .conveyor => |conveyor| {
                if (conveyor.item) |item| {
                    const pos: rl.Vector2 = switch (conveyor.direction) {
                        .up => .init(
                            rec.x + 16,
                            rec.y + (32.0 * (1.0 - conveyor.move_progress)),
                        ),
                        .down => .init(
                            rec.x + 16,
                            rec.y + (32.0 * (conveyor.move_progress)),
                        ),
                        .left => .init(
                            rec.x + (32.0 * (1.0 - conveyor.move_progress)),
                            rec.y + 16,
                        ),
                        .right => .init(
                            rec.x + (32.0 * (conveyor.move_progress)),
                            rec.y + 16,
                        ),
                    };

                    item.draw(pos, textures);
                }
            },
            else => {},
        }
    }
};
