--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] local M = require 'amend.docs.__module'

local tinsert = table.insert
local cindex = class.index

--- `context`
--
-- {
local context = class(M) "context" {
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
                    self.column = source.column + (column or 0)
                end
            end
            done = true
        elseif isa(source, M.file) then
            self.source = source
            self.line = line or 1
            self.column = column or 1
        elseif type(source) == 'string' then
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
-- }

--- `file`
--
-- {
local file = class(M) "file" {
    __public = {
        path = void, -- @var `path` Full file path.
        file = void, -- @var `file` Relative file path.
        extension = {}, -- @var `extension` File extension.
        data = {} -- @var `data` Lines.
    }
}

function file:__init(path, workdir)
    if path then
        self:load(path, workdir)
    end
end

function file:__index(n)
    if math.type(n) == 'integer' then
        return self.data[n]
    else
        return cindex(self, n)
    end
end

function file:load(path, workdir)
    local iter, errmsg = io.lines(path)
    if not iter then
        error(errmsg, 2)
    end

    path = fs.fullpath(path)
    workdir = workdir or ROOTDIR

    self.path = path
    self.file = fs.relpath(path, workdir)
    local _, _, extension = fs.parts(path)
    self.extension = extension

    local lines = self.data
    for line in iter do
        if line:match("[\t]") then
            error("TAB characters are not supported.")
        end

        tinsert(lines, line)
    end
end

function file:lines()
    return #(self.data)
end

function file:context(line, column)
    return context(self, line, column or 1)
end

function file:message(level, line, column, fmt, ...)
    M.notice(level, context(self, line, column), fmt, ...)
end
-- }

-- [[ MODULE ]]
return M
