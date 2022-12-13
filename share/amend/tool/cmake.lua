--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] 

--[===[>>[amend.api.use.cmake] CMake support.
--]===] 

local M = {}

--- `parse_args(options, one_value_keywords, multi_value_keywords, ...)`
--
local function parse_args(options, one_value_keywords, multi_value_keywords, ...)
    local arguments = {...}
    if type(arguments[1]) == 'table' then
        arguments = arguments[1]
    end

    -- convert to lookup table
    local function make_lookup(t)
        for _,k in ipairs(t) do
            t[k] = true
        end
    end

    make_lookup(options)
    make_lookup(one_value_keywords)
    make_lookup(multi_value_keywords)
    
    -- parse
    local res = {}

    local current = nil
    local i = 1
    while i <= #arguments do
        local value = arguments[i]

        if options[value] then
            res[value] = true
        elseif one_value_keywords[value] then
            i = i + 1
            res[value] = arguments[i]
        elseif multi_value_keywords[value] then
            i = i + 1
            current = value
            res[value] = { arguments[i] }
        elseif current then
            table.insert(res[current], value)
        else
            res.UNPARSED_ARGUMENTS = res.UNPARSED_ARGUMENTS or {}
            table.insert(res.UNPARSED_ARGUMENTS, value)
        end

        i = i + 1
    end
    
    return res
end

--- `update(configfile)`
--
-- Update PROJECT configuration.
--
local function update(configfile)
    message(TRACE[2], "Updating project from %q...", configfile)

    -- extrace "project" command arguments 
    local project
    local inproject = false
    for line in io.lines(configfile) do
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
    end

    -- update settings
    if project then
        PROJECT.NAME = table.remove(project, 1)

        -- project(<PROJECT-NAME> [<language-name>...])
        -- project(<PROJECT-NAME>
        --         [VERSION <major>[.<minor>[.<patch>[.<tweak>]]]]
        --         [DESCRIPTION <project-description-string>]
        --         [HOMEPAGE_URL <url-string>]
        --         [LANGUAGES <language-name>...])
        local param = parse_args({}, {"VERSION", "DESCRIPTION", "HOMEPAGE_URL"}, {"LANGUAGES"}, project)
        if param.VERSION then
            PROJECT.VERSION = param.VERSION
        end

        if param.UNPARSED_ARGUMENTS then
            param.LANGUAGES = param.UNPARSED_ARGUMENTS
        end

        if param.LANGUAGES then
            PROJECT.USES = PROJECT.USES or {}
            for _, l in ipairs(param.LANGUAGES) do
                local initstatus, errmsg = pcall(require, "amend.tool."..l:lower())
                if initstatus then
                    table.insert(PROJECT.USES, l:upper())                
                end
            end
        end
    end
end

--- FIXME
local function check()
    local file = fs.concat(ROOTDIR, "CMakeLists.txt")
    local res = fs.exists(file)

    if res then
        res = fs.isnewer(file, PROJECTFILE)
        if res then
            update(file)
            PROJECT.UPDATE = true
        end
    end

    return res
end

-- [[ MODULE ]]
M.update = update
M.check = check

message(TRACE, "CMake tool loaded")
return M
