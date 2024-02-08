--[[
    Copyright (C) 2022-2024 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[[>>[amend.api.lua.string] `string` library
]]
--- `string.any(s, tbl, exact)`
-- Match elements from a table.
--
-- @param
--      s                   The string.
--      tbl                 Table with regex-patterns.
--      exact [optional]    If ''true'', the matched part must be identical to the full string.
--
-- @returns
--      Matched string, otherwise ''nil''.
--
function string.any(s, tbl, exact)
    for _, p in ipairs(tbl) do
        local m = s:match(p)
        if m then
            if not exact or (m == s) then
                return m
            end
        end
    end
end

--- `string.trim(s)`
-- Trim string.
function string.trim(s)
    s = s and s:match "^%s*(.-)%s*$"
    return s and s:gsub("[\n]+$", "\n")
end

--- `string.title(s)`
-- Make string "titlecase".
function string.title(s)
    return s:sub(1, 1):upper() .. s:sub(2, -1)
end

--- `string.untitle(s)`
-- Undo "titlecase".
function string.untitle(s)
    return s:sub(1, 1):lower() .. s:sub(2, -1)
end

--- `string:split(sSeparator, nMax, bRegexp)`
-- String split.
-- See http://lua-users.org/wiki/SplitJoin
function string:split(sSeparator, nMax, bRegexp)
    assert(sSeparator ~= "")
    assert(nMax == nil or nMax >= 1)

    local aRecord = {}

    if self:len() > 0 then
        local bPlain = not bRegexp
        nMax = nMax or -1

        local nField, nStart = 1, 1
        local nFirst, nLast = self:find(sSeparator, nStart, bPlain)
        while nFirst and nMax ~= 0 do
            aRecord[nField] = self:sub(nStart, nFirst - 1)
            nField = nField + 1
            nStart = nLast + 1
            nFirst, nLast = self:find(sSeparator, nStart, bPlain)
            nMax = nMax - 1
        end
        aRecord[nField] = self:sub(nStart)
    end

    return aRecord
end

--- `string.wrap(s, col)`
-- Wrap string (each line is detected as a paragraph) to specified column-width.
function string.wrap(s, max_column, no_concat)
    assert(type(s) == "string", "expected a string")
    max_column = max_column or 79

    local paragraphs = s:split("\n")
    local N = #paragraphs
    local res = {}
    for i, l in ipairs(paragraphs) do
        local column = 1
        local line = ""
        local words = l:split(" ")
        for wi, wv in ipairs(words) do
            local wlen = wv:len()
            if wlen > 0 then
                if wi == 1 then
                    line = wv
                    column = wlen + 1
                else
                    if column + wlen >= max_column then
                        table.insert(res, line)
                        line = wv
                        column = wlen + 1
                    else
                        line = line .. " " .. wv
                        column = column + 1 + wlen
                    end
                end
            end
        end
        table.insert(res, line)

        if i < N then
            table.insert(res, "")
        end
    end

    if res[#res]:len() == 0 then
        table.remove(res)
    end

    if no_concat then
        return res
    else
        return table.concat(res, "\n")
    end
end

-- [[ MODULE ]]
message(TRACE[10], "extended string library")
return string
