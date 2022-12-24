% Amend

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

# -- update source copyright

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

## API


### Version

#### `VERSION`

### Globals


 The following global variables are set or determined at startup:

      EXECDIR             Path, where ''amend.lua'' was started.
      ROOTDIR             Project root (where ''.amend/project.lua'' was found).
      PROJECTFILE         Full path to the ''.amend/project.lua'' file.

 To separate source from other files, the variable

      IGNORE              Files or directories generally to ignore.

 is populated (regular expressions) at startup. This list is automatically
 extended if ''amend'' finds the following files, containing wild-card patterns,
 in the ''ROOTDIR'':

      .amend/ignore
      .gitignore

 The project file contains the general configuration variables:

      PROJECT             Project settings.
      CONFIG              Amend settings.
      TOOLS               System tools (see 'amend/tools.lua')
      PATHS               Additional module paths.

 See [amend.api.project] for details.

### Project configuration


#### Projects.

FIXME

##### API


###### Configuration.

FIXME

###### Settings.

FIXME

###### Tools.

FIXME

### Components


#### Components

"Amend components" can be created anywhere in the source code tree in a sub-folder ".amend".
The first line of such a component starts with a shebang of the format

    #![indicator]<component-name> [<argument-description>] -- <component-description>

where the 'indicator' is

    *           The component is always executed (even if option 'all' is not used).
    _           This defines a "hidden" component (which is only executed as dependency).

If the <indicator> is omitted, the component behaves like a command and is executed only on 
explicit request.

Example:

    #!*check [<arguments>] Check system.
    depends "check-os"
    verbose "Checking system"

    assert(os.command("cmake --version"))

    -- ...
    

##### `help()`

##### `shebang()`

##### `scandir()`

##### `find()`

##### `_run()`

##### `run()`

##### `depends '<name>'`

### Tools


#### Tools.

FIXME

### Utilities


#### Message logging

##### `VERBOSE`

##### Verbosity levels.

##### ERROR

##### WARNING

##### NOTICE

##### STATUS

##### INFO

##### DEBUG

##### ERROR

##### `message()`

##### `verbosity [{<level>}]`

### Lua extensions


### Tools


#### External tools.

FIXME

##### API


###### CMake support.

--

####### `parse_args(options, one_value_keywords, multi_value_keywords, ...)`

####### `update(configfile)`

####### `check()`

###### Git support.

--

####### `check()`

###### C++ support.

--
--

## License


### Copyright

Copyright (C) 2021-2022 Yogev Sawa


### License

#### UNLICENSE

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>
