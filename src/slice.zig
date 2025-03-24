const std = @import("std");
const Allocator = mem.Allocator;
const mem = std.mem;
const t = std.testing;

/// Copies the contents of a slice to a new slice stored with the given allocator
pub fn clone(comptime T: type, alloc: Allocator, src: []const T) Allocator.Error![]T {
    const copy = try alloc.alloc(T, src.len);
    @memcpy(copy, src);
    return copy;
}

test "slice.clone" {
    const a = [_]u32{ 1, 2, 3 };
    const b = try clone(u32, t.allocator, &a);
    defer t.allocator.free(b);
    try t.expectEqualSlices(u32, &a, b);
}
