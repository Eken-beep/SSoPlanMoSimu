const std = @import("std");

const G: comptime_float = 6.67430e-11;
// One AU in meters
const AU: comptime_float = 149597870700;

pub const Direction = enum {
    n,
    s,
    e,
    w,
};

pub const Body = struct {
    position: @Vector(2, f128),
    // The x and y components of the force, summed up to one vector
    force: @Vector(2, f128) = @splat(0),
    // Start velocity
    v0: @Vector(2, f128),
    mass: f128,
    color: @Vector(3, u8),

    pub fn step(self: *Body, time: f128) void {
        const acceleration = self.force / @as(@Vector(2, f128), @splat(self.mass));
        std.debug.print("acceleration: {d}\n", .{acceleration});
        self.position[0] += ((self.v0[0] * time + acceleration[0] * time * time / 2) / AU);
        self.position[1] += ((self.v0[1] * time + acceleration[1] * time * time / 2) / AU);
        std.debug.print("x {d} y {d}\n", .{ self.position[0], self.position[1] });
    }
};

pub fn step(bodies: []Body, time: f128) void {
    for (bodies) |*body| {
        body.step(time);
        body.force = @splat(0);
        for (bodies) |other| {
            body.force += getGravitationalForce(body.*, other);
        }
    }
}

fn getGravitationalForce(body: Body, other: Body) @Vector(2, f128) {
    // Make AU into meters for the formula to work
    const distance = (body.position - other.position) * @as(@Vector(2, f128), @splat(AU));
    const force = @Vector(2, f128){
        if (distance[0] != 0) G * (body.mass * other.mass) / (distance[0] * distance[0]) else 0,
        if (distance[1] != 0) G * (body.mass * other.mass) / (distance[1] * distance[1]) else 0,
    };
    std.debug.print("force: {any}\n", .{force});
    return force;
}
