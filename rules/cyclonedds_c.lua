rule("cyclonedds_c", function()
    add_deps("c")
    set_extensions(".idl")

    on_config(function(target)
        local sourcebatch = target:sourcebatches()["@cat/cyclonedds_c"]
        for _, sourcefile_idl in ipairs(sourcebatch and sourcebatch.sourcefiles) do
            local rootdir = autogendir and autogendir or
                                path.join(target:autogendir(), "rules",
                                          "cyclonedds")
            local filename = path.basename(sourcefile_idl) .. ".c"
            local sourcefile_c = target:autogenfile(sourcefile_idl, {
                rootdir = rootdir,
                filename = filename
            })
            local sourcefile_dir = path.directory(sourcefile_c)

            -- add includedirs
            target:add("includedirs", rootdir, {public = true})

            -- add objectfile
            local objectfile = target:objectfile(sourcefile_c)
            table.insert(target:objectfiles(), objectfile)
        end
    end)

    on_build_file(function(target, sourcefile, opt) end)

    before_build_files(function(target, batchjobs, sourcebatch, opt)
        import("core.project.config")
        import("core.base.option")

        opt = opt or {}
        local nodes = {}
        local nodenames = {}
        local node_rulename = "rules/" .. sourcebatch.rulename .. "/node"
        local sourcefiles = sourcebatch.sourcefiles

        function get_idlc(target)
            import("lib.detect.find_tool")

            local envs = os.joinenvs(target:pkgenvs(), os.getenvs())
            local idlc = target:data("cyclonedds.idlc")
            if not idlc then
                idlc = find_tool("idlc", {check = "-v"})
                if idlc and idlc.program then
                    target:data_set("cyclonedds.idlc", idlc.program)
                end
            end
            return assert(target:data("cyclonedds.idlc"),
                          "cyclonedds.idlc not found!")
        end

        function buildcmd_idl_files(target, batchcmds, sourcefile_idl, opt)
            local rootdir = autogendir and autogendir or
                                path.join(target:autogendir(), "rules",
                                          "cyclonedds")
            local filename = path.basename(sourcefile_idl) .. ".c"
            local sourcefile_c = target:autogenfile(sourcefile_idl, {
                rootdir = rootdir,
                filename = filename
            })
            local sourcefile_dir = path.directory(sourcefile_c)

            local idlc_args = {"-l", "c", "-o", sourcefile_dir, sourcefile_idl}

            local idlc = get_idlc(target)
            batchcmds:mkdir(sourcefile_dir)
            batchcmds:show_progress(opt.progress,
                                    "${color.build.object}compiling.cyclonedds.idlc %s",
                                    sourcefile_idl)
            batchcmds:vrunv(idlc, idlc_args, {colored_output = true})

            -- add deps
            local depmtime = os.mtime(sourcefile_c)
            batchcmds:add_depfiles(sourcefile_idl)
            batchcmds:set_depcache(target:dependfile(sourcefile_c))
            batchcmds:set_depmtime(depmtime)
        end

        function build_cxfile(target, sourcefile_idl, opt)
            local rootdir = autogendir and autogendir or
                                path.join(target:autogendir(), "rules",
                                          "cyclonedds")
            local filename = path.basename(sourcefile_idl) .. ".c"
            local sourcefile_c = target:autogenfile(sourcefile_idl, {
                rootdir = rootdir,
                filename = filename
            })
            local sourcefile_dir = path.directory(sourcefile_c)
            
            -- add includedirs
            target:add("includedirs", sourcefile_dir, { public = true })

            -- build objectfile
            local objectfile = target:objectfile(sourcefile_c)
            local dependfile = target:dependfile(sourcefile_idl)
            local build_opt = table.join({ objectfile = objectfile, dependfile = dependfile, sourcekind = "cc" }, opt)
            import("private.action.build.object").build_object(target, sourcefile_c, build_opt)
        end

        -- build proto && cx jobs
        for _, sourcefile_idl in ipairs(sourcefiles) do
            local nodename = node_rulename .. "/" .. sourcefile_idl
            nodes[nodename] = {
                name = nodename,
                job = batchjobs:addjob(nodename, function(index, total, jobopt)
                    local batchcmds_ = import("private.utils.batchcmds").new({target = target})
                    -- *.idl ==> *.c
                    buildcmd_idl_files(target, batchcmds_, sourcefile_idl,
                                       {progress = jobopt.progress})
                    batchcmds_:runcmds({
                        changed = target:is_rebuilt(),
                        dryrun = option.get("dry-run")
                    })
                end)
            }
            table.insert(nodenames, nodename)

            local cxfile_nodename = nodename .. "/" .. "cc"
            nodes[cxfile_nodename] = {
                name = cxfile_nodename,
                deps = {nodename},
                job = batchjobs:addjob(cxfile_nodename,
                                       function(index, total, jobopt)
                    -- *.c file ==> object file
                    build_cxfile(target, sourcefile_idl,
                                 {progress = jobopt.progress})
                end)
            }
            table.insert(nodenames, cxfile_nodename)
        end
        import("private.async").buildjobs(nodes, batchjobs, opt.rootjob)
    end, {batch = true})
end)
