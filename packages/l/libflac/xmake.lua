package("libflac", function()
    set_homepage("https://xiph.org/flac")
    set_description("Free Lossless Audio Codec")
    set_license("BSD")

    set_urls("https://github.com/xiph/flac/archive/$(version).tar.gz",
             "https://github.com/xiph/flac.git")

    add_versions("1.4.3",
                 "0a4bb82a30609b606650d538a804a7b40205366ce8fc98871b0ecf3fbb0611ee")
    add_versions("1.4.2",
                 "8e8e0406fb9e1d177bb4ba8cfed3ca3935d37144eac8f0219a03e8c1ed5cc18e")
    add_versions("1.3.3",
                 "668cdeab898a7dd43cf84739f7e1f3ed6b35ece2ef9968a5c7079fe9adfe1689")
    add_patches("1.4.3", "patches/1.4.2/cmake.patch",
                "29c46028e03c78f4a04aa878bfc3e0f4dda8dda41aba56bc909c307daec7ac32")
    add_patches("1.4.2", "patches/1.4.2/cmake.patch",
                "29c46028e03c78f4a04aa878bfc3e0f4dda8dda41aba56bc909c307daec7ac32")
    add_patches("1.3.3", "patches/1.3.3/cmake.patch",
                "b1ee9b071e330b90e50f7a6801963c7f1d40c99ce7d631dc13a928d35590095c")

    if is_plat("mingw") and is_subhost("msys") then
        add_extsources("pacman::flac")
    elseif is_plat("linux") then
        add_extsources("pacman::flac", "apt::libflac++-dev", "apt::libflac-dev")
    elseif is_plat("macosx") then
        add_extsources("brew::flac")
    end

    add_deps("cmake", "libogg")

    if is_plat("linux") then
        add_syslinks("m")
    end

    on_load("windows", "mingw", function(package)
        if not package:config("shared") then
            package:add("defines", "FLAC__NO_DLL")
        end
    end)

    on_install("windows", "linux", "macosx", "iphoneos", "mingw", "android",
               "wasm", function(package)

        local configs = {}
        table.insert(configs, "-DBUILD_CXXLIBS=OFF")
        table.insert(configs, "-DBUILD_DOCS=OFF")
        table.insert(configs, "-DBUILD_PROGRAMS=OFF")
        table.insert(configs, "-DBUILD_EXAMPLES=OFF")
        table.insert(configs, "-DBUILD_TESTING=OFF")
        table.insert(configs, "-DBUILD_UTILS=OFF")
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" ..
                         (package:debug() and "Debug" or "Release"))
        table.insert(configs, "-DBUILD_SHARED_LIBS=" ..
                         (package:config("shared") and "ON" or "OFF"))
        table.insert(configs, "-DCMAKE_POSITION_INDEPENDENT_CODE=ON")
        table.insert(configs, "-DINSTALL_MANPAGES=OFF")
        if package:is_plat("wasm") then
            -- wasm doesn't support stack protector
            table.insert(configs, "-DWITH_STACK_PROTECTOR=OFF")
        end

        -- fix, undefined reference to `__memset_chk'
        -- @see https://github.com/msys2/MINGW-packages/issues/5803
        if package:config("shared") and package:is_plat("mingw") then
            io.replace("CMakeLists.txt", "add_definitions(-DHAVE_CONFIG_H)",
                       "add_definitions(-DHAVE_CONFIG_H -D_FORTIFY_SOURCE=0)",
                       {plain = true})
        end

        -- we pass libogg as packagedeps instead of findOgg.cmake (it does not work)
        local libogg = package:dep("libogg"):fetch()
        if libogg then
            local links = table.concat(table.wrap(libogg.links), " ")
            io.replace("CMakeLists.txt", "find_package(OGG REQUIRED)", "",
                       {plain = true}) -- v1.3.3
            io.replace("CMakeLists.txt", "find_package(Ogg REQUIRED)", "",
                       {plain = true}) -- v1.3.4+
            io.replace("src/libFLAC/CMakeLists.txt", [[
if(TARGET Ogg::ogg)
    target_link_libraries(FLAC PUBLIC Ogg::ogg)
endif()]], "target_link_libraries(FLAC PUBLIC " .. links .. ")", {plain = true})
        end
        import("package.tools.cmake").install(package, configs,
                                              {packagedeps = "libogg"})
    end)

    on_test(function(package)
        assert(package:has_cfuncs("FLAC__format_sample_rate_is_valid",
                                  {includes = "FLAC/format.h"}))
    end)
end)
