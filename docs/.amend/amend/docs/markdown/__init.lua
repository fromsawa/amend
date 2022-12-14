--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --

local M = require "amend.docs.markdown.__module"

require "amend.docs.markdown.types"
require "amend.docs.markdown.document"

local function parse(core, thefile)
    message(INFO, "parsing markdown in %q...", thefile.origin)
    local doc = M.document(core)
    doc:parse(thefile)
    return doc
end

-- [[ MODULE ]]
M.parse = parse
return M
