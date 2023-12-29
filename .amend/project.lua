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
        "GIT"
    },
    VERSION = {0, 91}
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
    ["git"] = auto
}

--[[
    Package paths.
]]
PATHS = {}
