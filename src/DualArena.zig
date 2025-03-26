//! Implements the common pattern of creating a permanent arena as well as a scratch arena.
//!
//! The scratch arena is intended to be freed at the end of scope and the permanent arena is intended to be freed in the case of an error.

const std = @import("std");
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const t = std.testing;

const Self = @This();

perm: Allocator,
perm_arena: ArenaAllocator,

scratch: Allocator,
scratch_arena: ArenaAllocator,

/// Initializes the DualArena with a perm and scratch arena allocator
pub inline fn init(alloc: Allocator) Allocator.Error!*Self {
    const self = try alloc.create(Self);
    errdefer alloc.destroy(self);

    self.* = .{
        .perm = undefined,
        .perm_arena = ArenaAllocator.init(alloc),
        .scratch = undefined,
        .scratch_arena = ArenaAllocator.init(alloc),
    };

    self.perm = self.perm_arena.allocator();
    self.scratch = self.scratch_arena.allocator();

    return self;
}

/// Deinitializes both arenas
pub fn deinit(self: *Self, alloc: Allocator) void {
    self.perm_arena.deinit();
    self.scratch_arena.deinit();
    alloc.destroy(self);
}

/// Frees any data allocated in the permanent arena
pub fn freePerm(self: *Self) void {
    _ = self.perm_arena.reset(.free_all);
}

/// Frees any data allocated in the scratch arena
pub fn freeScratch(self: *Self) void {
    _ = self.scratch_arena.reset(.free_all);
}

test "DualArena" {
    try t.expectError(error.OutOfMemory, Self.init(t.failing_allocator));

    const S = struct {
        fn check(arenas: *Self) Allocator.Error!*u32 {
            errdefer arenas.freePerm();
            defer arenas.freeScratch();

            _ = try arenas.scratch.create(u32);

            const res = try arenas.perm.create(u32);
            res.* = 123;
            return res;
        }
    };

    {
        // test the success case
        var self = try Self.init(t.allocator);
        defer self.deinit(t.allocator);

        const res = try S.check(self);
        try t.expectEqual(123, res.*);
        try t.expectEqual(0, self.scratch_arena.state.buffer_list.len());
        try t.expectEqual(1, self.perm_arena.state.buffer_list.len());
    }

    {
        // test the case where an allocation fails
        var self = try Self.init(t.allocator);
        defer self.deinit(t.allocator);
        self.perm = t.failing_allocator;

        try t.expectError(error.OutOfMemory, S.check(self));
        try t.expectEqual(0, self.scratch_arena.state.buffer_list.len());
        try t.expectEqual(0, self.perm_arena.state.buffer_list.len());
    }
}
