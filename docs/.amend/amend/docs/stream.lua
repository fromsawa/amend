--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] local M = require 'amend.docs.__module'

local mtype = math.type
local tinsert = table.insert
local tremove = table.remove
local cindex = class.index
local cnewindex = class.newindex

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

--- `stream`
--
-- {
local stream = class(M) "stream" {
    __public = {
        --
    }
}

function stream:__init()
end

function stream:__index(k)
    if mtype(n) == 'integer' then
        return self.data[k]
    else
        return cindex(self, k)
    end
end

function stream:__newindex(k, v)
    if mtype(k) == 'integer' then
        rawset(self, k, v)
    else
        cnewindex(self, k, v)
    end
end

function stream:lines()
    local idx = 0
    return function(obj)
        idx = idx + 1
        if idx <= #obj then
            return rawget(obj, idx), context(obj, idx)
        end
    end, self
end

function stream:context(line, column)
    return context(self, line, column or 1)
end

function stream:message(level, line, column, fmt, ...)
    M.notice(level, context(self, line, column), fmt, ...)
end
-- }

-- [[ MODULE ]]
return M
