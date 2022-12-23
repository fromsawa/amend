--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[[>>[amend.api.util.csv] CSV-file tools.
]]
local mod = {}

local strim = string.trim
local slen = string.len
local tinsert = table.insert

--- `csv.load(fname, [opts])`
--  Read a CSV file.
-- @param 
--      fname       File name.
--      opts        Options.
--
-- Options:
-- >    {
-- >        comment = '<pattern>',
-- >        separator = 'separator',
-- >        columns = { <column-names-list> },   
-- >        filter = <item-filter-function>
-- >    }
--
function mod.load(fname, opts)
    local res = {}

    -- defaults
    opts = opts or {}

    local comment_pattern = opts.comment or "^#"
    local separator = opts.separator or ";"
    local columns = opts.columns
    local filter = opts.filter or string.trim

    local f = assert(io.open(fname, "rb"))
    local lineno = 1
    for line in f:lines() do
        line = filter(line)
        if not line or slen(line) == 0 then
            -- ignore
        elseif line:match(comment_pattern) then
            -- ignore
        else
            local t = line:split(separator)
            -- io.dump(t, {key = "LINE"})
            if columns then
                local c = {}
                for i, s in ipairs(t) do
                    if not columns[i] then
                        io.printf("In line %d: title for column %d is nil.\n", lineno, i)
                        os.exit(1)
                    end
                    
                    local colname = columns[i]
                    local colvalue = t[i]:trim()
                    if colname:match("[.]") then
                        local coltree = colname:split('.')
                        local tmp = c
                        for i,colkey in ipairs(coltree) do
                            if i < #coltree then
                                tmp[colkey] = tmp[colkey] or {}
                                tmp = tmp[colkey]
                            else
                                tmp[colkey] = colvalue
                            end
                        end
                    else
                        c[colname] = colvalue
                    end
                end
                tinsert(res, c)
            else
                for i, s in ipairs(t) do
                    t[i] = t[i]:trim()
                end
                tinsert(res, t)
            end
        end

        lineno = lineno + 1
    end

    return res
end

-- [[ MODULE ]]
message(TRACE[10], "loaded util.csv module")
return mod
