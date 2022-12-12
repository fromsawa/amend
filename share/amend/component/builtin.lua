--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]

local tinsert = table.insert

local function builtin(m)
    local b = require(m)

    b.arguments = b.arguments or {}
    b.arguments.min = b.arguments.min or 0
    b.arguments.max = b.arguments.max or 999

    tinsert(COMPONENTS, b)
end

builtin 'amend.component.dirs'
builtin 'amend.component.all'
builtin 'amend.component.edit'
