--[[
    Copyright (C) 2022-2024 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] 

--[===[>>[amend.api.use.c] C support.

TBD

]===]
local M = {}

-- CONFIG defaults
local function defaults() 
    CONFIG.EXTENSIONS.C = CONFIG.EXTENSIONS.C or {".h", ".c"}
    CONFIG.LANG.C = CONFIG.LANG.C or {
        PRE = {},
        POST = {}
    }
end

-- [[ MODULE ]]
M.check = function() end
M.defaults = defaults

message(TRACE, "C support loaded")
return M
