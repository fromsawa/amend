--[[
    Copyright (C) 2022-2024 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] 

--[[>>[amend.api.project.tools] Tools

The `TOOLS` table associates an external command with a "tool". For example:

```.lua
TOOLS = {
    ["git"] = auto,
    ["clang"] = "/usr/bin/clang-15"
}
```

will tell `amend` to automatically detect the git command and version, while
clang will explicitely use major version 15.

See the [external tools](#amend.api.use) chapter for further information.

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

