--[[
    Project settings.

    This table contains two required entries:

        NAME            Project name.
        VERSION         Project version.

    If a CMakeLists.txt file is present, these values are automatically detected.

    Additional variable(s) are:
        USE             List of languages and tools required.

    Users are free to add additional entries.
]]
PROJECT = {
    NAME = "amend",
    USES = { 'GIT' },
    VERSION = "0.90",
}

--[[
    Amend configuration.

    FIXME
]]
CONFIG = {
}

--[[
    Tools.

    FIXME
]]
TOOLS = {
}

--[[
    Package paths.
]]
PATHS = {}
