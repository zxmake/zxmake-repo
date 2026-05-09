package("webdriverxx", function()
    set_kind("library", {headeronly = true})
    set_homepage("https://GermanAizek.github.io/webdriverxx")
    set_description("A C++ client library for Selenium Webdriver")
    set_license("MIT")

    add_urls("https://github.com/GermanAizek/webdriverxx.git",
             {submodules = false})
    add_versions("2023.04.22", "b8c9ac36360021daca7b0fd006a092b605b19e29")

    add_patches("2023.04.22", "patches/2023.04.22/picojson.patch",
                "d539deee0ebfbd3f46e9f9550ec23f8c67da503465d35f23c6c3c2e7ec522f25")
    add_patches("2023.04.22", "patches/2023.04.22/fix_cxx23.patch",
                "a07d9498eb678634ecdef0732cab6bec5bc8e3f60b4bcfce0bc295b8bdd16229")

    add_deps("libcurl", "picojson")

    on_install("!bsd and !wasm", function(package)
        os.rm("include/webdriverxx/picojson.h")
        os.cp("include/webdriverxx.h", package:installdir("include"))
        os.cp("include/webdriverxx", package:installdir("include"))
    end)

    on_test(function(package)
        assert(package:check_cxxsnippets({
            test = [[
            #include <webdriverxx.h>
            using namespace webdriverxx;
            void test() {
                WebDriver chrome = Start(Chrome());
            }
        ]]
        }, {configs = {languages = "c++17"}}))
    end)
end)
