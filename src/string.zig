const std = @import("std");
const Allocator = mem.Allocator;
// const ArenaAllocator = std.heap.ArenaAllocator;
// const AutoHashMapUnmanaged = std.AutoArrayHashMapUnmanaged;
const mem = std.mem;
// const Mutex = std.Thread.Mutex;
const t = std.testing;

const Numeric = @import("numeric.zig").Numeric;
const slice = @import("slice.zig");

pub const String = []const u8;

/// Checks if two strings are equal
pub fn eql(a: String, b: String) bool {
    return mem.eql(u8, a, b);
}

/// Makes a copy of the given string. Caller owns returned memory.
pub fn clone(alloc: Allocator, src: String) Allocator.Error!String {
    return try slice.clone(u8, alloc, src);
}

/// Hash is a unique, non-cryptographic hash of a String
pub const Hash = Numeric(u64);

/// Returns a unique, non-cryptographic hash of string for use as an
/// index in to various data structures
pub fn hash(str: String) Hash {
    return Hash.from(std.hash.Fnv1a_64.hash(str));
}

test "String basic operations" {
    const s = "Testing 123";
    const copy = try clone(t.allocator, s);
    defer t.allocator.free(copy);
    try t.expectEqualSlices(u8, s, copy);
    try t.expect(eql(s, copy));

    // hash was generated using a 3rd party tool
    try t.expectEqual(Hash.from(0x1b507107bc4a618f), hash(s));
}
