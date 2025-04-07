rule("protobuf_cpp", function()
    add_deps("c++")
    add_deps("@cat/set_protoc_binary")

    set_extensions(".proto")

    on_config(function(target)
        -- get proto source file
        local sourcebatch = target:sourcebatches()["@cat/protobuf_cpp"]
        if sourcebatch then sourcefile_proto = sourcebatch.sourcefiles[1] end
        if not sourcefile_proto then return end

        -- get c++ source file for protobuf
        local fileconfig = target:fileconfig(sourcefile_proto)
        if fileconfig then
            public = fileconfig.proto_public
            prefixdir = fileconfig.proto_rootdir
            autogendir = fileconfig.proto_autogendir
        end
        local rootdir = autogendir and autogendir or
                            path.join(target:autogendir(), "rules", "protobuf")
        local filename = path.basename(sourcefile_proto) .. ".pb.cc"
        local sourcefile_cx = target:autogenfile(
                                  path.relative(sourcefile_proto, prefixdir),
                                  {rootdir = rootdir, filename = filename})
        local sourcefile_dir = prefixdir and rootdir or
                                   path.directory(sourcefile_cx)

        -- add includedirs
        target:add("includedirs", sourcefile_dir, {public = public})
        -- cprint("${blue}rule@cat/protobuf_cpp load success")
    end)

    before_buildcmd_file(function(target, batchcmds, sourcefile_proto, opt)
        function get_grpc_cpp_plugin(target, sourcekind)
            assert(sourcekind == "cxx", "grpc_cpp_plugin only support c++")
            local grpc_cpp_plugin = import("lib.detect").find_tool(
                                        "grpc_cpp_plugin", {
                    norun = true,
                    force = true,
                    envs = target:pkgenvs("protobuf")
                })
            return assert(grpc_cpp_plugin and grpc_cpp_plugin.program,
                          "grpc_cpp_plugin not found!")
        end

        -- protoc binary
        function get_protoc(target)
            return assert(target:data("protobuf.protoc"), "protoc not found!")
        end
        local_protoc = get_protoc(target)

        -- protoc args
        local prefixdir
        local autogendir
        local public
        local grpc_cpp_plugin
        local extra_flags
        local fileconfig = target:fileconfig(sourcefile_proto)
        if fileconfig then
            public = fileconfig.proto_public
            prefixdir = fileconfig.proto_rootdir
            autogendir = fileconfig.proto_autogendir
            grpc_cpp_plugin = fileconfig.proto_grpc_cpp_plugin
            extra_flags = fileconfig.extra_flags
        end
        local rootdir = autogendir and autogendir or
                            path.join(target:autogendir(), "rules", "protobuf")
        local filename = path.basename(sourcefile_proto) .. ".pb.cc"
        local sourcefile_cx = target:autogenfile(
                                  path.relative(sourcefile_proto, prefixdir),
                                  {rootdir = rootdir, filename = filename})
        local sourcefile_dir = prefixdir and rootdir or
                                   path.directory(sourcefile_cx)

        local grpc_cpp_plugin_bin
        local filename_grpc
        local sourcefile_cx_grpc
        if grpc_cpp_plugin then
            grpc_cpp_plugin_bin = get_grpc_cpp_plugin(target, "cxx")
            filename_grpc = path.basename(sourcefile_proto) .. ".grpc.pb.cc"
            sourcefile_cx_grpc = target:autogenfile(path.relative(
                                                        sourcefile_proto,
                                                        prefixdir), {
                rootdir = rootdir,
                filename = filename_grpc
            })
        end
        local protoc_args = {
            path(path.relative(sourcefile_proto, prefixdir)),
            path(prefixdir and prefixdir or path.directory(sourcefile_proto),
                 function(p) return "-I" .. p end),
            path(sourcefile_dir, function(p) return "--cpp_out=" .. p end)
        }
        if extra_flags then
            if type(extra_flags) == "string" then
                table.insert(protoc_args, extra_flags)
            elseif type(extra_flags) == "table" then
                for _, v in pairs(extra_flags) do
                    table.insert(protoc_args, v)
                end
            end
        end

        if grpc_cpp_plugin then
            table.insert(protoc_args,
                         "--plugin=protoc-gen-grpc=" .. grpc_cpp_plugin_bin)
            table.insert(protoc_args, path(sourcefile_dir, function(p)
                return ("--grpc_out=") .. p
            end))
        end

        -- add commands
        batchcmds:mkdir(sourcefile_dir)
        batchcmds:show_progress(opt.progress,
                                "${color.build.object}compiling.proto.%s %s",
                                "c++", sourcefile_proto)
        batchcmds:vrunv(protoc, protoc_args)

        local depmtime = os.mtime(sourcefile_cx)
        batchcmds:add_depfiles(sourcefile_proto)
        batchcmds:set_depcache(target:dependfile(sourcefile_cx))
        if grpc_cpp_plugin then
            batchcmds:set_depmtime(math.max(os.mtime(sourcefile_cx_grpc),
                                            depmtime))
        else
            batchcmds:set_depmtime(depmtime)
        end
        -- cprint("${blue}rule@cat/protobuf_cpp before_buildcmd_file success")
    end)

    on_buildcmd_file(function(target, batchcmds, sourcefile_proto, opt)
        local sourcekind = "cxx"

        -- protoc binary
        function get_protoc(target)
            return assert(target:data("protobuf.protoc"), "protoc not found!")
        end
        local_protoc = get_protoc(target)

        -- get c/c++ source file for protobuf
        local prefixdir
        local autogendir
        local public
        local grpc_cpp_plugin
        local fileconfig = target:fileconfig(sourcefile_proto)

        if fileconfig then
            public = fileconfig.proto_public
            prefixdir = fileconfig.proto_rootdir
            -- custom autogen directory to access the generated header files
            -- @see https://github.com/xmake-io/xmake/issues/3678
            autogendir = fileconfig.proto_autogendir
            grpc_cpp_plugin = fileconfig.proto_grpc_cpp_plugin
        end
        local rootdir = autogendir and autogendir or
                            path.join(target:autogendir(), "rules", "protobuf")
        local filename = path.basename(sourcefile_proto) .. ".pb" ..
                             (sourcekind == "cxx" and ".cc" or "-c.c")
        local sourcefile_cx = target:autogenfile(
                                  path.relative(sourcefile_proto, prefixdir),
                                  {rootdir = rootdir, filename = filename})
        local sourcefile_dir = prefixdir and rootdir or
                                   path.directory(sourcefile_cx)
        local grpc_cpp_plugin_bin
        local filename_grpc
        local sourcefile_cx_grpc
        if grpc_cpp_plugin then
            grpc_cpp_plugin_bin = _get_grpc_cpp_plugin(target, sourcekind)
            filename_grpc = path.basename(sourcefile_proto) .. ".grpc.pb.cc"
            sourcefile_cx_grpc = target:autogenfile(path.relative(
                                                        sourcefile_proto,
                                                        prefixdir), {
                rootdir = rootdir,
                filename = filename_grpc
            })
        end

        -- add includedirs
        target:add("includedirs", sourcefile_dir, {public = public})

        -- add objectfile
        local objectfile = target:objectfile(sourcefile_cx)
        table.insert(target:objectfiles(), objectfile)

        local objectfile_grpc
        if grpc_cpp_plugin then
            objectfile_grpc = target:objectfile(sourcefile_cx_grpc)
            table.insert(target:objectfiles(), objectfile_grpc)
        end

        batchcmds:show_progress(opt.progress,
                                "${color.build.object}compiling.proto.$(mode) %s",
                                sourcefile_cx)
        batchcmds:compile(sourcefile_cx, objectfile,
                          {configs = {includedirs = sourcefile_dir}})
        if grpc_cpp_plugin then
            batchcmds:compile(sourcefile_cx_grpc, objectfile_grpc,
                              {configs = {includedirs = sourcefile_dir}})
        end

        -- add deps
        local depmtime = os.mtime(objectfile)
        batchcmds:add_depfiles(sourcefile_proto)
        batchcmds:set_depcache(target:dependfile(objectfile))
        if grpc_cpp_plugin then
            batchcmds:set_depmtime(math.max(os.mtime(objectfile_grpc), depmtime))
        else
            batchcmds:set_depmtime(depmtime)
        end
        -- cprint("${blue}rule@cat/protobuf_cpp on_buildcmd_file success")
    end)

    before_build_files(function(target, batchjobs, sourcebatch, opt)
        import("private.action.build.object", {alias = "build_objectfiles"})

        function buildcmd_pfiles(target, batchcmds, sourcefile_proto, opt,
                                 sourcekind)
            -- get protoc
            function get_protoc(target)
                return assert(target:data("protobuf.protoc"),
                              "protoc not found!")
            end
            local protoc = get_protoc(target, sourcekind)

            -- get c/c++ source file for protobuf
            local prefixdir
            local autogendir
            local public
            local grpc_cpp_plugin
            local extra_flags
            local fileconfig = target:fileconfig(sourcefile_proto)
            if fileconfig then
                public = fileconfig.proto_public
                prefixdir = fileconfig.proto_rootdir
                -- custom autogen directory to access the generated header files
                -- @see https://github.com/xmake-io/xmake/issues/3678
                autogendir = fileconfig.proto_autogendir
                grpc_cpp_plugin = fileconfig.proto_grpc_cpp_plugin
                extra_flags = fileconfig.extra_flags
            end
            local rootdir = autogendir and autogendir or
                                path.join(target:autogendir(), "rules",
                                          "protobuf")
            local filename = path.basename(sourcefile_proto) .. ".pb" ..
                                 (sourcekind == "cxx" and ".cc" or "-c.c")
            local sourcefile_cx = target:autogenfile(path.relative(
                                                         sourcefile_proto,
                                                         prefixdir), {
                rootdir = rootdir,
                filename = filename
            })

            local sourcefile_dir = prefixdir and rootdir or
                                       path.directory(sourcefile_cx)

            local grpc_cpp_plugin_bin
            local filename_grpc
            local sourcefile_cx_grpc
            if grpc_cpp_plugin then
                grpc_cpp_plugin_bin = _get_grpc_cpp_plugin(target, sourcekind)
                filename_grpc = path.basename(sourcefile_proto) .. ".grpc.pb.cc"
                sourcefile_cx_grpc = target:autogenfile(path.relative(
                                                            sourcefile_proto,
                                                            prefixdir), {
                    rootdir = rootdir,
                    filename = filename_grpc
                })
            end

            local protoc_args = {
                path(path.relative(sourcefile_proto, prefixdir)),
                path(
                    prefixdir and prefixdir or path.directory(sourcefile_proto),
                    function(p) return "-I" .. p end), path(rootdir, function(p)
                    return
                        (sourcekind == "cxx" and "--cpp_out=" or "--c_out=") ..
                            p
                end)
            }
            if extra_flags then
                if type(extra_flags) == "string" then
                    table.insert(protoc_args, extra_flags)
                elseif type(extra_flags) == "table" then
                    for _, v in pairs(extra_flags) do
                        table.insert(protoc_args, v)
                    end
                end
            end

            if grpc_cpp_plugin then
                local extension = target:is_plat("windows") and ".exe" or ""
                table.insert(protoc_args, "--plugin=protoc-gen-grpc=" ..
                                 grpc_cpp_plugin_bin .. extension)
                table.insert(protoc_args, path(sourcefile_dir, function(p)
                    return ("--grpc_out=") .. p
                end))
            end

            -- print("proto args:")
            -- print(protoc_args)

            -- add commands
            batchcmds:mkdir(sourcefile_dir)
            batchcmds:show_progress(opt.progress,
                                    "${color.build.object}compiling.proto.%s %s",
                                    (sourcekind == "cxx" and "c++" or "c"),
                                    sourcefile_proto)
            batchcmds:vrunv(protoc, protoc_args)

            -- add deps
            local depmtime = os.mtime(sourcefile_cx)
            batchcmds:add_depfiles(sourcefile_proto)
            batchcmds:set_depcache(target:dependfile(sourcefile_cx))
            if grpc_cpp_plugin then
                batchcmds:set_depmtime(math.max(os.mtime(sourcefile_cx_grpc),
                                                depmtime))
            else
                batchcmds:set_depmtime(depmtime)
            end
        end

        function build_cxfile_objects(target, batchjobs, opt, sourcekind)
            -- do build
            local sourcebatch_cx = {
                rulename = (sourcekind == "cxx" and "c++" or "c") .. ".build",
                sourcekind = sourcekind,
                sourcefiles = {},
                objectfiles = {},
                dependfiles = {}
            }
            for _, sourcefile_proto in ipairs(sourcefiles) do
                -- get c/c++ source file for protobuf
                local prefixdir
                local autogendir
                local public
                local grpc_cpp_plugin
                local fileconfig = target:fileconfig(sourcefile_proto)
                if fileconfig then
                    public = fileconfig.proto_public
                    prefixdir = fileconfig.proto_rootdir
                    -- custom autogen directory to access the generated header files
                    -- @see https://github.com/xmake-io/xmake/issues/3678
                    autogendir = fileconfig.proto_autogendir
                    grpc_cpp_plugin = fileconfig.proto_grpc_cpp_plugin
                end
                local rootdir = autogendir and autogendir or
                                    path.join(target:autogendir(), "rules",
                                              "protobuf")
                local filename = path.basename(sourcefile_proto) .. ".pb" ..
                                     (sourcekind == "cxx" and ".cc" or "-c.c")
                local sourcefile_cx = target:autogenfile(path.relative(
                                                             sourcefile_proto,
                                                             prefixdir), {
                    rootdir = rootdir,
                    filename = filename
                })
                local sourcefile_dir = prefixdir and rootdir or
                                           path.directory(sourcefile_cx)

                local grpc_cpp_plugin_bin
                local filename_grpc
                local sourcefile_cx_grpc
                if grpc_cpp_plugin then
                    grpc_cpp_plugin_bin =
                        _get_grpc_cpp_plugin(target, sourcekind)
                    filename_grpc = path.basename(sourcefile_proto) ..
                                        ".grpc.pb.cc"
                    sourcefile_cx_grpc =
                        target:autogenfile(path.relative(sourcefile_proto,
                                                         prefixdir), {
                            rootdir = rootdir,
                            filename = filename_grpc
                        })
                end

                -- add includedirs
                target:add("includedirs", sourcefile_dir, {public = public})

                -- add objectfile
                local objectfile = target:objectfile(sourcefile_cx)
                local dependfile = target:dependfile(sourcefile_proto)
                table.insert(sourcebatch_cx.sourcefiles, sourcefile_cx)
                table.insert(sourcebatch_cx.objectfiles, objectfile)
                table.insert(sourcebatch_cx.dependfiles, dependfile)

                local objectfile_grpc
                if grpc_cpp_plugin then
                    objectfile_grpc = target:objectfile(sourcefile_cx_grpc)
                    table.insert(sourcebatch_cx.sourcefiles, sourcefile_cx_grpc)
                    table.insert(sourcebatch_cx.objectfiles, objectfile_grpc)
                    table.insert(sourcebatch_cx.dependfiles, dependfile)
                end
            end
            build_objectfiles(target, batchjobs, sourcebatch_cx, opt)
        end

        -- import("proto").build_cxfiles(target, batchjobs, sourcebatch, opt, "cxx")
        local sourcekind = "cxx"

        opt = opt or {}
        local nodes = {}
        local nodenames = {}
        local node_rulename = "rules/" .. sourcebatch.rulename .. "/node"
        local sourcefiles = sourcebatch.sourcefiles
        for _, sourcefile_proto in ipairs(sourcefiles) do
            local nodename = node_rulename .. "/" .. sourcefile_proto
            nodes[nodename] = {
                name = nodename,
                job = batchjobs:addjob(nodename, function(index, total)
                    local batchcmds_ = import("private.utils.batchcmds").new({
                        target = target
                    })
                    buildcmd_pfiles(target, batchcmds_, sourcefile_proto,
                                    {progress = (index * 100) / total},
                                    sourcekind)
                    batchcmds_:runcmds({
                        changed = target:is_rebuilt(),
                        dryrun = import("core.base").option.get("dry-run")
                    })
                end)
            }
            table.insert(nodenames, nodename)
        end
        local rootname = "rules/" .. sourcebatch.rulename .. "/root"
        nodes[rootname] = {
            name = rootname,
            deps = nodenames,
            job = batchjobs:addjob(rootname, function(_index, _total)
                build_cxfile_objects(target, batchjobs, opt, sourcekind)
            end)
        }
        import("private.async").buildjobs(nodes, batchjobs, opt.rootjob)
    end, {batch = true})
end)
