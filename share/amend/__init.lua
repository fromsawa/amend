--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[[
    "Amend" initialization.    

    This module loads all ''amend'' modules into global namespace.
    Thus, "components" need not to load anything related to "amend".
]]
require "amend.message"

-- Lua extensions
require "amend.lua.io"
require "amend.lua.os"
require "amend.lua.string"
require "amend.lua.table"
require "amend.lua.class"

-- get current file name
function filename()
    local cwd = fs.currentdir()
    local dirsep = package.config:sub(1, 1)
    local module = debug.getinfo(2, "S").source:sub(2)
    return cwd .. dirsep .. module
end

-- FIXME
auto = {}
setmetatable(auto, {
    __dump = function(self, options)
        options.stream:write("auto")
    end})

-- amend functionality
fs = require "amend.util.filesystem"
csv = require "amend.util.csv"
rdbl = require "amend.util.rdbl"
edit = require "amend.util.edit"
component = require "amend.component"
tool = require "amend.tool"

