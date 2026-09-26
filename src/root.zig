const rl = @import("raylib");
const util = @import("util.zig");
const std = @import("std");
const Map = @import("Map.zig");
const Textures = @import("Textures.zig");

pub fn main(init: std.process.Init) void {
    rl.initWindow(1280, 720, "Conveyor flow");
    defer rl.closeWindow();

    var textures = Textures.init();
    defer textures.deinit();

    var map = Map.init(init.gpa);
    defer map.deinit();

    map.set(.init(0, 0), .{ .conveyor = .{ .direction = .right } });
    map.set(.init(1, 0), .{ .conveyor = .{ .direction = .right } });
    map.set(.init(2, 0), .{ .conveyor = .{ .direction = .down } });
    map.set(.init(2, 1), .{ .conveyor = .{ .direction = .left } });
    map.set(.init(0, 1), .{ .conveyor = .{ .direction = .up } });
    map.set(.init(1, 1), .{ .conveyor = .{ .direction = .left } });

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

        rl.endDrawing();

        // ----------------------------------------------------------

        // Camera movement
        if (rl.isMouseButtonDown(.left)) {
            const delta_move = rl.getMouseDelta();
            camera.target = camera.target.subtract(
                delta_move.scale(1 / camera.zoom),
            );
        }

        // Zooming
        const mouse_wheel_move = rl.getMouseWheelMoveV();
        camera.zoom += 0.1 * mouse_wheel_move.y;
    }
}
