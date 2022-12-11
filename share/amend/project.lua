--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[[>>[amend.api.project] 

FIXME

]]
PROJECT = PROJECT or {}
CONFIG = CONFIG or {}
TOOLS = TOOLS or {}
PATHS = PATHS or {}

local usage = {}
-- ===========================================================================
-- Detect tools
-- ===========================================================================
usage.TOOLS = [[
    Tools.

    FIXME
]]

local cmd

-- [[ clang-format ]]
local clang_format = TOOLS["clang-format"]
if clang_format == nil then
    cmd = "clang-format"
    local v = io.command(cmd .. " --version")
    if v then
        print("Found clang-format " .. v:match("([0-9].*)"))
        clang_format = "clang-format -i %q"
    else
        clang_format = false
    end
end
TOOLS["clang-format"] = clang_format

-- [[ git ]]
local git = TOOLS["git-command"]
if git == nil then
    local v = io.command("git version")
    if v then
        print("Found git " .. v:match("([0-9].*)"))
        git = "git"
    else
        git = false
    end
end
TOOLS["git-command"] = TOOLS["git-command"] or "git"

if git then
    TOOLS["git-add"] = TOOLS["git-add"] or "git add %q"
-- FIXME
end

-- ===========================================================================
-- Project settings
-- ===========================================================================
usage.PROJECT = [[
    Project settings.

    This table contains two required entries:

        NAME            Project name.
        VERSION         Project version.

    If a CMakeLists.txt file is present, these values are automatically filled in.

    Users are free to add additional entries.
]]

local CMakeLists = fs.concat(ROOTDIR, "CMakeLists.txt")
if fs.attributes(CMakeLists) then
    local project
    local inproject = false
    for line in io.lines(CMakeLists) do
        if not inproject then
            if line:match("project%s*[(]") then
                project = line

                if line:match("[)]") then
                    break
                end

                inproject = true
            end
        else
            project = project .. " " .. line
            if line:match("[)]") then
                break
            end
        end
    end

    if project then
        project = project:gsub("project%s*[(]%s*([^)]+).*", "%1")
        project = project:gsub("[ \t]+", " ")
        project = string.split(project, " ")

        -- name is first
        PROJECT.NAME = table.remove(project, 1)

        -- version follows VERSION
        while #project > 0 do
            local cmd = table.remove(project, 1)
            if cmd == "VERSION" then
                PROJECT.VERSION = table.remove(project, 1)
                break
            end
        end
    end
end

PROJECT.NAME = PROJECT.NAME or "<unknown>"
PROJECT.VERSION = PROJECT.VERSION or "<unknown>"

-- ===========================================================================
-- Amend settings
-- ===========================================================================
usage.CONFIG = [[
    Amend configuration.

    FIXME
]]

-- [[ file extensions ]]
CONFIG.EXTENSIONS = CONFIG.EXTENSIONS or {}
CONFIG.EXTENSIONS.C = CONFIG.EXTENSIONS.C or {".h", ".c"}
CONFIG.EXTENSIONS.CXX = CONFIG.EXTENSIONS.CXX or {".hh", ".hpp", ".hxx", ".cc", ".cpp", ".cxx"}

-- [[ language tools ]]
CONFIG.LANG = CONFIG.LANG or {}
CONFIG.LANG.C =
    CONFIG.LANG.C or
    {
        PRE = {},
        POST = {}
    }
CONFIG.LANG.CXX =
    CONFIG.LANG.CXX or
    {
        PRE = {},
        POST = {}
    }

-- tidy
if clang_format then
    for _, k in ipairs {"C", "CXX"} do
        if CONFIG.LANG[k].POST.TIDY == nil then
            CONFIG.LANG[k].POST.TIDY = "clang-format"
        end
    end
end

-- ===========================================================================
-- create extensions list (fs.filetype)
EXTENSION = {}
for group, t in pairs(CONFIG.EXTENSIONS) do
    for _, k in ipairs(t) do
        EXTENSION[k] = group
    end
end

-- ===========================================================================
-- Paths
-- ===========================================================================
usage.PATHS = [[
    Package paths.
]]
-- already handled in main amend.lua

-- [[ SAVE CONFIG ========================================================= ]]
local function comment(f, sec, paragraph)
    if paragraph then
        f:write("\n")
    end

    if usage[sec] then
        f:write("--[[\n")
        f:write(usage[sec])
        f:write("]]\n")
    end
end

local f = io.open(PROJECTFILE, "w")
for i, sec in ipairs {"PROJECT", "CONFIG", "TOOLS", "PATHS"} do
    comment(f, sec, i > 1)
    io.dump(_G[sec] or {}, {key = sec, stream = f})
end

-- [[ Fill '<auto>' ======================================================= ]]
-- FIXME
