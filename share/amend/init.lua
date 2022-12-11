--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[[
    "Amend" initialization.    

    This module loads all ''amend'' modules into global namespace.
    Thus, "components" need not to load anything related to "amend".
]]
-- Lua extensions
require "amend.lua.io"
require "amend.lua.os"
require "amend.lua.string"
require "amend.lua.table"

-- amend functionality
fs = require "amend.filesystem"
component = require "amend.component"
edit = require "amend.edit"
csv = require "amend.csv"
rdbl = require "amend.rdbl"

-- get current file name
function filename()
    local cwd = fs.currentdir()
    local dirsep = package.config:sub(1, 1)
    local module = debug.getinfo(2, "S").source:sub(2)
    return cwd .. dirsep .. module
end
