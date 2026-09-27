const rl = @import("raylib");

const Self = @This();

x: i64,
y: i64,

const zero = Self{
    .x = 0,
    .y = 0,
};

pub fn init(x: i64, y: i64) Self {
    return .{
        .x = x,
        .y = y,
    };
}

pub fn fromVector2(vec: rl.Vector2) Self {
    return .{
        .x = @intFromFloat(vec.x),
        .y = @intFromFloat(vec.y),
    };
}
