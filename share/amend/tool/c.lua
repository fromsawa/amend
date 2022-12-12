--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[===[>>[amend.api.use.git] C support.
--]===]
message(TRACE, "C support loaded")

require 'amend.use.clang'
require 'amend.use.gcc'
