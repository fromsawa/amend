# Amend 

Source code revision tool.

## Description

A lot of software is accompanied by additional developer tools to update or check
certain features of the source code. This may, for example, include updating a date,
such as in the copyright notice. Another example is the [Lua](https://www.lua.org) 
[source code](https://github.com/lua) itself, 
where you encounter [comments](https://github.com/lua/lua/blob/master/lopcodes.h), 
such as:

    ** Grep "ORDER OP" if you change these enums. Opcodes marked with a (*)
    ** has extra descriptions in the notes after the enumeration.

The author(s) of ''amend'' have also repeatedly reinvented wheels (read utilities)
to prepare software releases for each new software they were working on. The ''amend''
package is (a possibly [futile](https://xkcd.com/927/)) attempt to create a generic
tool for such purposes: yet, the author(s) are using it succesfully in several projects
and, therefore, disclose it to the public.

## Example

To update copyright information in a project this [script](https://github.com/fromsawa/amend/blob/main/.amend/copyright.lua)
is used within `amend`:

```.lua
#!copyright [<year>] -- update source copyright
message "Updating copyrights..."

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
```

To update copyright information, one needs to run `amend copyright` (see `amend --help` for further information).
