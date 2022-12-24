--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]

local M = {}

local tools = {
    format = "clang-format",
    tidy = "clang-tidy",
    rename = "clang-rename"
}

for k,v in pairs(tools) do
    if TOOLS[v] then
        if TOOLS[v] == auto then
            TOOLS[v] = fs.which(v)            
        end

        local fn = require('amend.tool.clang.' .. k)
        tool[v] = fn
        M[k] = fn
    end
end

-- [[ MODULE ]]
message(TRACE, "Clang tools support loaded")
return M
