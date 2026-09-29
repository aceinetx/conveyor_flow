const Item = @import("item.zig").Item;
const Map = @import("Map.zig");
const Textures = @import("Textures.zig");
const Vector2i = @import("Vector2i.zig");
const config = @import("config.zig");
const tiles = @import("tiles.zig");
const util = @import("util.zig");
const rl = @import("raylib");
const std = @import("std");

const TileType = enum(u8) {
    stone,
    conveyor,
    miner,
    collector,
    distributor,
};

pub const Tile = union(TileType) {
    const Self = @This();

    stone,
    conveyor: tiles.Conveyor,
    miner: tiles.Miner,
    collector,
    distributor: tiles.Distributor,

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
            .distributor => |distributor| {
                try distributor.serialize(writer);
            },
            else => {},
        }
    }

    pub fn deserialize(reader: *std.Io.Reader) !Self {
        var self: Self = util.unionFromTag(Self, TileType, try reader.takeInt(u8, .little));

        switch (self) {
            .conveyor => {
                self.conveyor = try tiles.Conveyor.deserialize(reader);
            },
            .miner => {
                self.miner = try reader.takeStruct(@TypeOf(self.miner), .little);
            },
            .distributor => {
                self.distributor = try tiles.Distributor.deserialize(reader);
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
                self.miner.tick(self, map, position);
            },
            .distributor => {
                self.distributor.tick(self, map, position);
            },
            .collector => {},
        }
    }

    // ----------------------------------------------------------

    pub inline fn getRectangle(position: Vector2i) rl.Rectangle {
        return rl.Rectangle{
            .x = @floatFromInt(position.x * 32),
            .y = @floatFromInt(position.y * 32),
            .width = 32,
            .height = 32,
        };
    }

    pub fn draw(self: Self, position: Vector2i, textures: *Textures) void {
        const rec = Self.getRectangle(position);

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
                conveyor.draw(self, position, textures);
            },
            .miner => |miner| {
                miner.draw(self, position, textures);
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
            .distributor => |distributor| {
                distributor.draw(self, position, textures);
            },
        }
    }

    pub fn drawPost(self: Self, position: Vector2i, textures: *Textures) void {
        switch (self) {
            .conveyor => |conveyor| {
                conveyor.drawPost(self, position, textures);
            },
            else => {},
        }
    }
};
