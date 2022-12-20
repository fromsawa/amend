--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] local M = require 'amend.docs.__module'

--- `context`
--
-- {
local context = class(M) "context" {
    __public = {
        source = "<chunk>",
        line = 1,
        column = 1
    },
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
        source = void
    }
}

function file:__init(...)
    -- FIXME
end

function file:load(...)
    -- FIXME
end

-- }

-- [[ MODULE ]]
M.context = context
return M
