$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require "zig-base64"

zig = ZigRb.new
puts zig.encode_base64("abcdefgh")