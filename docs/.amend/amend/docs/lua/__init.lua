--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --

local M = require "amend.docs.lua.__module"

require "amend.docs.lua.source"

local function parse(core, thefile)
    message(INFO, "parsing Lua source in %q...", thefile.origin)
    local src = M.source(core)
    src:parse(thefile)
    return src
end

-- [[ MODULE ]]
M.parse = parse
return M
