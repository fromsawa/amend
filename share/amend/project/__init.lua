--[[
    Copyright (C) 2022-2023 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]

--[[>>[amend.api.project] Projects

FIXME

<<[.config]
<<[.settings]
<<[.tools]
]]

PROJECT = PROJECT or {}
CONFIG = CONFIG or {}
TOOLS = TOOLS or {}

require 'amend.project.config'
require 'amend.project.settings'
require 'amend.project.tools'

-- [[ DEFAULTS ]]
for _, tag in ipairs(PROJECT.USES) do
    local k = tag:lower()

    if tool[k] and tool[k].defaults then
        tool[k]:defaults()
    end
end

-- [[ EXTENSIONS ]]
-- see `fs.filetype()`
EXTENSIONS = {}
for group, t in pairs(CONFIG.EXTENSIONS) do
    for _, k in ipairs(t) do
        EXTENSIONS[k] = group
    end
end

-- [[ UPDATE/SAVE SETTINGS ]]
if PROJECT.UPDATE then
    message(TRACE[1], 'updating project file...')

    -- cleanup
    PROJECT.UPDATE = nil
    table.unique(PROJECT.USES)
    table.sort(PROJECT.USES)

    local usage = {
        PROJECT = [=[
    Project settings.

    This table contains two required entries:

        NAME            Project name.
        VERSION         Project version ({major, minor[, patch[, tweak]]}).

    as well as 

        USES            List of tools in use.

    Users are free to add additional entries.
]=],
        CONFIG = [=[
    Amend configuration.

]=],
        TOOLS = [=[
    Tools.
]=],
        PATHS = [=[
    Package paths.

    Here, additional Lua paths may be listed, if necessary.
]=]
    }

    local function comment(f, sec, paragraph)
        if paragraph then
            f:write("\n")
        end

        if usage[sec] then
            f:write("--[=[\n")
            f:write(usage[sec])
            f:write("]=]\n")
        end
    end

    local f = io.open(PROJECTFILE, "w")
    for i, sec in ipairs {"PROJECT", "CONFIG", "TOOLS", "PATHS"} do
        comment(f, sec, i > 1)
        if sec == "TOOLS" then
            f:write("TOOLS = ")
            io.dump(_G[sec] or {}, {stream = f, quoted = true})
        else
            io.dump(_G[sec] or {}, {key = sec, stream = f})
        end
    end
end

-- [[ LOAD TOOLS ]]
for _, tag in ipairs(PROJECT.USES) do
    local k = tag:lower()

    if tool[k] then
        tool[k]:use()
    else
        message(ERROR, "tool not found for tag %q, ignoring", tag)
    end
end
