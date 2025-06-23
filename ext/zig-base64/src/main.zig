const std = @import("std");
const ruby = @cImport({
    @cInclude("ruby.h");
    @cInclude("ruby/encoding.h");
});
const base64 = @import("base64.zig");

/// base64エンコード処理のruby側エントリポイント
fn rb_encode_base64(...) callconv(.C) ruby.VALUE {
    var ap: std.builtin.VaList = @cVaStart(); // ruby側から可変長引数を取る
    defer @cVaEnd(&ap);
    const allocator = std.heap.c_allocator; // c用のアロケーター

    // rubyのCAPIの第一引数はselfだが、今回は使わない
    const self: ruby.VALUE = @cVaArg(&ap, ruby.VALUE);
    _ = self;

    // base64に変換する文字列
    const input: ruby.VALUE = @cVaArg(&ap, ruby.VALUE);
    // 文字列じゃなかったらNilを返す
    if (ruby.TYPE(input) != ruby.T_STRING) {
        return ruby.Qnil;
    }
    const ptr = ruby.RSTRING_PTR(input);
    const len: usize = @intCast(ruby.RSTRING_LEN(input));
    const str = ptr[0..len];

    // 変換処理
    const encoded = base64.Encode_base64(str, allocator) catch return ruby.Qnil;
    const encoded_len: c_long = @intCast(encoded.len);

    // Rubyの文字列に変換
    const result: ruby.VALUE = ruby.rb_str_new(encoded.ptr, encoded_len);
    _ = ruby.rb_enc_associate(result, ruby.rb_utf8_encoding());
    // 安全のために変換後に解放
    allocator.free(encoded);
    return result;
}

export fn Init_libzig_rb() void {
    // ZigRbクラスの登録
    const zig_rb_class: ruby.VALUE = ruby.rb_define_class("ZigRb", ruby.rb_cObject);
    // ZigRb.encode_base64(str)
    _ = ruby.rb_define_method(zig_rb_class, "encode_base64", rb_encode_base64, 1);
}
