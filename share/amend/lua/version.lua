--[[
    Copyright (C) 2024 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[[>>[amend.api.lua.version] Version number library
]]

require "amend.lua.class"
require "amend.lua.string"

--- `version`
--
-- Version numbering and comparison.
--
class 'version' {
    __public = {
        values = {},
        compare = void
    }
}

local function toversion(s)
    local d = 0
    local t = s:split('.')
    for i,v in ipairs(t) do
        v = tonumber(v)
        if v == nil then
            break
        end 
        d = i
        t[i] = v
    end
    return t,d
end

--- `version(t)`
--
-- @param 
--      t       Version definition.
--
-- FIXME 
-- 
function version:__init(t)
    if type(t) == 'string' then
        
    elseif type(t) == 'table' then
        
    else
        error('Invalid argument passed to version().')
    end
end

--- `version:tostring()`
--
-- Convert to a string.
--
function version:tostring() 
    return table.concat(self.values, '.')
end