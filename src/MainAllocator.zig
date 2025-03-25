//! Not actually a bespoke implementation of an Allocator, but a wrapper for the common pattern of using the DebugAllocator in debug builds and the SMPAllocator in release builds.

const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const heap = std.heap;

const Self = @This();

gpa: heap.GeneralPurposeAllocator(.{}),
alloc: Allocator,

/// Initializes the allocator
pub inline fn init() Self {
    var gpa = heap.DebugAllocator(.{}){};
    return Self{
        .gpa = gpa,
        .alloc = switch (builtin.mode) {
            .Debug => gpa.allocator(),
            else => heap.smp_allocator,
        },
    };
}

/// Returns the Allocator interface
pub fn allocator(self: Self) Allocator {
    return self.alloc;
}

/// Checks for leaks in debug builds, and noops in release builds.
pub fn deinit(self: *Self) void {
    defer std.debug.assert(self.gpa.deinit() == .ok);
}
