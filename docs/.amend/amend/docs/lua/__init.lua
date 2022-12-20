--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] local M = {}

local tinsert = table.insert
local tremove = table.remove
local tmake = table.make
local strlen = string.len

--- File extensions.
local extensions = {".lua"}

--- Extract documentation from Lua files.
--
-- **Note**: At the point of writing, only comments are extracted.
-- 
local function parse(data)
    message(STATUS, "extracting %q...", data.file)

    local fragment

    --- get all comments
    local state, pattern
    local source = data.file
    local line = 1
    for text in io.lines(data.path) do
        if state == 'longcomment' then
            local bpos, epos = text:find(pattern)

            if bpos then
                if bpos > 1 then
                    tinsert(fragment, {
                        source = source,
                        line = line,
                        column = bpos,
                        text = text:sub(1, bpos)
                    })
                end
                fragment = nil
                state = nil
            else
                tinsert(fragment, {
                    source = source,
                    line = line,
                    column = 1,
                    text = text
                })
            end
        else
            local bpos, epos = text:find("[ \t]*%-%-")
            if bpos == 1 then -- only deal with pure comments
                -- check long comment
                local blong, elong = text:find("[[][^[]*[[]")

                if blong == 3 then
                    epos = elong

                    state = 'longcomment'
                    pattern = '[]]' .. text:sub(blong + 1, elong - 1) .. '[]]'
                    fragment = nil
                end
                epos = epos + 1

                -- the comment text
                text = text:sub(epos)

                -- create comment block if needed
                -- (otherwise consecutive...)
                if not fragment then
                    fragment = {
                        tag = 'fragment'
                    }
                    tinsert(data, fragment)

                    if strlen(text) == 0 then
                        text = nil
                    end
                end

                if text then
                    -- unindent
                    if text:match("^[%s]$") or text:match("^[%s]") then
                        text = text:sub(2)
                        epos = epos + 1
                    end

                    -- add line
                    tinsert(fragment, {
                        source = source,
                        line = line,
                        column = epos,
                        text = text
                    })
                end
            else
                fragment = nil
            end

        end

        line = line + 1
    end

    data.tag = 'source'
end

-- [[ MODULE ]]
M.extensions = extensions
M.parse = parse
return M
