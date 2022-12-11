--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[[>>[amend.api.lua.io] #+ IO
]]
local stdout = io.stdout
local sformat = string.format

-->> ##+ `io.printf(...)`
-- Equivalent to C's ''printf''
function io.printf(...)
    return stdout:write(sformat(...))
end

local keywords = {
    ["and"] = true,
    ["break"] = true,
    ["do"] = true,
    ["else"] = true,
    ["elseif"] = true,
    ["end"] = true,
    ["false"] = true,
    ["for"] = true,
    ["function"] = true,
    ["goto"] = true,
    ["if"] = true,
    ["in"] = true,
    ["local"] = true,
    ["nil"] = true,
    ["not"] = true,
    ["or"] = true,
    ["repeat"] = true,
    ["return"] = true,
    ["then"] = true,
    ["true"] = true,
    ["until"] = true,
    ["while"] = true
}

-- Get sorted list of keys.
local prec = {
    integer = 0,
    float = 1,
    string = 2,
    any = 99
}
local function getkeys(t)
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end

    table.sort(
        keys,
        function(a, b)
            local ta, tb = math.type(a) or type(a), math.type(b) or type(b)
            if ta == tb then
                return a < b
            else
                ta = prec[ta] or prec.any
                tb = prec[tb] or prec.any

                return ta < tb
            end
        end
    )

    return keys
end

-- Escape string.
local function escape(s, q)
    -- FIXME there's more to escape
    s = s:gsub('([\'"])', "\\%1")
    return s
end

local function io_dump(value, options)
    local stream = options.stream
    local indent = options.indent
    local level = options.level
    local key = options.key
    local quoted = options.quoted
    local always_index = options.index

    local format = options.format or {}
    local fmt_integer = format.integer or "%d"
    local fmt_number = format.number or "%g"

    local function _tostr(d)
        if type(d) == "number" then
            if math.type(d) == "integer" then
                return string.format(fmt_integer, d)
            else
                return string.format(fmt_number, d)
            end
        end
        return tostring(d)
    end

    -- indent
    stream:write(string.rep(indent, level))

    -- output key
    if key then
        local K = type(key)
        if K == "string" then
            if not quoted and key:match("^[_a-zA-Z][_a-zA-Z0-9]*$") and not keywords[key] then
                stream:write(sformat("%s = ", _tostr(key)))
            else
                stream:write(sformat("[%q] = ", escape(_tostr(key))))
            end
        else
            stream:write(sformat("[%s] = ", _tostr(key)))
        end
    end

    -- output value
    local t = type(value)
    if t == "table" then
        local isempty = true
        for _, _ in pairs(value) do
            isempty = false
            break
        end

        if isempty then
            stream:write("{}")
        else
            stream:write("{\n")

            ks = getkeys(value)
            for _, k in ipairs(ks) do
                if math.type(k) == "integer" and k >= 1 and k <= #value and not always_index then
                    io_dump(
                        value[k],
                        {
                            indent = indent,
                            level = level + 1,
                            stream = stream,
                            format = format,
                            quoted = quoted,
                            always_index = always_index
                        }
                    )
                else
                    io_dump(
                        value[k],
                        {
                            key = k,
                            indent = indent,
                            level = level + 1,
                            stream = stream,
                            format = format,
                            quoted = quoted,
                            always_index = always_index
                        }
                    )
                end
            end

            stream:write(string.rep(indent, level))
            stream:write("}")
        end
    elseif t == "string" then
        -- quotes
        local q = {'"', '"'}

        local str = _tostr(value)
        if str:match("\n") then
            local neq = 0
            while true do
                local eq = string.rep("=", neq)
                if (not str:match("[[]" .. eq .. "[[]")) and (not str:match("[]]" .. eq .. "[]]")) then
                    q = {string.format("[%s[\n", eq), string.format("]%s]", eq)}
                    if str:sub(-1, -1) ~= "\n" then
                        str = str .. "\n"
                    end
                    break
                else
                    neq = neq + 1
                end
            end
        else
            str = escape(str)
        end

        stream:write(q[1], str, q[2])
    else
        stream:write(_tostr(value))
    end

    if level > 0 then
        stream:write(",\n")
    else
        stream:write("\n")
    end
end

-->> ##+ `io.dump(value, options)`
-- Dump value.
-- ::args
--      value                   Value to stream to output.
--      options [optional]      Display options.
--
-- This function dumps value to an output stream.
--
-- The ''options'' is a table, that may contain the following fields:
--
--      stream          Output stream (default: io.stdout).
--      indent          Indentation string.
--      level           Indentation level.
--      key             Table key.
--      prefix          Prefix for output (usually only for adding a "return" statement).
--      quoted          Always output keys in the ["quoted"] format (default: false)
--
function io.dump(value, options)
    -- defaults
    options = options or {}
    options.stream = options.stream or io.stdout
    options.indent = options.indent or "    "
    options.level = options.level or 0
    options.format = options.format or {}

    -- dump
    if options.prefix then
        options.stream:write(string.rep(options.indent, options.level))
        options.stream:write(options.prefix .. " ")
    end
    return io_dump(value, options)
end

-->> ##+ `io.readall(fname)`
-- Read file.
-- ::args
--      fname           The file name.
-- ::returns text, error
function io.readall(fname)
    local f = io.open(fname)
    return f:read("a")
end

-->> ##+ `io.command(program, ...)`
-- Execute command and read output.
-- ::args
--          program                 The command to execute (as format string).
--          ...                     Format options.
-- ::returns output,error
--      FIXME
function io.command(program, ...)
    local cmd = string.format(program, ...)
    local f, e = io.popen(cmd)
    if not f then
        return nil, e
    end

    local txt, err = f:read("a")
    f:close()

    return txt, err
end

-- [[ MODULE ]]
return io
