--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] local M = {}

local tinsert = table.insert
local tremove = table.remove
local tmake = table.make
local strlen = string.len

--- File extensions.
local extensions = {".md"}

--- Extract markdown syntax.
--
-- **Note**: At the point of writing, only the full document is "extracted" line-wise.
-- 
local function parse(data)
    message(STATUS, "extracting %q...", data.file)

    -- build (single) fragment
    local fragment = {
        tag = "file"
    }

    local source = data.file
    local line = 1
    local column = 1
    for text in io.lines(data.path) do
        tinsert(fragment, {
            source = source,
            line = line,
            column = column,
            text = text
        })
        line = line + 1
    end

    -- remove leading/trailing empty lines
    while (#fragment > 0) and fragment[1].text:match("^[%s]*$") do
        tremove(fragment, 1)
    end

    while (#fragment > 0) and fragment[#fragment].text:match("^[%s]*$") do
        tremove(fragment, #fragment)
    end

    tinsert(data, fragment)
end

-- [[ MODULE ]]
M.extensions = extensions
M.parse = parse
return M
