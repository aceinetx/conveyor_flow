const rl = @import("raylib");

pub fn getScreenSize() rl.Vector2 {
    return .{
        .x = @floatFromInt(rl.getScreenWidth()),
        .y = @floatFromInt(rl.getScreenHeight()),
    };
}

pub inline fn createPlaceholderTexture() rl.Texture {
    const image = rl.genImageColor(1, 1, .purple);
    const texture = rl.loadTextureFromImage(image) catch unreachable;
    rl.unloadImage(image);
    return texture;
}

pub inline fn loadTextureFromImageInMemory(data: []const u8) rl.Texture {
    const image = rl.loadImageFromMemory(".png", data) catch return createPlaceholderTexture();
    defer rl.unloadImage(image);
    const texture = rl.loadTextureFromImage(image) catch return createPlaceholderTexture();
    return texture;
}
