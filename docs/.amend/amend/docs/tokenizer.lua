--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] local M = require 'amend.docs.__module'

local tinsert = table.insert
local tremove = table.remove
local strsplit = string.split
local strtrim = string.trim
local strlen = string.len

local function tokenize(db, data)
    message(TRACE[10], "tokenize(%q)", data.file)

    local node
    for _, fragment in ipairs(data) do
        local context = fragment.context

        if fragment.tag == 'document' then
        end

        io.dump(fragment, {key = 'fragment'})
        os.exit()
    end
end

-- [[ MODULE ]]
M.tokenize = tokenize
return M
