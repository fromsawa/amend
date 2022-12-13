--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] 

--[[>>[amend.api.project.tools] Tools.

FIXME

]] 

-- check tools
PROJECT.USES = PROJECT.USES or {}
for k,t in pairs(tool) do
    if t.check() then
        local tag = k:upper()
        if not table.has(PROJECT.USES, tag) then
            table.insert(PROJECT.USES, tag)
            PROJECT.UPDATE = true
        end
    end
end

