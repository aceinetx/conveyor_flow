const rl = @import("raylib");
const std = @import("std");

pub fn getScreenSize() rl.Vector2 {
    return .{
        .x = @floatFromInt(rl.getScreenWidth()),
        .y = @floatFromInt(rl.getScreenHeight()),
    };
}

pub inline fn createPlaceholderTexture() rl.Texture2D {
    const image = rl.genImageChecked(32, 32, 16, 16, .black, .purple);
    const texture = rl.loadTextureFromImage(image) catch unreachable;
    rl.unloadImage(image);
    return texture;
}

pub inline fn loadTextureFromImageInMemory(data: []const u8) rl.Texture2D {
    const image = rl.loadImageFromMemory(".png", data) catch {
        std.log.err("[loadTextureFromImageInMemory] Image load failed, using placeholder texture", .{});
        return createPlaceholderTexture();
    };
    defer rl.unloadImage(image);
    const texture = rl.loadTextureFromImage(image) catch {
        std.log.err("[loadTextureFromImageInMemory] Texture load failed, using placeholder texture", .{});
        return createPlaceholderTexture();
    };
    return texture;
}
