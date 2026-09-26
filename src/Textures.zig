const rl = @import("raylib");
const util = @import("util.zig");

const Self = @This();

placeholder: rl.Texture2D,
conveyor: rl.Texture2D,

pub fn init() Self {
    return .{
        .placeholder = util.createPlaceholderTexture(),
        .conveyor = util.loadTextureFromImageInMemory(@embedFile("assets/conveyor.png")),
    };
}

pub fn deinit(self: *Self) void {
    rl.unloadTexture(self.conveyor);
    rl.unloadTexture(self.placeholder);
}
