package("autotools", function()
    set_kind("binary")

    if is_subhost("msys") then
        add_deps("pacman::autotools")
    else
        add_deps("autoconf", "automake", "libtool")
    end

    on_install("@linux", "@macosx", "@bsd", "@msys", function(package)
    end)
end)
