--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[===[>>[amend.api.tools] External tools.

FIXME

--]===]
local M = {}

--- FIXME
local mt = {
    __index = function(t,k)
        -- FIXME
        return rawget(t, k)
    end,
    __newindex = function(t,k,v)
        -- FIXME
        rawset(t, k, v)
    end
}
setmetatable(M, mt)

-- [[ MODULE ]]
return M
