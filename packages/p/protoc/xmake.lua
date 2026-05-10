package("protoc", function()

    set_kind("binary")
    set_homepage("https://developers.google.com/protocol-buffers/")
    set_description("Google's data interchange format compiler")

    if is_host("macosx") then
        if is_arch("x86_64") then
            add_urls(
                "https://github.com/protocolbuffers/protobuf/releases/download/v$(version)/protoc-$(version)-osx-x86_64.zip")
            add_versions("3.8.0",
                         "8093a79ca6f22bd9b178cc457a3cf44945c088f162e237b075584f6851ca316c")
        else
            add_urls(
                "https://github.com/protocolbuffers/protobuf/releases/download/v$(version)/protoc-$(version)-osx-x86_32.zip")
            add_versions("3.8.0",
                         "14376f58d19a7579c43ee95d9f87ed383391d695d4968107f02ed226c13448ae")
        end
    else
        add_urls(
            "https://github.com/protocolbuffers/protobuf/releases/download/v$(version)/protoc-$(version)-linux-x86_64.zip")
    end

    on_install("@linux", "@macosx", function(package)
        os.cp("bin", package:installdir())
        os.cp("include", package:installdir())
    end)

    on_test(function(package)
        io.writefile("test.proto", [[
            syntax = "proto3";
            package test;
            message TestCase {
                string name = 4;
            }
            message Test {
                repeated TestCase case = 1;
            }
        ]])
        os.vrun("protoc test.proto --cpp_out=.")
    end)
end)
