--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] 

local M = require 'amend.docs.module'

require 'amend.docs.generate'
require 'amend.docs.parser'
require 'amend.docs.tokenizer'

--- Raise an error.
local function raise(context, fmt, ...)
    message(ERROR, "In source %q [%d:%d]:", context.source, context.line, context.column)
    message(ERROR, fmt, ...)
    os.exit(1)
end

-- [[ MODULE ]]
M.raise = raise
return M
