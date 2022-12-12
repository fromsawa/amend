#!copyright [<year>] -- update source copyright
message "Updating copyrights..."

local symbol = "©" -- copyright symbol
local pattern = {"Yogev Sawa"} -- copyright name pattern(s)
local year = tonumber(OPTIONS[1] or os.date("%Y")) -- year

function fix_copyright(fname)
    -- read file
    local f = assert(io.open(fname))
    local txt = f:read("*a")
    f:close()

    -- find and check copyright
    local bpos, epos, copyright, sym, year_from, year_to, name =
        txt:find("(Copyright)[ ]*([^0-9]*)[ ]*([0-9]+)[-]*([0-9]*)[ ]+([^\n]+)")

    -- edit files (if applicable)
    if table.has(pattern, name) then
        year_from = tonumber(year_from)
        year_to = tonumber(year_to)

        if year_from ~= year then
            if not year_to or year_to ~= year then
                message(STATUS, "    updating %s\n", fname)

                local before, after = txt:sub(1, bpos - 1), txt:sub(epos + 1, -1)

                f = assert(io.open(fname, "w"))
                f:write(before)
                f:write(string.format("%s %s %d-%d %s", copyright, symbol, year_from, year, name))
                f:write(after)
                f:close()
            end
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
