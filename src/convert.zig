//! Handles conversion of enum and optional types safely

const std = @import("std");
const t = std.testing;

const Error = @import("Error.zig");

/// The error returned when converting to/from enum and optional types fails
pub const ConversionError = error{
    UnexpectedEnumValue,
    UnexpectedOptionalValue,
};

/// Safely converts an int to the enum of type `T`. If there is no appropriate value
/// for the given integer, `err` will be set, and caller owns its memory.
pub fn enumFromInt(comptime T: anytype, err: *Error, val: anytype) ConversionError!T {
    return inline for (@typeInfo(T).@"enum".fields) |f| {
        if (val == f.value) break @enumFromInt(f.value);
    } else {
        err.set("unexpected " ++ @typeName(T) ++ " enum value: 0x{x}", .{val}) catch err.clear();
        return error.UnexpectedEnumValue;
    };
}

test "enumFromInt" {
    const MyEnum = enum(u8) { one, two, three };

    var err = Error.init(t.allocator);
    defer err.deinit();

    try t.expectEqual(MyEnum.one, try enumFromInt(MyEnum, &err, @intFromEnum(MyEnum.one)));
    try t.expectEqual(MyEnum.two, try enumFromInt(MyEnum, &err, @intFromEnum(MyEnum.two)));
    try t.expectEqual(MyEnum.three, try enumFromInt(MyEnum, &err, @intFromEnum(MyEnum.three)));

    try t.expectEqual(error.UnexpectedEnumValue, enumFromInt(MyEnum, &err, 3));
    try t.expect(err.message != null);
    try t.expectEqual(error.UnexpectedEnumValue, enumFromInt(MyEnum, &err, 4));
    try t.expect(err.message != null);
    try t.expectEqual(error.UnexpectedEnumValue, enumFromInt(MyEnum, &err, 1000));
    try t.expect(err.message != null);
    try t.expectEqual(error.UnexpectedEnumValue, enumFromInt(MyEnum, &err, -1));
    try t.expect(err.message != null);
    try t.expectEqualSlices(
        u8,
        "unexpected convert.test.enumFromInt.MyEnum enum value: 0x-1",
        err.message.?,
    );
}

/// Safely returns the value contained in the optional, or an error otherwise
pub fn optional(comptime T: type, opt: ?T) error{UnexpectedOptional}!T {
    if (opt) |o| return o;
    return error.UnexpectedOptional;
}

test "optional" {
    var item: ?i32 = null;
    try t.expectError(error.UnexpectedOptional, optional(i32, item));

    item = 123;
    try t.expectEqual(item.?, try optional(i32, item));
}
