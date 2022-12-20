--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] 

local M = require 'amend.docs.__module'

require 'amend.docs.generator'
require 'amend.docs.parser'

--- Output a notice with context.
local function notice(level, context, fmt, ...)
    message(level, "In source %q [%d:%d]:", context.source, context.line, context.column)
    message(level, fmt, ...)

    while type(level) == 'table' do
        level = table.unpack(level);
    end

    if level <= ERROR[1] then
        os.exit(1)
    end
end

-- [[ MODULE ]]
M.notice = notice
return M
