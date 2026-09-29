const Map = @import("../Map.zig");
const rl = @import("raylib");
const Tile = @import("../tile.zig").Tile;
const Vector2i = @import("../Vector2i.zig");
const config = @import("../config.zig");
const Item = @import("../item.zig").Item;
const Textures = @import("../Textures.zig");

pub const Miner = extern struct {
    const Self = @This();

    base_cooldown: f32 = 10.0,

    cooldown: f32 = 0.0,

    pub fn tick(self: *Self, super: *Tile, map: *Map, position: Vector2i) void {
        _ = super;

        self.cooldown -= config.one_tick_in_seconds;

        if (self.cooldown <= 0) {
            self.cooldown = 0;

            const surrounding_positions = [_]Vector2i{
                .{
                    .x = position.x,
                    .y = position.y - 1,
                },
                .{
                    .x = position.x - 1,
                    .y = position.y,
                },
                .{
                    .x = position.x,
                    .y = position.y + 1,
                },
                .{
                    .x = position.x + 1,
                    .y = position.y,
                },
            };

            const has_source = for (surrounding_positions) |pos| {
                if (map.tiles.get(pos)) |tile| {
                    if (tile == .stone) break true;
                }
            } else false;

            if (has_source) {
                for (surrounding_positions) |item_position| {
                    if (map.tiles.getPtr(item_position)) |tile| {
                        const item = Item{
                            .kind = .stone,
                        };
                        if (tile.acceptItem(item)) {
                            // Success
                            self.cooldown = self.base_cooldown;
                            break;
                        }
                    }
                }
            }
        }
    }

    pub fn draw(self: Self, super: Tile, position: Vector2i, textures: *Textures) void {
        _ = .{ self, super };

        const rec = rl.Rectangle{
            .x = @floatFromInt(position.x * 32),
            .y = @floatFromInt(position.y * 32),
            .width = 32,
            .height = 32,
        };

        rl.drawTexturePro(
            textures.miner,
            .{
                .x = 0,
                .y = 0,
                .width = 32,
                .height = 32,
            },
            rec,
            .zero(),
            0.0,
            .white,
        );
    }
};
