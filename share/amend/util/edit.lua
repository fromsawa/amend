--[[
    Copyright (C) 2022-2024 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --[[>>[amend.api.util.edit] Editing

Amend provides several utilities for editing files.

]] local mod = {}

local tinsert = table.insert
local tremove = table.remove
local sformat = string.format

-- [[ section meta ]]
local section = {}

--- `clear()`
-- Clear contents.
function section:clear()
    while #self > 0 do
        tremove(self, #self)
    end

    local id = self[".id"]
    if id then
        self[".amend"] = sformat("//@AMEND{%s} -- auto-generated content:", id)
        self[".end"] = sformat("//@END{%s} -- end of auto-generated content", id)
    end
end

--- `add(code, ...)`
-- Add code to current line.
function section:add(code, ...)
    if #self == 0 then
        tinsert(self, "")
    end

    assert(type(code) == 'string', "expected a string")
    if ... then
        self[#self] = self[#self] .. sformat(code, ...)
    else
        self[#self] = self[#self] .. code
    end
end

--- `addln(code, ...)`
-- ::as
--      addln()
--      addln(<table>)
--      addln(<plain string>)
--      addln(<format>, <format arguments...>)
--
-- Add a code line with formatting or array of lines.
--
function section:addln(code, ...)
    if code == nil then
        tinsert(self, "")
    elseif type(code) == "table" then
        for _, v in ipairs(code) do
            tinsert(self, v)
        end
    else
        assert(type(code) == 'string', "expected a string")
        if ... then
            tinsert(self, sformat(code, ...))
        else
            tinsert(self, code)
        end
    end
end

--- `sed(pattern, replace)`
-- In-place sed.
--
function section:sed(pattern, replace)
    local found = false
    for LINE, l in ipairs(self) do
        if l:match(pattern) then
            message(3, "- found sed expression on line %d", LINE)
            found = true
            self[LINE] = l:gsub(pattern, replace)
        end
    end
    return found
end

--- `write(stream)`
-- Write section to a stream.
function section:write(stream)
    local indent = self[".indent"] or ""
    local function emit(s)
        stream:write(indent, s, "\n")
    end

    if self[".amend"] then
        emit(self[".amend"])
    end

    for _, l in ipairs(self) do
        emit(l)
    end

    if self[".end"] then
        emit(self[".end"])
    end
end

section.__index = section
setmetatable(section, {
    --- **section**`()`
    -- Constructor.
    __call = function(mt, file_)
        local t = {}
        setmetatable(t, mt)
        if file_ then
            tinsert(file_, t)
        end
        return t
    end
})

-- [[ file meta ]]
local file = {}

--- `parse(path)`
-- Parse file (into sections)
--
function file:parse(path)
    message(4, "Loading %q for editing...", path)

    self[".path"] = path

    local LINE = 0 -- keeping track of line number for error message
    local id, indent = nil, "" -- helper variables during parsing
    local sec = section(self) -- current section

    local f = assert(io.open(path))
    for l in f:lines() do
        LINE = LINE + 1
        message(6, "[%4d] %s", LINE, l)

        if id then -- we're inside "@AMEND" section
            if l:match("^" .. indent) then
                l = l:sub(#indent + 1)
            end

            local name = l:match("^%s*[^@]+@END{([^}]+)}.*$")
            if name then
                if name ~= id then
                    io.printf("[ERROR] found @END{%s}, but expected @END{%s}\n", name, id)
                    os.exit(1)
                end
                sec[".end"] = l

                sec = section(self)
                id = nil
            else
                sec:addln(l)
            end
        else
            indent, id = l:match("^(%s*)[^@]+@AMEND{([^}]+)}.*$")
            if id then
                message(5, "- found section %q", id)

                sec = section(self)
                self[id] = sec

                sec[".indent"] = indent
                sec[".id"] = id

                if l:match("^" .. indent) then
                    l = l:sub(#indent + 1)
                end
                sec[".amend"] = l
            else
                sec:addln(l)
            end
        end
    end
    f:close()
end

local function run_other(t, path)
    t = t or {}

    for k, v in pairs(t) do
        if math.tointeger(k) then
            FIXME()
        else
            if TOOLS[v] then
                message(4, "[%s] executing %s...", k, string.format(TOOLS[v], path))
                os.command(TOOLS[v], path)
            end
        end
    end
end

--- `update()`
-- Update file.
--
function file:update()
    local path = self[".path"]
    message(STATUS, "Updating %q...", path)
    local config = CONFIG.LANG[fs.filetype(path)]

    -- PRE
    message(VERBOSE, "Running pre...")
    run_other(config and config.PRE, path)

    -- write data
    local f = assert(io.open(path, "w"))

    for _, sec in ipairs(self) do
        assert(getmetatable(sec) == section)
        sec:write(f)
    end

    if f ~= io.stdout then
        f:close()
    end

    -- POST
    message(VERBOSE, "Running post...")
    run_other(config and config.POST, path)
end

--- `sed(pattern, replace)`
-- In-place sed.
--
function file:sed(pattern, replace)
    local found = false
    for _, sec in ipairs(self) do
        found = found or sec:sed(pattern, replace)
    end
    return found
end

file.__index = file
setmetatable(file, {
    -- Constructor.
    __call = function(mt, path)
        local t = {}
        setmetatable(t, mt)
        if path then
            t:parse(path)
        end
        return t
    end
})

-- [[ MODULE ]]

--- `edit.file{fname, ...}`
-- Edit a single or multiple files.
--
-- Example:
-- Assuming we have a file 'myfile.hh' with the following 
-- ```.hh
-- constexpr const char *version_s = "1.2.3";
-- constexpr int version[] = {
--     //@AMEND{myfile:version}
--     //@END{myfile:version}
-- }
-- ```
-- then we can use the following script snippet to automatically
-- update the contents:
-- ```.lua
-- local version = {0,1,2,3}
-- local code = edit.file{'myfile.hh'}
-- code:sed('(constexpr const char [*]version_s) = .*;', '%1 = %q', table.concat(version, "."))
-- code['myfile:version']:clear()
-- for _, v in ipairs(version) do
--     code['myfile:version']:addln("%d,", v)
-- end
-- code:update()
-- ```
function mod.file(fname)
    if type(fname) ~= "table" then
        fname = {fname}
    end

    -- parse file-wise
    local ret = {}
    for _, path in ipairs(fname) do
        -- load and parse file
        -- local f = {}
        -- setmetatable(f, file)

        -- f:parse(path)
        f = file(path)

        -- add file and sections to ret
        ret[path] = f
        for k, v in pairs(f) do
            if type(k) == "string" and getmetatable(v) == section then
                ret[k] = v
            end
        end
    end

    -- set meta
    local mt = {
        update = function(t)
            for k, v in pairs(t) do
                if getmetatable(v) == file then
                    v:update()
                end
            end
        end
    }
    mt.__index = mt
    setmetatable(ret, mt)

    return ret
end

-- [[ module ]]
message(TRACE[10], "loaded util.edit module")
return mod
