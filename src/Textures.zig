const util = @import("util.zig");
const rl = @import("raylib");
const std = @import("std");

const Self = @This();

placeholder: rl.Texture2D,
conveyor: rl.Texture2D,
stone: rl.Texture2D,
stone_item: rl.Texture2D,
miner: rl.Texture2D,
collector: rl.Texture2D,

pub fn init() Self {
    return .{
        .placeholder = util.createPlaceholderTexture(),
        .conveyor = util.loadTextureFromImageInMemory(@embedFile("assets/conveyor.png")),
        .stone = util.loadTextureFromImageInMemory(@embedFile("assets/stone.png")),
        .stone_item = util.loadTextureFromImageInMemory(@embedFile("assets/stone_item.png")),
        .miner = util.loadTextureFromImageInMemory(@embedFile("assets/miner.png")),
        .collector = util.loadTextureFromImageInMemory(@embedFile("assets/collector.png")),
    };
}

pub fn deinit(self: *Self) void {
    inline for (std.meta.fields(Self)) |field| {
        rl.unloadTexture(@field(self, field.name));
    }
}