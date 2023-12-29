--[[
    Copyright (C) 2022-2023 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[[
    Amend's internal 'sed' equivalent.
]]
local sed = io.sed

local function amend_edit()
    -- parse options
    local args = {}
    local opts = {
        dryrun = false
    }

    for i = 1, #OPTIONS do
        local a = OPTIONS[i]

        if a:match("^[-][-]") then
            opts[a:gsub("[^a-z]", "")] = true
        elseif a:match("^[-]") then
            message(NOTICE, "invalid option: %q", a)
            os.exit(1)
        else
            tinsert(args, a)
        end
    end

    if #args > 2 or #args < 2 then
        message(NOTIVE, "pattern and replacement string required")
        os.exit(1)
    end

    -- edit whole source tree
    fs.dodir(
        ROOTDIR,
        function(t)
            sed(t[0], args[1], args[2], opts)
        end,
        {
            exclude = IGNORE,
            recurse = true,
            mode = "file"
        }
    )
end

return {
    name = "edit",
    invocation = "edit <pattern> <replacement>",
    comment = "edit files (like sed)",
    scope = "builtin",
    arguments = {
        min = 2,
        max = 999
    },
    component = amend_edit
}
