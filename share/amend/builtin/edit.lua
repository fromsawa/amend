--[[
    Copyright (C) 2022-2023 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[[
    Amend's internal 'sed' equivalent.
]]
local tinsert = table.insert

local function sed(fname, pattern, replace, opts)
    message(TRACE, "sed(%q,%q,%q)", fname, pattern, replace)

    local dryrun = opts.dryrun -- FIXME not supported

    local output = {}
    local modified

    local ins = assert(io.open(fname))
    if dryrun then
        modified = {}
        for line in ins:lines() do
            if line:match(pattern) then
                local rep = line:gsub(pattern, replace)
                tinsert(modified, {[fname] = {line, rep}})
            end
        end
    else
        local ins = assert(io.open(fname))
        for line in ins:lines() do
            if line:match(pattern) then
                tinsert(output, line:gsub(pattern, replace))
                modified = true
            else
                tinsert(output, line)
            end
        end
    end
    ins:close()

    if dryrun then
        for _, t in ipairs(modified) do
            local fname, diff = next(t)

            message(INFO, "%s", fs.relpath(fname, ROODIR))
            message(INFO, "--- %s", diff[1])
            message(INFO, "+++ %s", diff[2])
        end
    else
        local outs = assert(io.open(fname, "w+b"))
        for _, line in ipairs(output) do
            outs:write(line, '\n')
        end
        outs:close()
    end
end

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
