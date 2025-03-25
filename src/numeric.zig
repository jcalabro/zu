const std = @import("std");
const t = std.testing;

/// Defines a unique numeric type that can be used in place of primitive types
pub fn Numeric(comptime T: type) type {
    return enum(T) {
        const Self = @This();

        _,

        /// Casts a primitive type to a `Numeric`
        pub fn from(i: @typeInfo(Self).@"enum".tag_type) Self {
            return @enumFromInt(i);
        }

        /// Casts a `Numeric` to a primitive type
        pub fn int(self: Self) @typeInfo(Self).@"enum".tag_type {
            return @intFromEnum(self);
        }

        /// Checks if two `Numerics` are equal
        pub fn eql(a: Self, b: Self) bool {
            return a.int() == b.int();
        }

        /// Checks if the `Numeric` is equal to the primitive
        pub fn eqlInt(a: Self, b: T) bool {
            return a.int() == b;
        }

        /// Checks if two `Numerics` are not equal
        pub fn neq(a: Self, b: Self) bool {
            return a.int() != b.int();
        }

        /// Checks if the `Numeric` is not equal to the primitive
        pub fn neqInt(a: Self, b: T) bool {
            return a.int() != b;
        }

        /// Adds two `Numerics`
        pub fn add(a: Self, b: Self) Self {
            return Self.from(a.int() + b.int());
        }

        /// Adds a `Numeric` with a primitive
        pub fn addInt(a: Self, b: T) Self {
            return Self.from(a.int() + b);
        }

        /// Adds two `Numerics`, returning `null` if the addition overflows
        pub fn addSafe(a: Self, b: Self) ?Self {
            const res = @addWithOverflow(a.int(), b.int());
            if (res[1] == 1) return null;
            return Self.from(res[0]);
        }

        /// Adds a `Numeric` with a primitive, returning `null` if the addition wraps
        pub fn addIntSafe(a: Self, b: T) ?Self {
            const res = @addWithOverflow(a.int(), b);
            if (res[1] == 1) return null;
            return Self.from(res[0]);
        }

        /// Substracts two `Numerics`
        pub fn sub(a: Self, b: Self) Self {
            return Self.from(a.int() - b.int());
        }

        /// Substracts a primitive from a `Numeric`
        pub fn subInt(a: Self, b: T) Self {
            return Self.from(a.int() - b);
        }

        /// Substracts two `Numerics`, returning `null` if the subtraction wraps
        pub fn subSafe(a: Self, b: Self) ?Self {
            const res = @subWithOverflow(a.int(), b.int());
            if (res[1] == 1) return null;
            return Self.from(res[0]);
        }

        /// Substracts a primitive from a `Numeric`, returning `null` if the subtraction wraps
        pub fn subIntSafe(a: Self, b: T) ?Self {
            const res = @subWithOverflow(a.int(), b);
            if (res[1] == 1) return null;
            return Self.from(res[0]);
        }

        /// Performs the modulo of two `Numerics`
        pub fn mod(a: Self, b: Self) Self {
            return Self.from(a.int() % b.int());
        }

        /// Performs the modulo of a `Numeric` and a primitive
        pub fn modInt(a: Self, b: T) Self {
            return Self.from(a.int() % b);
        }

        /// JSON-encodes the given `Numeric` as a primitive
        pub fn jsonStringify(self: *const Self, jw: anytype) !void {
            try jw.write(self.int());
        }

        /// Formats the `Numeric` in to a string as a primitive
        pub fn format(
            self: Self,
            comptime fmt: []const u8,
            _: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = try writer.print("{" ++ fmt ++ "}", .{self.int()});
        }
    };
}

test "Numeric basic operations" {
    const T = Numeric(u8);

    const n = T.from(1);
    try t.expectEqual(T.from(1), n);
    try t.expectEqual(1, n.int());

    try t.expect(n.eql(T.from(1)));
    try t.expect(n.eqlInt(1));

    try t.expect(n.neq(T.from(2)));
    try t.expect(n.neqInt(2));

    try t.expectEqual(T.from(2), n.add(T.from(1)));
    try t.expectEqual(T.from(2), n.addInt(1));

    try t.expectEqual(null, n.addSafe(T.from(255)));
    try t.expectEqual(null, n.addIntSafe(255));

    try t.expectEqual(T.from(0), n.sub(T.from(1)));
    try t.expectEqual(T.from(0), n.subInt(1));

    try t.expectEqual(null, n.subSafe(T.from(2)));
    try t.expectEqual(null, n.subIntSafe(2));

    const n2 = T.from(8);
    try t.expectEqual(T.from(2), n2.mod(T.from(3)));
    try t.expectEqual(T.from(2), n2.modInt(3));
}

test "Numeric json operations" {
    const T = Numeric(u8);
    const S = struct {
        n: T,
    };

    const s = S{ .n = T.from(12) };

    const json = try std.json.stringifyAlloc(t.allocator, s, .{});
    defer t.allocator.free(json);
    try t.expectEqualSlices(u8, "{\"n\":12}", json);

    const res = try std.json.parseFromSlice(S, t.allocator, json, .{});
    defer res.deinit();
    try t.expectEqual(s, res.value);
}

test "Numeric string formatting" {
    const T = Numeric(i8);

    {
        // positive number
        const n = T.from(12);
        const decimal = try std.fmt.allocPrint(t.allocator, "val: {d}", .{n});
        defer t.allocator.free(decimal);
        try t.expectEqualSlices(u8, "val: 12", decimal);

        const hex = try std.fmt.allocPrint(t.allocator, "val: 0x{x}", .{n});
        defer t.allocator.free(hex);
        try t.expectEqualSlices(u8, "val: 0xc", hex);
    }

    {
        // negative number
        const n = T.from(-12);
        const decimal = try std.fmt.allocPrint(t.allocator, "val: {d}", .{n});
        defer t.allocator.free(decimal);
        try t.expectEqualSlices(u8, "val: -12", decimal);
    }
}
