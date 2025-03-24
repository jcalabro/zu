//! Zoo is a collection of small utilities that are useful for writing zig programs
//! quickly. Very few (if any) of the data structures here are optimized for writing
//! optimal programs; they exist to help the user write programs quickly and with
//! minimal bugs.

/// An allocator that changes based on build mode
pub const Allocator = @import("Allocator.zig");

/// `Error` carries additional user-friendly error messages that can provide more
/// context on why a particular operation failed.
pub const Error = @import("Error.zig");

/// Defines a unique numeric type that can be used in place of primitive types
pub const Numeric = @import("numeric.zig").Numeric;

/// Namespace containing various string utilities
pub const string = @import("string.zig");

/// Defines an alias for `[]const u8` that is both easier to read and easier to type
pub const String = string.String;

/// A data structure used to do string interning
pub const StringPool = @import("StringPool.zig");

/// Handles conversion of enum and optional types safely
pub const convert = @import("convert.zig");

/// A simple thread-safe Queue. The queue does not assume ownership over memory of
/// its items, so for instance if you're using a `Queue([]const u8)`, be sure to
/// free each slice.
pub const Queue = @import("queue.zig").Queue;

test {
    comptime {
        @import("std").testing.refAllDeclsRecursive(@This());
    }
}
