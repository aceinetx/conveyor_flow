const rl = @import("raylib");
const Vector2i = @import("Vector2i.zig");
const Textures = @import("Textures.zig");
const config = @import("config.zig");

pub const Tile = union(enum) {
    pub const ConveyorDirection = enum {
        up,
        down,
        left,
        right,
    };

    air,
    conveyor: struct {
        direction: ConveyorDirection,
    },
    generator: struct {
        cooldown: f32 = 1.0,
    },

    pub fn tick(self: *Tile, position: Vector2i) void {
        _ = position;
        switch (self.*) {
            .generator => {
                self.generator.cooldown -= config.one_tick_in_seconds;
            },
            else => {},
        }
    }

    pub fn draw(self: Tile, position: Vector2i, textures: *Textures) void {
        switch (self) {
            .air => {},
            .conveyor => |conveyor| {
                var rec = rl.Rectangle{
                    .x = @floatFromInt(position.x),
                    .y = @floatFromInt(position.y),
                    .width = 32,
                    .height = 32,
                };
                rec.x *= rec.width;
                rec.y *= rec.height;

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
                    rec,
                    .init(rec.width / 2, rec.height / 2),
                    rotation,
                    .white,
                );
            },
            .generator => |generator| {
                const pos = rl.Vector2.init(
                    @floatFromInt(position.x * 32),
                    @floatFromInt(position.y * 32),
                );

                rl.drawTextureV(textures.placeholder, pos, .white);

                const text = rl.textFormat("%.2f", .{generator.cooldown});
                rl.drawText(text, @intFromFloat(pos.x), @intFromFloat(pos.y), 5, .white);
            },
        }
    }
};
