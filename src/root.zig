const rl = @import("raylib");
const util = @import("util.zig");
const std = @import("std");
const config = @import("config.zig");
const Map = @import("Map.zig");
const Tile = @import("tile.zig").Tile;
const Textures = @import("Textures.zig");
const Vector2i = @import("Vector2i.zig");

pub fn main(init: std.process.Init) void {
    rl.initWindow(1280, 720, "Conveyor flow");
    defer rl.closeWindow();

    var tick_timer: f32 = config.one_tick_in_seconds;

    var textures = Textures.init();
    defer textures.deinit();

    var map = Map.init(init.gpa);
    defer map.deinit();

    map.tiles.put(.init(0, 0), .collector) catch {};
    map.tiles.put(.init(-5, -5), .stone) catch {};
    map.tiles.put(.init(-4, -5), .stone) catch {};
    map.tiles.put(.init(-4, -3), .stone) catch {};
    map.tiles.put(.init(-4, -4), .stone) catch {};
    map.tiles.put(.init(-3, -4), .stone) catch {};

    map.tiles.put(.init(5, 5), .stone) catch {};
    map.tiles.put(.init(4, 5), .stone) catch {};
    map.tiles.put(.init(4, 3), .stone) catch {};
    map.tiles.put(.init(4, 4), .stone) catch {};
    map.tiles.put(.init(3, 4), .stone) catch {};

    // ----------------------------------------------------------

    var camera = rl.Camera2D{
        .target = .zero(),
        .offset = .zero(),
        .rotation = 0,
        .zoom = 1,
    };

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        rl.clearBackground(.white);

        camera.offset = util.getScreenSize().scale(0.5);

        camera.begin();

        map.draw(&textures);

        camera.end();

        const mouse_pos = rl.getMousePosition();
        const mouse_pos_grid = blk: {
            var pos = mouse_pos;
            pos = pos.subtract(camera.offset);
            pos = pos.scale(1 / camera.zoom);
            pos = pos.add(camera.target);
            pos = rl.Vector2{
                .x = @divFloor(pos.x, 32),
                .y = @divFloor(pos.y, 32),
            };
            break :blk Vector2i.fromVector2(pos);
        };

        camera.begin();

        // Cursor
        rl.drawRectangle(
            @intCast(mouse_pos_grid.x * 32),
            @intCast(mouse_pos_grid.y * 32),
            32,
            32,
            .init(0, 0, 0, 100),
        );

        camera.end();

        rl.endDrawing();

        // ----------------------------------------------------------

        // Camera movement
        if (rl.isKeyPressed(.one)) {
            map.tiles.put(
                mouse_pos_grid,
                .{
                    .conveyor = .{
                        .direction = .up,
                    },
                },
            ) catch {};
        }
        if (rl.isKeyPressed(.two)) {
            map.tiles.put(
                mouse_pos_grid,
                .{
                    .miner = .{},
                },
            ) catch {};
        }

        if (rl.isMouseButtonPressed(.right)) {
            if (map.tiles.getPtr(mouse_pos_grid)) |tile| {
                tile.right_click();
            }
        }

        if (rl.isMouseButtonDown(.left)) {
            const delta_move = rl.getMouseDelta();
            camera.target = camera.target.subtract(
                delta_move.scale(1 / camera.zoom),
            );
        }

        // Zooming
        const mouse_wheel_move = rl.getMouseWheelMoveV();
        camera.zoom += 0.1 * mouse_wheel_move.y;
        if (camera.zoom < 0.1) camera.zoom = 0.1;

        // ----------------------------------------------------------

        tick_timer -= rl.getFrameTime();
        if (tick_timer <= 0) {
            map.tick();
            tick_timer = config.one_tick_in_seconds;
        }
    }
}
