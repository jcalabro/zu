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
}
