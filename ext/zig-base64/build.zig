const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addSharedLibrary(.{ .name = "zig_rb", .root_source_file = b.path("src/main.zig"), .version = .{ .major = 0, .minor = 0, .patch = 1 }, .optimize = optimize, .target = target });

    //Ruby Header Linkage
    const ruby_libdir = std.posix.getenv("RUBY_LIBDIR") orelse "";
    lib.addIncludePath(std.Build.LazyPath{ .cwd_relative = ruby_libdir });
    const ruby_hdrdir = std.posix.getenv("RUBY_HDRDIR") orelse "";
    lib.addIncludePath(std.Build.LazyPath{ .cwd_relative = ruby_hdrdir });
    const ruby_archhdrdir = std.posix.getenv("RUBY_ARCHHDRDIR") orelse "";
    lib.addIncludePath(std.Build.LazyPath{ .cwd_relative = ruby_archhdrdir });

    lib.linkSystemLibrary("c");
    b.installArtifact(lib);
}
