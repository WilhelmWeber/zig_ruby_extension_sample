const std = @import("std");
const testing = std.testing;

const SplitedBin = struct {
    main: u6,
    extra: u6,
};

/// u8を分割して二つのu6を返す
fn Split_u8_to_u6(bin: u8, i: usize) SplitedBin {
    const mod: usize = i % 3;

    //分割軸の決定
    var shift: u3 = 0;
    if (mod == 0 or mod == 3) {
        shift = 2;
    } else if (mod == 1) {
        shift = 4;
    } else if (mod == 2) {
        shift = 6;
    }

    //shiftで分割した上位ビット
    const main_bit: u6 = @intCast(bin >> shift);

    //shiftで分割した下位ビット
    const mask: u8 = switch (shift) {
        2 => 0b00000011,
        4 => 0b00001111,
        6 => 0b00111111,
        else => unreachable,
    };
    const extra_bit: u6 = @intCast(bin & mask);

    return SplitedBin{ .main = main_bit, .extra = extra_bit };
}

/// u8スライスを受け取り、バイナリを6分割して、u6スライスを返す
fn Make_u6_slice_from_u8_slice(array: []const u8, allocator: std.mem.Allocator) ![]u6 {
    var result_array = std.ArrayList(u6).init(allocator);
    var extra: u6 = 0;
    var i: usize = 0;
    for (array) |bin| {
        const mod: usize = i % 3;
        const splited = Split_u8_to_u6(bin, i);
        switch (mod) {
            0 => {
                // mainをそのままスライスに登録し、extraに代入
                try result_array.append(splited.main);
                extra = splited.extra;
            },
            1 => {
                // extraを左に4bitシフトし、mainと足し算したものをスライスに
                // extraには普通に代入
                const result: u6 = (extra << 4) + splited.main;
                try result_array.append(result);
                extra = splited.extra;
            },
            2 => {
                // extraを左に2bitシフトし、mainと足し算したものをスライスに
                // 今自分が持っているextraも既に6bitなので、そのままスライスに登録
                // extraは0にしておく
                const result: u6 = (extra << 2) + splited.main;
                try result_array.append(result);
                try result_array.append(splited.extra);
                extra = 0;
            },
            else => unreachable,
        }
        i = i + 1;
    }
    //余ったextraをsliceにappendする
    const last_i_mod: usize = i % 3;
    switch (last_i_mod) {
        0 => {},
        1 => try result_array.append(extra << 4),
        2 => try result_array.append(extra << 2),
        else => unreachable,
    }

    //need to free at entry point
    return try result_array.toOwnedSlice();
}

/// 変換対応をもとに、u6の列を文字列に変換
fn Convert_u6_to_char(array: []u6, allocator: std.mem.Allocator) ![]u8 {
    const BASE64_CHAR: []const u8 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    var result = std.ArrayList(u8).init(allocator);

    for (array) |bin| {
        const val = BASE64_CHAR[bin];
        try result.append(val);
    }

    //4つに分けて足りない分だけ、=を追加
    const mod: usize = array.len % 4;
    switch (mod) {
        0 => {},
        1...3 => {
            for (0..(4 - mod)) |_| {
                try result.append('=');
            }
        },
        else => unreachable,
    }

    // need to free at entry point;
    return try result.toOwnedSlice();
}

/// Base64エンコード処理のzig側エントリポイント
pub fn Encode_base64(array: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const u6_array = try Make_u6_slice_from_u8_slice(array, allocator);
    //もうこのスコープ内でしかu6_arrayは使わないので、解放
    defer allocator.free(u6_array);

    const result = try Convert_u6_to_char(u6_array, allocator);
    return result;
}

test "split_u8_to_u6" {
    try testing.expectEqual(Split_u8_to_u6(178, 0), SplitedBin{ .main = 44, .extra = 2 });
    try testing.expectEqual(Split_u8_to_u6(178, 1), SplitedBin{ .main = 11, .extra = 2 });
    try testing.expectEqual(Split_u8_to_u6(178, 2), SplitedBin{ .main = 2, .extra = 50 });
}

test "u8_slice_to_u6_slice" {
    const target_1: []const u8 = "abcdefg";
    const _answer = [10]u6{ 24, 22, 9, 35, 25, 6, 21, 38, 25, 48 };
    const answer = _answer[0..];
    const result_slice = try Make_u6_slice_from_u8_slice(target_1, testing.allocator);
    defer testing.allocator.free(result_slice);

    try testing.expectEqualSlices(u6, answer, result_slice);
}

test "u6_slice_to_char_slice" {
    const target: []const u8 = "abcdefg";
    const answer: []const u8 = "YWJjZGVmZw==";

    const u6_array = try Make_u6_slice_from_u8_slice(target, testing.allocator);
    defer testing.allocator.free(u6_array);
    const result: []const u8 = try Convert_u6_to_char(u6_array, testing.allocator);
    defer testing.allocator.free(result);

    try testing.expectEqualStrings(answer, result);
}
