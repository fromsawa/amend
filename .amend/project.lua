--[[
    Project settings.

    This table contains two required entries:

        NAME            Project name.
        VERSION         Project version.

    as well as 

        USES            List of tools in use.

    Users are free to add additional entries.
]]
PROJECT = {
    NAME = "amend",
    USES = {
        "CLANG",
        "GIT"
    },
    VERSION = "0.90"
}

--[[
    Amend configuration.

]]
CONFIG = {
    EXTENSIONS = {},
    LANG = {}
}

--[[
    Tools.
]]
TOOLS = {
    ["clang-format"] = auto,
    ["git"] = auto
}

--[[
    Package paths.
]]
PATHS = {}
