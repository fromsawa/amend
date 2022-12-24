--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]

--[===[>>[amend.api.use.git] Git support.
--]===]
local M = {}

-- -- [[ git ]]
-- local git = TOOLS["git-command"]
-- if git == nil then
--     local v = io.command("git version")
--     if v then
--         print("Found git " .. v:match("([0-9].*)"))
--         git = "git"
--     else
--         git = false
--     end
-- end
-- TOOLS["git-command"] = TOOLS["git-command"] or "git"

-- if git then
--     TOOLS["git-add"] = TOOLS["git-add"] or "git add %q"
-- -- FIXME
-- end


--- `check()`
--
-- Check if project uses git and update PROJECT settings.
--
local function check()
    local res = fs.exists(fs.concat(ROOTDIR, ".git"))

    if res then
        local exe = fs.which("git")
        if not exe then
            message(WARNING, "git executable could not be found")
            return false
        end

        TOOLS["git"] = TOOLS["git"] or auto
    end

    return res
end

-- [[ MODULE ]]
message(TRACE, "Git support loaded")

M.check = check
return M
