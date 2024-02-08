--[[
    Copyright (C) 2022-2024 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
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
