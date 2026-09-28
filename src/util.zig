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

pub inline fn isRectangleInside(inner: rl.Rectangle, outer: rl.Rectangle) bool {
    return inner.x >= outer.x and
        inner.y >= outer.y and
        inner.x + inner.width <= outer.x + outer.width and
        inner.y + inner.height <= outer.y + outer.height;
}

pub inline fn createRectangleAroundPoint(point: rl.Vector2, full_size_not_half: f32) rl.Rectangle {
    return .{
        .x = point.x - full_size_not_half / 2,
        .y = point.y - full_size_not_half / 2,
        .width = full_size_not_half,
        .height = full_size_not_half,
    };
}

pub inline fn unionFromTag(UnionT: type, TagT: type, tag: u8) UnionT {
    const tag_enum: TagT = @enumFromInt(tag);
    var x: UnionT = undefined;
    switch (tag_enum) {
        inline else => |t| {
            x = @unionInit(UnionT, @tagName(t), undefined);
        },
    }
    return x;
}

pub fn declsContainShit(comptime decls: []const std.builtin.Type.Declaration, comptime name: [:0]const u8) bool {
    inline for (decls) |decl| {
        @compileLog(.{ name, decl.name });
        if (std.mem.eql(u8, decl.name, name)) {
            @compileLog("ok");
            return true;
        }
    }
    return false;
}
