//! `Error` carries additional user-friendly error messages that can provide more context on why a particular operation failed.

// @REF: https://github.com/ziglang/zig/issues/2647

const std = @import("std");
const Allocator = std.mem.Allocator;
const t = std.testing;

const Self = @This();

/// The allocator that will be used to set and free the error message, if any
alloc: Allocator,

/// The user-friendly error message describing what went wrong
message: ?[]const u8 = null,

/// Creates a new `Error` that is ready for use
pub fn init(alloc: Allocator) Self {
    return .{ .alloc = alloc };
}

/// Releases and invalidates any memory held by this `Error`
pub fn deinit(self: *Self) void {
    self.clear();
    self.* = undefined;
}

/// Resets the error message, if any
pub fn clear(self: *Self) void {
    if (self.message) |m| self.alloc.free(m);
    self.message = null;
}

/// Foramts and sets the error message, free'ing and overwriting
/// any existing value. Caller owns returned memory.
pub fn set(
    self: *Self,
    comptime msg: []const u8,
    args: anytype,
) Allocator.Error!void {
    self.clear();
    self.message = try std.fmt.allocPrint(self.alloc, msg, args);
}

/// Formats the `Error` in to a string
pub fn format(self: @This(), writer: *std.io.Writer) !void {
    const msg = if (self.message) |m| m else "(none)";
    _ = try writer.print("{s}", .{msg});
}

/// Prints the error to stderr if an error is set, else is a noop. This is a convenience wrapper that's likely only appropriate for tests.
pub fn printAndDeinit(self: *Self) void {
    if (self.message) |m| std.debug.print("error: {s}\n", .{m});
    self.deinit();
}

test "Error" {
    const S = struct {
        fn check(alloc: Allocator) Allocator.Error!void {
            var err = Self.init(alloc);
            defer err.deinit();

            try err.set("this is {s}", .{"a test"});
            try err.set("this is {s}", .{"a second"});
        }
    };

    try t.checkAllAllocationFailures(t.allocator, S.check, .{});

    var err = Self.init(t.allocator);
    defer err.deinit();

    {
        const msg = try std.fmt.allocPrint(t.allocator, "msg: {f}!", .{err});
        defer t.allocator.free(msg);
        try t.expectEqualSlices(u8, "msg: (none)!", msg);
    }

    try err.set("hi", .{});
    const msg = try std.fmt.allocPrint(t.allocator, "{f} there!", .{err});
    defer t.allocator.free(msg);
    try t.expectEqualSlices(u8, "hi there!", msg);
}
