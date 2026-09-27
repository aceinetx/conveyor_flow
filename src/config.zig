pub const ticks_per_second: usize = 20;
pub const one_tick_in_seconds: f32 = 1.0 / @as(f32, @floatFromInt(ticks_per_second));
pub var debug_mode: bool = true;
