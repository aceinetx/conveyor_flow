const rl = @import("raylib");
const Vector2i = @import("Vector2i.zig");
const Textures = @import("Textures.zig");

const Self = @This();

count: u8 = 1,

kind: union(enum) {
    testing,
},

pub fn draw(self: Self, position: Vector2i, textures: *Textures) void {
    switch (self.kind) {
        .testing => {
            rl.drawTexture(
                textures.placeholder,
                @intCast(position.x * 32),
                @intCast(position.y * 32),
                .white,
            );
        },
    }
}
