--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --
local M = require "amend.docs.__module"

--[[>>[amend.api.docs.api.stream] Streams and context.
]] --

local mtype = math.type
local tinsert = table.insert
local tremove = table.remove
local strformat = string.format
local strfind = string.find
local strtrim = string.trim
local strlen = string.len
local cindex = class.index
local cnewindex = class.newindex

--- `stream.context`
--
-- FIXME
--
--{
local context =
    class(M) "stream.context" {
    __public = {
        source = "<chunk>",
        line = 1,
        column = 1
    }
}

--- `context(...)`
-- @call
--      `context(source)`
--      `context(source, line, column)`
--      `context(source, line)`
-- @param
--      source      Source for context (string or context object)
--      line        Line or line offset.
--      column      Column or column offset.
--
-- Construct a "context".
--
-- @see [amend.docs.context.call]
function context:__init(source, line, column)
    local done = false
    if source then
        if isa(source, context) then
            self.source = source.source
            self.line = source.line + (line or 0)
            if column then
                if line > 0 then
                    self.column = column
                else
                    self.column = source.column + column
                end
            end
            done = true
        elseif isa(source, M.stream.file) then
            self.source = source
            self.line = line or 1
            self.column = column or 1
        elseif type(source) == "string" then
            self.source = source
        else
            error("expected a source name or a context object")
        end
    end

    if not done and line then
        self.line = line

        if column then
            self.column = column
        end
    end
end

---[amend.docs.context.call] `context()(...)`
-- @call
--      `obj(column)`
--      `obj(line, column)`
-- @param
--      line        Line offset (default: 0).
--      column      Column offset.
--
-- Derive a new context.
--
-- FIXME
--
function context:__call(offset, column)
    if column then
        return context(self, offset, column)
    else
        return context(self, 0, offset)
    end
end

function context:__dump(options)
    options.stream:write(strformat("<%s [%d:%d]>", self.source, self.line, self.column))
end
--}

--- `stream.line`
--
-- FIXME
--
-- {
local line =
    class(M) "stream.line" {
    __public = {
        text = void,
        origin = void
    }
}

function line:__init(text, origin, offset)
    assert(isa(text, "string") == true)
    assert(isa(origin, context) == true)

    self.text = text
    if offset then
        self.origin = origin(offset)
    else
        self.origin = origin
    end
end

function line:re(pattern)
    local txt = self.text
    local match = {txt:find(pattern)}

    local n = #match
    if n > 0 then
        local offset, final = match[1], match[2]
        local ctxt = self.origin(offset)

        local res = {
            [0] = {offset, final},
            origin = self.origin
        }

        for i = 3, n do
            tinsert(res, line(match[i], ctxt))
        end

        return res
    end
end

function line:trim()
    local space, tmp = self.text:match("^(%s*)(.*)%s*$")
    self.origin.column = self.origin.column + strlen(space)
    self.text = strtrim(tmp)
    return self
end

function line:sub(bpos, epos)
    return line(self.text:sub(bpos, epos), self.origin(bpos - 1))
end

function line:__index(k)
    if mtype(k) == "integer" then
        return self.text:sub(k, k)
    else
        return cindex(self, k)
    end
end

function line:__len()
    return strlen(self.text)
end

function line:__tostring(options)
    return self.text
end

function line:__dump(options)
    options.stream:write("[[", self.text, "]]")
end
--}

--- `stream.file`
--
-- FIXME
--
--{
local file =
    class(M) "stream.file" {
    __public = {
        origin = void,
        language = void,
        id = void
    }
}

function file:__init()
end

function file:__index(k)
    if mtype(k) == "integer" then
        return self.data[k]
    else
        return cindex(self, k)
    end
end

function file:__newindex(k, v)
    if mtype(k) == "integer" then
        assert(isa(v, line) == true)
        rawset(self, k, v)
    else
        cnewindex(self, k, v)
    end
end

function file:insert(aline)
    assert(isa(aline, line) == true)
    rawset(self, #self + 1, aline)
end

function file:lines()
    local idx = 0
    return function(obj)
        idx = idx + 1
        if idx <= #obj then
            return rawget(obj, idx)
        end
    end, self
end

function file:load(path, workdir)
    local iter, errmsg = io.lines(path)
    if not iter then
        error(errmsg, 2)
    end

    path = fs.fullpath(path)
    workdir = workdir or ROOTDIR

    local _, _, extension = fs.parts(path)
    self.language = extension

    local origin = fs.relpath(path, workdir)
    self.origin = origin

    local i = 0
    local ctxt = context(self, 1, 1)
    for txt in iter do
        if txt:match("[\t]") then
            message(ERROR, "TAB characters are not supported (%q).", origin)
        end

        self:insert(line(txt, ctxt(i, 1)))
        i = i + 1
    end
end
--}

-- [[ MODULE ]]
return M
