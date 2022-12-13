--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] 

local tinsert = table.insert
local strlen = string.len

--- Extract documentation from Lua files.
--
return function(node)
    message(STATUS, "extracting %q...", node.file)
    node.type = "source"

    --- we only parse comments
    local comment
    local state, pattern
    local lineno = 1
    for line in io.lines(node.path) do
        if state == 'longcomment' then
            local bpos, epos = line:find(pattern)

            if bpos then
                if bpos > 1 then
                    tinsert(comment, {line:sub(1, bpos), lineno, epos})
                end
                comment = nil
                state = nil
            else
                tinsert(comment, {line, lineno, epos})
            end
        elseif state == 'longstring' then
            local bpos, epos = line:find(pattern)
            if bpos then
                state = nil
            end
        else
            local bpos, epos = line:find("[ \t]*%-%-")
            if bpos == 1 then -- only deal with pure comments
                -- check long comment
                local blong, elong = line:find("[[][^[]*[[]")

                if blong == 3 then
                    epos = elong

                    state = 'longcomment'
                    pattern = '[]]' .. line:sub(blong + 1, elong - 1) .. '[]]'
                end
                epos = epos + 1

                -- the comment text
                local text = line:sub(epos)

                -- create comment block if needed
                -- (otherwise consecutive...)
                if not comment then
                    comment = {
                        tag = 'comment'
                    }
                    tinsert(node, comment)

                    if strlen(text) == 0 then
                        text = nil
                    end
                end

                if text then
                    tinsert(comment, {text, lineno, epos})
                end
            else
                -- swallow long strings
                bpos, epos = line:find("[[][^[]*[[]")
                if bpos then
                    state = 'longstring'
                    pattern = '[]]' .. line:sub(bpos + 1, epos - 1) .. '[]]'
                end

                comment = nil
            end

        end

        lineno = lineno + 1
    end
end
