const std = @import("std");
const SDL = @import("sdl2");
const P = @import("Physics.zig");

const fontpath: [:0]const u8 = "./font.ttf";
const fontsize = 24;
const PIXELSPERAU: comptime_float = 800 / 30;

pub fn main() anyerror!void {
    try SDL.init(.{
        .video = true,
        .events = true,
        .audio = true,
    });
    defer SDL.quit();

    var sdl_window = try SDL.createWindow(
        "~SSoPlanMoSimu~",
        .{ .centered = {} },
        .{ .centered = {} },
        1600,
        900,
        .{
            .vis = .shown,
            .resizable = true,
        },
    );
    defer sdl_window.destroy();

    var renderer = try SDL.createRenderer(sdl_window, null, .{ .accelerated = true });
    defer renderer.destroy();

    try SDL.ttf.init();
    defer SDL.ttf.quit();

    var running = true;
    var paused = false;

    var windowsize = @Vector(2, i32){ 1600, 900 };
    var viewport = windowsize;

    const font = SDL.ttf.openFont(fontpath, fontsize) catch |err| {
        std.log.err("Failed to open font at {s}", .{fontpath});
        return err;
    };

    defer font.close();

    // This allocator is for everything other than the currently active level and it's associated data
    var general_purpouse_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpouse_allocator.allocator();

    var bodies = std.ArrayList(P.Body).init(gpa);
    try bodies.append(.{
        .mass = 1.9891e+30,
        .position = @splat(0),
        .v0 = @splat(0),
        .color = .{ 0, 255, 255 },
    });
    try bodies.append(.{
        .mass = 5.9722e+24,
        .position = @Vector(2, f128){ 0, 1 },
        .v0 = .{ 29784, 0 },
        .color = .{ 0, 255, 0 },
    });

    while (running) {
        try renderer.setColorRGB(0, 0, 0);
        try renderer.clear();

        while (SDL.pollEvent()) |event| {
            switch (event) {
                .quit => running = false,
                .window => {
                    if (event.window.type == .resized) {
                        const window = sdl_window.getSize();
                        // For changing the viewport equally to the rest of the window even if they are sized different
                        var deltaWindow = windowsize;
                        windowsize[0] = @intCast(window.width);
                        windowsize[1] = @intCast(window.height);
                        deltaWindow = @intCast(@abs(deltaWindow - windowsize));
                        viewport += deltaWindow;
                    }
                },
                .key_down => |key| {
                    switch (key.keycode) {
                        .space => paused = !paused,
                        else => {},
                    }
                },
                else => {},
            }
        }

        if (!paused) P.step(bodies.items, 1);
        for (bodies.items) |body| {
            try renderer.setColorRGB(body.color[0], body.color[1], body.color[2]);
            const pos = mapCoordinateSystemToScreen(body.position, windowsize);
            try renderer.fillRect(.{
                .x = pos[0] - 25,
                .y = pos[1] - 25,
                .width = 50,
                .height = 50,
            });
        }

        renderer.present();
    }
}

// For drawing the coordinate system
fn mapCoordinateSystemToScreen(v: @Vector(2, f128), window: @Vector(2, i32)) @Vector(2, i32) {
    std.debug.print("x {d} y {d}\n", .{ v[0], v[1] });
    const vInt: @Vector(2, i32) = @intFromFloat(v);
    return @divTrunc(window, @as(@Vector(2, i32), @splat(2))) + vInt;
}

fn drawAxis(r: SDL.Renderer, axis: P.Direction, window: @Vector(2, i32)) !void {
    const start = @Vector(2, i32){ @divTrunc(window[0], 2), @divTrunc(window[1], 2) };
    try r.setColorRGB(255, 255, 255);

    const scale = @Vector(2, f128){ @floatFromInt(@divTrunc(window[0], 1600)), @floatFromInt(@divTrunc(window[1], 900)) };
    const pixelsPerAU = @Vector(2, f128){ PIXELSPERAU * scale[0], PIXELSPERAU * scale[1] };

    switch (axis) {
        .n => {
            try r.drawLine(start[0], start[1], start[0], 0);

            const ppau: i32 = @intFromFloat(pixelsPerAU[1]);
            // Scale when drawing is 30 astronomical units per 800 pixels
            var i: i32 = start[1];
            while (i > 0) : (i -= ppau) {
                try r.drawLine(start[0], start[1] + i, start[0] + 10, start[1] + i);
            }
        },
        .w => {
            try r.drawLine(start[0], start[1], 0, start[1]);
        },
        .s => {
            try r.drawLine(start[0], start[1], start[0], window[1]);
        },
        .e => {
            try r.drawLine(start[0], start[1], window[0], start[1]);
        },
    }
}
