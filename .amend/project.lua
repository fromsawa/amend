--[[
    Project settings.

    This table contains two required entries:

        NAME            Project name.
        VERSION         Project version.

    If a CMakeLists.txt file is present, these values are automatically filled in.

    Users are free to add additional entries.
]]
PROJECT = {
    NAME = "amend",
    VERSION = "0.90",
}

--[[
    Amend configuration.

    FIXME
]]
CONFIG = {
    EXTENSIONS = {
        C = {
            ".h",
            ".c",
        },
        CXX = {
            ".hh",
            ".hpp",
            ".hxx",
            ".cc",
            ".cpp",
            ".cxx",
        },
    },
    LANG = {
        C = {
            POST = {
                TIDY = "clang-format",
            },
            PRE = {},
        },
        CXX = {
            POST = {
                TIDY = "clang-format",
            },
            PRE = {},
        },
    },
}

--[[
    Tools.

    FIXME
]]
TOOLS = {
    ["clang-format"] = "clang-format",
    ["git-add"] = "git add %q",
    ["git-command"] = "git",
}

--[[
    Package paths.
]]
PATHS = {}
