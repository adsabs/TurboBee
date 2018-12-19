package = "turbobee"
version = "0.1-1"
source = {
    url = "https://github.com/marblestation/TurboBee"
}
description = {
    homepage = "https://ui.adsabs.harvard.edu/#",
    license = "GNU Affero General Public License v3.0"
}
dependencies = {
    "lua >= 5.1, < 5.4",
    "pgmoon == 1.9.0-1",
    "luaunit == 3.3-1"
}
build = {
    type = "builtin",
    modules = {
        ["turbobee.abs"] = "turbobee/abs.lua",
        ["turbobee.search"] = "turbobee/search.lua",
        ["tests.test"] = "tests/test.lua"
    },
    copy_directories = {
        "tests"
    }
}
