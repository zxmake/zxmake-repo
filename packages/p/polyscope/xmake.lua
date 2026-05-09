package("polyscope", function()

    set_homepage("https://polyscope.run/")
    set_description(
        "A C++ & Python viewer for 3D data like meshes and point clouds")
    set_license("MIT")

    add_urls(
        "https://github.com/nmwsharp/polyscope/archive/refs/tags/$(version).tar.gz",
        "https://github.com/nmwsharp/polyscope.git")
    add_versions("v2.3",
                 "2f57d6d206aa69d277858f046f4db08d27f03c10e97d691a0c3fc9e221a0cd60")
    add_versions("v2.2.1",
                 "1952d20722cb37c5531e88d5b7f5db88c2827c55fd7ada481c2ac425f3bc4d25")
    add_versions("v2.1.0",
                 "bdad2daab33a44b3b6424cec82b43cecb842b529769fd0df3bf7d8e616cea34c")
    add_versions("v1.3.0",
                 "c0d3594b1c818c6e7efe2c2589d71f5e254db383d36a92555aa909a2114f12d4")

    add_patches(">=2.2.1", "patches/v2.2.1/deps.patch",
                "599482137ab5a562e5a43f90fa72593036d5909c475c797da754ad9ba1d78be6")
    add_patches("2.1.0", "patches/v2.1.0/deps.patch",
                "60b76afef7511b283bd9927ae3391bd1dcd2523f2887c286408d8fd4a42db9ad")
    add_patches("1.3.0", "patches/v1.3.0/deps.patch",
                "e4980e12dc7939d62bafc3cd2830a0de727fdf876cc9c441af16624b8019d2a1")
    add_patches("1.3.0", "patches/v1.3.0/imgui.patch",
                "72bf04e2529576d34a2f78d43cbecc8795e952e52ca6e72b7ec7f4bab2516b6c")

    if is_plat("windows") then
        add_configs("shared", {
            description = "Build shared library.",
            default = false,
            type = "boolean",
            readonly = true
        })
    end

    add_deps("cmake")
    add_deps("glad", "glfw", "glm", "nlohmann_json", "stb")
    on_load("windows", "macosx", "linux", function(package)
        if package:version():ge("2.2.0") then
            package:add("deps", "imgui",
                        {configs = {glfw = true, opengl3 = true}})
        else
            package:add("deps", "happly")
            package:add("deps", "imgui <=1.86",
                        {configs = {glfw = true, opengl3 = true}})
        end
        package:add("defines", "GLM_ENABLE_EXPERIMENTAL")
    end)

    on_install("windows", "macosx", "linux", function(package)
        os.cp("deps/stb/stb_impl.cpp", "deps/stb_impl.cpp")
        local configs = {
            "-DPOLYSCOPE_BACKEND_OPENGL_MOCK=OFF",
            "-DPOLYSCOPE_BACKEND_OPENGL3_EGL=OFF"
        }
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" ..
                         (package:debug() and "Debug" or "Release"))
        table.insert(configs, "-DBUILD_SHARED_LIBS=" ..
                         (package:config("shared") and "ON" or "OFF"))
        import("package.tools.cmake").install(package, configs, {
            packagedeps = {
                "imgui", "glad", "glfw", "glm", "happly", "nlohmann_json", "stb"
            }
        })
        if package:version():lt("2.2.0") then
            os.cp("include/polyscope", package:installdir("include"))
        end
    end)

    on_test(function(package)
        assert(package:check_cxxsnippets({
            test = [[
            #include <polyscope/polyscope.h>
            void test() {
                polyscope::init();
                polyscope::show();
            }
        ]]
        }, {configs = {languages = "c++17"}}))
    end)
end)
