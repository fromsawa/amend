--[[
    Copyright (C) 2022-2023 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] 

--[===[>>[amend.api.use.cxx] CXX support
]===]
local M = {}

-- CONFIG defaults
local function defaults() 
    CONFIG.EXTENSIONS.CXX = CONFIG.EXTENSIONS.CXX or {".hh", ".hpp", ".hxx", ".cc", ".cpp", ".cxx"}
    CONFIG.LANG.CXX = CONFIG.LANG.CXX or {
        PRE = {},
        POST = {}
    }
end

-- [[ MODULE ]]
M.check = function() end
M.defaults = defaults

message(TRACE, "C++ support loaded")
return M
