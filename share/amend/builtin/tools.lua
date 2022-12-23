--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[[
    FIXME
]]

local function amend_tools()
end

return {
    name = "tools",
    invocation = "tools",
    comment = "list available tools",
    scope = "builtin",
    arguments = {
        min = 0,
        max = 0
    },
    component = amend_tools
}
