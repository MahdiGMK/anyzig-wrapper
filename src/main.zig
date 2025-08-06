const std = @import("std");
pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    const alloc = gpa.allocator();
    var args_iter = std.process.args();
    var args = try std.ArrayListUnmanaged([]const u8).initCapacity(alloc, 3);

    const def_zig_ver: ?[]u8 = std.process.getEnvVarOwned(alloc, "ZIG_VERSION") catch null;

    const zon_exist = zon_chk: {
        var dir = std.fs.cwd();
        for (0..6) |_| {
            _ = dir.access("./build.zig.zon", .{}) catch {
                var cur_dir = dir;
                dir = try cur_dir.openDir("..", .{});
                // cur_dir.close();
                continue;
            };
            break :zon_chk true;
        }
        dir.close();
        break :zon_chk false;
    };

    _ = args_iter.next();
    const cmd_zig_ver: ?[:0]const u8 =
        blk: {
            if (args_iter.next()) |arg| {
                _ = std.SemanticVersion.parse(arg) catch {
                    try args.append(alloc, arg);
                    break :blk null;
                };
                break :blk arg;
            }
            break :blk null;
        };

    try args.insert(alloc, 0, "anyzig");
    if (cmd_zig_ver) |zver| {
        try args.insert(alloc, 1, zver);
    } else if (zon_exist) {} else if (def_zig_ver) |zver| {
        try args.insert(alloc, 1, zver);
    }

    while (args_iter.next()) |arg| {
        try args.append(alloc, arg);
    }
    var ch = std.process.Child.init(args.items, alloc);
    _ = try ch.spawnAndWait();
}
