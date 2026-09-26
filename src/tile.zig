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
                //rl.drawRectangleRec(rec, .black);
                rl.drawTexture(textures.conveyor, @intFromFloat(rec.x), @intFromFloat(rec.y), .white);

                const text = switch (conveyor.direction) {
                    .up => "up",
                    .down => "down",
                    .left => "left",
                    .right => "right",
                };
                rl.drawText(text, @intFromFloat(rec.x), @intFromFloat(rec.y), 5, .purple);
            },
        }
    }
};
