const rl = @import("raylib");
const util = @import("util.zig");

const Self = @This();

conveyor: rl.Texture,

pub fn init() Self {
    return .{
        .conveyor = util.loadTextureFromImageInMemory(@embedFile("assets/conveyor.png")),
    };
}

pub fn deinit(self: *Self) void {
    rl.unloadTexture(self.conveyor);
}
