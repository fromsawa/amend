--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]

return {
    name = "all",
    comment = "execute all components",
    scope = "builtin",
    component = function()
        for _,t in ipairs(COMPONENTS) do
            if t.scope == "user" then
                message(DEBUG, "Running %q...", t.name)
                component.run(t.name)
            end
        end
    end
}
