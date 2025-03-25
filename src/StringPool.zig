//! A simple data structure used to do thread-safe string interning

const std = @import("std");
const Allocator = mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const AutoHashMapUnmanaged = std.AutoArrayHashMapUnmanaged;
const mem = std.mem;
const Mutex = std.Thread.Mutex;
const t = std.testing;

const string = @import("string.zig");
const String = string.String;

const Self = @This();

alloc: Allocator,
arena: *ArenaAllocator,

mu: Mutex = .{},
map: AutoHashMapUnmanaged(string.Hash, String) = .{},

/// Initializes a `StringPool` for use
pub fn init(alloc: Allocator) Allocator.Error!*Self {
    const arena = try alloc.create(ArenaAllocator);
    arena.* = ArenaAllocator.init(alloc);
    errdefer {
        arena.deinit();
        alloc.destroy(arena);
    }

    const self = try alloc.create(Self);
    errdefer alloc.destroy(self);
    self.* = .{
        .arena = arena,
        .alloc = arena.allocator(),
    };
    return self;
}

/// Releases all memory held by the `StringPool`
pub fn deinit(self: *Self, alloc: Allocator) void {
    {
        self.mu.lock();
        defer self.mu.unlock();

        self.arena.deinit();
        alloc.destroy(self.arena);
    }

    alloc.destroy(self);
}

/// Returns the number of strings in the pool
pub fn count(self: *Self) usize {
    self.mu.lock();
    defer self.mu.unlock();

    return self.map.count();
}

/// Inserts an item in to the cache, returning its cache key. It allocates
/// and stores a local copy of the string, so the caller is free to do what
/// it wants with the passed `str`.
pub fn add(self: *Self, str: String) Allocator.Error!string.Hash {
    self.mu.lock();
    defer self.mu.unlock();

    // check for existing so we avoid duplicates
    const hash = string.hash(str);
    if (self.map.contains(hash)) return hash;

    // copy and store
    const local = try string.clone(self.alloc, str);
    try self.map.put(self.alloc, hash, local);
    return hash;
}

/// Do not store or modify the return value of this function. This is intended for
/// quick-and-dirty lookups of Strings in the table. If the caller wishes to hold
/// on to the String, use `getOwned`, which will take a copy of the String in the
/// passed allocator (if any String is found).
pub fn get(self: *Self, hash: string.Hash) ?String {
    self.mu.lock();
    defer self.mu.unlock();

    return self.map.get(hash);
}

/// Caller owns returned memory, if the String is found
pub fn getOwned(self: *Self, alloc: Allocator, hash: string.Hash) Allocator.Error!?String {
    self.mu.lock();
    defer self.mu.unlock();

    if (self.map.get(hash)) |str| {
        return try string.clone(alloc, str);
    }

    return null;
}

/// Allocates and does a full copy of every string in the given Cache. Caller
/// owns returned memory, and the existing cache is still valid after copy.
pub fn clone(self: *Self, alloc: Allocator) Allocator.Error!*Self {
    const new = try init(alloc);
    errdefer new.deinit(alloc);

    self.mu.lock();
    defer self.mu.unlock();

    try new.map.ensureTotalCapacity(new.alloc, self.map.count());

    var it = self.map.iterator();
    while (it.next()) |str| {
        new.map.putAssumeCapacity(str.key_ptr.*, str.value_ptr.*);
    }

    return new;
}

test "StringPool" {
    const S = struct {
        fn check(alloc: Allocator) !void {
            const pool = try Self.init(alloc);
            defer pool.deinit(alloc);

            _ = try pool.add("test 1");
            try t.expectEqual(1, pool.count());

            _ = try pool.add("test 1"); // insert a dupe is a noop
            try t.expectEqual(1, pool.count());

            _ = try pool.add("test 2");
            try t.expectEqual(2, pool.count());
            const hash = try pool.add("test 3");
            try t.expectEqual(3, pool.count());

            const item1 = pool.get(hash);
            try t.expect(item1 != null);
            try t.expectEqualSlices(u8, "test 3", item1.?);

            const item2 = try pool.getOwned(alloc, hash);
            try t.expect(item2 != null);
            defer alloc.free(item2.?);
            try t.expectEqualSlices(u8, "test 3", item2.?);

            const pool2 = try pool.clone(alloc);
            defer pool2.deinit(alloc);
            try t.expectEqual(3, pool2.count());
        }
    };

    try t.checkAllAllocationFailures(t.allocator, S.check, .{});
}
