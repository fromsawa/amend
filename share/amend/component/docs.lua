--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[[
    Amend's internal markdown documentation generator.
]]
local docs = {}
local template = "amend/docs/README.in.md"
local readme = "amend/README.md"

local tinsert = table.insert
local slen = string.len

local function parsemd(fname)
    print("parsing", fname)
    local f = assert(io.open(fname))

    local section = nil -- Current section (persists until changed).
    local comment = nil -- Comment pattern (long comments).
    local record = false -- Continue adding lines to documentation section.

    for line in f:lines() do
        if line:match("^%s*[-][-]") then
            line = line:match("^%s*[-][-](.*)$") -- remove comment start pattern

            if line:sub(1, 1) == "[" then -- check for long comment
                -- long comment
                local pattern, rest = line:match("^[[]([^[]*)[[](.*)$")
                if pattern then
                    comment = pattern
                    line = rest
                end
            else
                if line:sub(1,1):match("%s") then
                    line = line:sub(2)
                end
            end

            if line:sub(1, 2) == ">>" then -- check for documentation content
                line = line:sub(3)

                -- check for index
                local index, rest = line:match("^[[]([^]]*)[]]%s*(.*)$")
                if index then
                    print("- found section '" .. index .. "'")
                    section = index
                    docs[section] = docs[section] or {}

                    if slen(rest) > 0 then
                        line = rest
                    else
                        line = nil
                    end
                end

                if line then
                    line = line:trim()
                end

                -- we're "recording"
                record = true
            end
        else
            if comment then
                if line:match("^%s*[]]" .. comment .. "[]]") then
                    -- reached end of a long comment
                    -- note: --]] is NOT detected, ']]' pattern must be on it's own
                    comment = nil
                    record = false
                end
            else
                record = false
            end
        end

        if record and line then
            assert(section, "document does not have a section defined")

            local heading = line:match("^%s*#")
            if heading then
                tinsert(docs[section], '')
            end
            tinsert(docs[section], line)
            if heading then
                tinsert(docs[section], '')
            end
        end
    end
    f:close()
end

local function update_amend_docs()
    local dir = fs.parts(OPTIONS.invocation)

    -- parse files
    parsemd(OPTIONS.invocation)
    fs.dodir(
        fs.concat(dir, "amend"),
        function(t)
            parsemd(t[0])
        end,
        {
            exclude = {table.unpack(IGNORE)},
            extension = {".lua"},
            mode = "file",
            recurse = true
        }
    )

    -- generate document
    local ins = assert(io.open(fs.concat(dir, template)))
    local outs = assert(io.open(fs.concat(dir, readme), "wb"))

    local function emit(l)
        outs:write(l, "\n")
    end

    local heading_pattern = nil
    for line in ins:lines() do
        local hpat = line:match("^(#+)")
        if hpat then
            heading_pattern = hpat
        end

        local inc = line:match("<<[[]([^]]+)[]]")
        if inc then
            if docs[inc] then
                for _, txt in ipairs(docs[inc]) do
                    if txt:match("^#+[+]%s") then
                        txt = txt:gsub("^(#+)[+]", "%1"..heading_pattern)
                    end

                    if txt:match("::args") then
                        txt = txt:gsub("::args", "\n**Arguments:**\n")
                    end

                    if txt:match("::returns") then
                        txt = txt:gsub("::returns", "\n**Returns:** ")
                    end

                    emit(txt)
                end
            end
        else
            emit(line)
        end
    end

    ins:close()
    outs:close()
end

return {
    name = "amend-docs", -- The component name.
    invocation = nil, -- Invocation string (part of she-bang).
    comment = "update amend documentation", -- Component description (shown by help).
    scope = "internal", -- Component scope: 'builtin', 'user', 'hidden' or 'internal'.
    done = false, -- Flag if component has been already executed.
    always = false, -- Flag, if component should be executed always.
    arguments = {
        min = 0, -- Minimal number of arguments.
        max = 999 -- Maximum number of arguments (default: take all or ignore).
    },
    component = update_amend_docs -- Function or script.
}
