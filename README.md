# ZXMake Repo

## 简介

xmake-repo 是一个官方的 xmake 包管理仓库，收录了常用的 c/c++ 开发包，提供跨平台支持。

## 包依赖描述

```lua
add_requires("zlib", "libtask", "libpng ~1.6")
```

## xrepo

xrepo 是一个基于 [Xmake](https://github.com/xmake-io/xmake) 的跨平台 C/C++ 包管理器。

它基于 xmake 提供的运行时，但却是一个完整独立的包管理程序，相比 vcpkg/homebrew 此类包管理器，xrepo 能够同时提供更多平台和架构的 C/C++ 包。

## 提交一个新包到仓库

在 `packages/x/xxx/xmake.lua` 中写个关于新包的 xmake.lua 描述，然后提交一个 pull-request 到 dev 分支。

例如：[packages/z/zlib/xmake.lua](https://github.com/xmake-io/xmake-repo/blob/dev/packages/z/zlib/xmake.lua):

关于如何制作包的更详细描述，请参看文档：[制作和提交到官方仓库](https://xmake.io/#/zh-cn/package/remote_package?id=%e6%b7%bb%e5%8a%a0%e5%8c%85%e5%88%b0%e4%bb%93%e5%ba%93)

## 从 Github 创建一个包模板

我们需要先安装 [gh](https://github.com/cli/cli) cli 工具，然后执行下面的命令登入 github。

```console
gh auth login
```

基于 github 的包地址创建一个包配置文件到此仓库。

```console
$ xmake lua scripts/new.lua github:glennrp/libpng
package("libpng")
    set_homepage("http://libpng.sf.net")
    set_description("LIBPNG: Portable Network Graphics support, official libpng repository")

    add_urls("https://github.com/glennrp/libpng/archive/refs/tags/$(version).tar.gz",
             "https://github.com/glennrp/libpng.git")
    add_versions("v1.6.35", "6d59d6a154ccbb772ec11772cb8f8beb0d382b61e7ccc62435bf7311c9f4b210")

    add_deps("cmake")

    on_install(function (package)
        local configs = {}
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:debug() and "Debug" or "Release"))
        table.insert(configs, "-DBUILD_SHARED_LIBS=" .. (package:config("shared") and "ON" or "OFF"))
        import("package.tools.cmake").install(package, configs)
    end)

    on_test(function (package)
        assert(package:has_cfuncs("foo", {includes = "foo.h"}))
    end)
packages/l/libpng/xmake.lua generated!
```

## 在本地测试一个包

```console
xmake l scripts/test.lua --shallow -vD zlib
xmake l scripts/test.lua --shallow -vD -p iphoneos zlib
xmake l scripts/test.lua --shallow -vD -k shared -m debug zlib
xmake l scripts/test.lua --shallow -vD --vs_runtime=MD zlib
```
