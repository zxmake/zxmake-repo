package("enet", function()
    set_homepage("http://enet.bespin.org")
    set_description("Reliable UDP networking library.")
    set_license("MIT")

    add_urls(
        "https://github.com/lsalzman/enet/archive/refs/tags/$(version).tar.gz",
        "https://github.com/lsalzman/enet.git")

    add_versions("v1.3.18",
                 "28603c895f9ed24a846478180ee72c7376b39b4bb1287b73877e5eae7d96b0dd")
    add_versions("v1.3.17",
                 "1e0b4bc0b7127a2d779dd7928f0b31830f5b3dcb7ec9588c5de70033e8d2434a")

    add_patches("v1.3.18", "patches/v1.3.18/cmake.patch",
                "e9e1c2b44eb9d3bf5f1a764265d08020664cc9ec10275dc8d5c6292bc4fbb252")
    add_patches("v1.3.17", "patches/v1.3.17/cmake.patch",
                "981daf3eb48cd00363d16fb558b944474a5b30dea7ba7cf02ddf0382d9aec350")

    if is_plat("mingw") and is_subhost("msys") then
        add_extsources("pacman::enet")
    elseif is_plat("linux") then
        add_extsources("pacman::enet", "apt::libenet-dev")
    elseif is_plat("macosx") then
        add_extsources("brew::enet")
    end

    add_deps("cmake")

    if is_plat("windows", "mingw") then
        add_syslinks("winmm", "ws2_32")
    end

    on_load("windows", "mingw", function(package)
        if package:config("shared") then
            package:add("defines", "ENET_DLL")
        end
    end)

    on_install(function(package)
        local configs = {}
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" ..
                         (package:debug() and "Debug" or "Release"))
        table.insert(configs, "-DBUILD_SHARED_LIBS=" ..
                         (package:config("shared") and "ON" or "OFF"))
        import("package.tools.cmake").install(package, configs)
    end)

    on_test(function(package)
        assert(package:has_cfuncs("enet_initialize", {includes = "enet/enet.h"}))
    end)
end)
