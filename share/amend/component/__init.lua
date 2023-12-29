--[[
    Copyright (C) 2022-2023 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]

--[===[>>[amend.api.components] Components

"Amend components" can be created anywhere in the source code tree in a sub-folder ".amend".
The first line of such a component starts with a shebang of the format

    #![indicator]<component-name> [<argument-description>] -- <component-description>

where the 'indicator' is

    *           The component is always executed (even if option 'all' is not used).
    _           This defines a "hidden" component (which is only executed as dependency).

If the \<indicator\> is omitted, the component behaves like a command and is executed only on 
explicit request.

Example:

    #!*check [<arguments>] Check system.
    depends "check-os"
    verbose "Checking system"

    assert(os.command("cmake --version"))

    -- ...
    
]===]
local mod = {}

COMPONENTS = {}
require "amend.builtin"
require "amend.message"

local printf = io.printf
local tunpack = table.unpack
local tinsert = table.insert
local tremove = table.remove
local tconcat = table.concat
local tunpack = table.unpack
local sformat = string.format

--- `component.help()`
--
-- Print components help.
--
local function help()
    printf("Builtins:\n")
    for _, v in ipairs(COMPONENTS) do
        if v.scope == "builtin" then
            local cmpnt = v.invocation or v.name
            printf("    %-28s %s\n", cmpnt, v.comment or "")
        end
    end

    printf("\nCompontents:\n")
    local lastcmpnt
    for _, v in ipairs(COMPONENTS) do
        if v.scope == "user" then
            local cmpnt = v.invocation or v.name
            local space = v.always and "*" or " "

            if lastcmpnt == cmpnt then
                cmpnt = ""
            end
            printf("   %s%-28s %s\n", space, cmpnt, v.comment or "")
            lastcmpnt = cmpnt
        end
    end
end

-- Get parsed "shebang" from file.
local function shebang(fname)
    for line in io.lines(fname) do
        if line:match("^#!") then
            local cmd, comment = line:match("^#!(.*)%s+[-][-]%s+(.*)")
            if not cmd then
                return {tunpack(line:sub(3):split(" "))}
            else
                cmd = cmd:gsub("%s+", " ") -- cleanup spaces
                return {comment = comment:trim(), tunpack(cmd:split(" "))}
            end
        end
        break
    end
end

-- Scan users '.amend' dir.
local function scandir(dname)
    fs.dodir(
        dname,
        function(t)
            local sb = shebang(t[0])
            if sb then
                if not sb.comment then
                    printf("IGNORING - invalid component declaration: %s\n", fs.relpath(t[0], ROOTDIR))
                else
                    local res = {
                        name = nil,
                        comment = sb.comment,
                        scope = "user",
                        path = fs.parts(t[1]),
                        component = t[0]
                    }

                    -- component name
                    local name = sb[1]
                    local firstc = name:sub(1, 1)
                    if firstc == "*" then
                        res.always = true
                        name = name:sub(2)
                    elseif firstc == "_" then
                        res.scope = "hidden"
                        name = name:sub(2)
                    elseif not firstc:match("[a-zA-Z]") then
                        error("invalid component name: '" .. name .. "'")
                    end
                    res.name = name

                    sb[1] = name
                    res.invocation = tconcat(sb, " ")

                    -- arguments
                    local nargs = #sb
                    res.arguments = {
                        min = nargs - 1,
                        max = nargs - 1
                    }
                    local optional = false
                    for i = 2, nargs do
                        local a = sb[i]

                        if a:match("^[[][^]]+[]]$") then
                            if not optional then
                                res.arguments.min = i - 2
                            end
                            optional = true
                        end

                        if a:match("[.][.][.]") then
                            res.arguments.max = 999
                        end
                    end

                    tinsert(COMPONENTS, res)
                    message(TRACE[2], "    FOUND %s", t[0])
                end
            end
        end,
        {exclude = IGNORE, mode = "file"}
    )
end

--- `component.find()`
--
-- Find all components in the project tree.
--
local function find()
    message(TRACE, "COMPONENT FIND")
    fs.dodir(
        ROOTDIR,
        function(t)
            local amenddir = fs.concat(t[0], ".amend")
            if fs.attributes(amenddir) then
                scandir(amenddir)
            end
            return true
        end,
        {exclude = IGNORE}
    )
end

-- Run the component (if not yet done)
local function _run(t)
    if not t.done then
        t.done = true

        -- execute in respective directory
        if t.path then
            fs.pushd(t.path)
        end

        -- check arguments
        local nargs = #OPTIONS
        if nargs < t.arguments.min then
            printf("%q expects at least %d argument(s)\n", t.name, t.arguments.min)
            os.exit(1)
        end
        if nargs > t.arguments.max then
            printf("%q expects at max %d argument(s)\n", t.name, t.arguments.max)
            os.exit(1)
        end

        -- do it
        local T = type(t.component)
        if T == "function" then
            message(TRACE, '    FUNCTION: %q\n', tostring(t.component))
            t.component()
        elseif T == "string" then
            message(TRACE, '    FILE: %q\n', tostring(t.component))
            dofile(t.component)
        else
            error "internal error: component entry has unexpected type"
        end

        if t.path then
            fs.popd()
        end
    else
        message(TRACE, '    ALREDY DONE\n')
    end
end

--- `component.run(name)`
--
-- Run a "component".
--
local function run(name)
    message(TRACE, "COMPONENT run(%s)", name)

    -- run 'always'
    for _, t in ipairs(COMPONENTS) do
        if t.always then
            message(TRACE, '    ALWAYS: %s', t.name)
            _run(t)
        end
    end

    -- run requested
    local wasrun = false
    for _, t in ipairs(COMPONENTS) do
        if name == 'default' then
            wasrun = true
        elseif name == t.name then
            message(TRACE, '    REQUEST: %s', t.name)
            _run(t)
            wasrun = true
        end
    end

    if not wasrun then
        message(NOTICE, [[
Component not found: %q.
Use 'help' for more information.
]], name)
    end
end

--- `depends '<name>'`
--
-- Include a dependecy.
--
function depends(name)
    message(TRACE, 'depends(%s)', name)
    for _, c in ipairs(COMPONENTS) do
        if c.name == name then
            message(TRACE, "    file %q", c.component or "nil")
            dofile(c.component)
            return
        end
    end

    io.printf("Unmet component dependency: %s not found\n", name)
    os.exit(1)
end

-- [[ MODULE ]]
mod.help = help
mod.find = find
mod.run = run

message(TRACE[10], "loaded component module")
return mod
