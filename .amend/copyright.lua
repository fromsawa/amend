#!copyright [<year>] -- update source copyright
message "Updating copyrights..."

--[[>>[amend.example.copyright] Updating the copyright.

TODO

]]

local symbol = "(C)" -- copyright symbol
local pattern = {"Yogev Sawa"} -- author pattern(s)
local year = tonumber(OPTIONS[1] or os.date("%Y")) -- current year

function fix_copyright(fname)
    -- read file
    local txt = io.readall(fname)
    if not txt then
        return
    end

    -- find and check copyright
    local bpos, epos, copyright, sym, year_from, year_to, author =
        txt:find("(Copyright)[ ]+([^0-9]*)[ ]+([0-9]+)[ ]*[%-]-[ ]*([0-9]*)[ ]+([^\n]+)")

    -- edit files (if applicable)
    if table.has(pattern, author) then
        year_from = tonumber(year_from)
        year_to = tonumber(year_to)

        if ((year_to or year_from) ~= year) or (sym ~= symbol) then
            local years = string.format("%d", year)
            if year_from ~= year then
                years = string.format("%d-%d", year_from, year)
            end
            message(STATUS, "    updating %s", fname)

            local before, after = txt:sub(1, bpos - 1), txt:sub(epos + 1, -1)
            local newcopyright = string.format("%s %s %s %s", copyright, symbol, years, author)

            f = assert(io.open(fname, "w"))
            f:write(before, newcopyright, after)
            f:close()
        end
    end
end

fs.dodir(
    ".",
    function(item)
        fix_copyright(item[0])
    end,
    {
        exclude = IGNORE,
        extension = {".lua", ".cmake", ".md"},
        include = {},
        recurse = true
    }
)

--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
