package("jthread", function()
    set_homepage("https://github.com/j0r1/JThread")
    set_description(
        "The JThread package provides some classes to make use of threads easy on different platforms")
    set_license("MIT")

    add_urls("https://github.com/j0r1/JThread.git")

    add_versions("2023.08.18", "719413043807b77448df3ba1c749798fb72ee459")
    add_deps("cmake")

    add_patches("2023.08.18", "patches/2023.08.18/cmakelist.patch",
                "10503405b4bfa2d3e4025d60e950c2f0f207d765af1ac45d9c5572500702e91e")

    add_includedirs("include", "include/jthread")

    on_install("windows", "linux", "macosx", function(package)
        local configs = {}
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" ..
                         (package:is_debug() and "Debug" or "Release"))
        table.insert(configs, "-DJTHREAD_COMPILE_STATIC=" ..
                         (package:config("shared") and "OFF" or "ON"))
        import("package.tools.cmake").install(package, configs)
    end)

    on_test(function(package)
        assert(package:check_cxxsnippets({
            test = [[
            using namespace jthread;
            JMutex* test = new JMutex();
        ]]
        }, {configs = {languages = "c++11"}, includes = "jthread.h"}))
    end)
end)
