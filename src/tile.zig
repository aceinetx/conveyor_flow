const rl = @import("raylib");
const Vector2i = @import("Vector2i.zig");
const Textures = @import("Textures.zig");

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
        }
    }
};
