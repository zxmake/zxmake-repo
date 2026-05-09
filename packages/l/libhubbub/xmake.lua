package("libhubbub", function()
    set_homepage("https://www.netsurf-browser.org/projects/libhubbub")
    set_description("Hubbub is an HTML5 compliant parsing library")
    set_license("MIT")

    set_urls(
        "https://source.netsurf-browser.org/libhubbub.git/snapshot/libhubbub-release/$(version).tar.bz2",
        "https://git.netsurf-browser.org/libhubbub.git")

    add_versions("0.3.8",
                 "570f2aef99071e0c24d16444b74884d611f46b264bbfb6e314039c9786e87160")

    add_patches("0.3.8", "patches/0.3.8/treebuilder.patch",
                "143efc05f6665c8d07fced47fdd7bc3e035ecf015710cc800ff9a5ac13f8a482")

    add_deps("libparserutils")
    if is_plat("windows") then
        add_deps("strings_h", {private = true})
    end

    on_load(function(package)
        if not package:is_precompiled() then
            package:add("deps", "gperf")
            if is_subhost("windows") then
                package:add("deps", "strawberry-perl")
            end
        end
    end)

    on_install(function(package)
        os.cd(package:version_str())
        os.cp(path.join(package:scriptdir(), "port", "xmake.lua"), "xmake.lua")
        import("package.tools.xmake").install(package)
    end)

    on_test(function(package)
        assert(package:has_cfuncs("hubbub_error_to_string",
                                  {includes = "hubbub/hubbub.h"}))
    end)
end)
