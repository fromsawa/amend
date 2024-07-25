--[[
    Copyright (C) 2022-2024 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --

--[[>>[amend.api.lua.io] ``io`` library
]] --

local stdout = io.stdout
local sformat = string.format
local tconcat = table.concat
local tinsert = table.insert

--- `io.printf(...)`
--
-- Equivalent to C's ''printf''
--
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
local prec_array = {
    integer = 0,
    float = 1,
    string = 2,
    any = 99
}
local prec_key = {
    string = 0,
    any = 1,
    integer = 99
}
local function getkeys(t, index_last)
    local prec = prec_array
    if index_last then
        prec = prec_key
    end

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
    s = s:gsub('([\'"\\])', "\\%1")
    return s
end

local function io_dump(value, options)
    local stream = options.stream
    local indent = options.indent
    local level = options.level
    local key = options.key
    local quoted = options.quoted
    local always_index = options.index
    local visited = options.visited
    local nocomma = options.nocomma
    local root = options.root
    local indexes = options.indexes

    local format = options.format or {}
    local fmt_integer = format.integer or "%d"
    local fmt_number = format.number or "%g"

    local function findobj(obj, tbl, res, visited)
        visited =
            visited or
            {
                [_G.package] = true
            }

        for k, v in pairs(tbl) do
            if not visited[v] then
                if v == obj then
                    table.insert(res, k)
                    return true
                elseif type(v) == "table" then
                    visited[v] = true
                    table.insert(res, k)

                    if findobj(obj, v, res, visited) then
                        return true
                    end

                    table.remove(res)
                end
            end
        end

        return false
    end

    local function fnname(d)
        local keys = {}
        if findobj(d, _G, keys) then
            return table.concat(keys, ".")
        end
        return tostring(d)
    end

    local function _tostr(d)
        if type(d) == "number" then
            if math.type(d) == "integer" then
                return string.format(fmt_integer, d)
            else
                return string.format(fmt_number, d)
            end
        elseif type(d) == "function" then
            return fnname(d)
        end

        if type(d) == 'table' then
            local mt = getmetatable(d)
            if mt and mt.tokey then
                return mt.tokey(d)
            end
        end
        return tostring(d)
    end

    -- indent
    if not options.nodump then
        stream:write(string.rep(indent, level))
    end

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
        if visited[value] then
            local name = {"@" .. options.root.key}
            if not findobj(options.root.value, value, name) then
                name = {"_G"}
                if not findobj(_G, value, name) then
                    name = {"@"}
                end
            end

            stream:write(tconcat(name, "."))
        else
            visited[value] = true

            local isempty = true
            for _, _ in pairs(value) do
                isempty = false
                break
            end

            local mt = getmetatable(value)
            if mt and mt.__dump and not options.nodump then
                visited[value] = false

                mt.__dump(
                    value,
                    {
                        indent = indent,
                        level = level,
                        stream = stream,
                        format = format,
                        quoted = quoted,
                        always_index = always_index,
                        indexes = indexes,
                        visited = visited,
                        root = root,
                        nocomma = false,
                        nodump = true
                    }
                )
            elseif isempty then
                stream:write("{}")
            else
                stream:write("{\n")

                local indexes_last = isobject(value)
                if indexes == 'first' then
                    indexes_last = false
                elseif indexes == 'last' then
                    indexes_last = true
                end

                local ks = getkeys(value, indexes_last)
                for i, k in ipairs(ks) do
                    if math.type(k) == "integer" and k >= 1 and k <= #value and not always_index then
                        io_dump(
                            value[k],
                            {
                                indent = indent,
                                level = level + 1,
                                stream = stream,
                                format = format,
                                quoted = quoted,
                                always_index = always_index,
                                indexes = indexes,
                                visited = visited,
                                root = root,
                                nocomma = (i == #ks)
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
                                always_index = always_index,
                                indexes = indexes,
                                visited = visited,
                                root = root,
                                nocomma = (i == #ks)
                            }
                        )
                    end
                end

                stream:write(string.rep(indent, level))
                stream:write("}")
            end
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

    -- comma and newline
    if not options.nodump then
        if not nocomma then
            stream:write(",")
        end

        stream:write("\n")
    end
end

--- `io.dump(value, options)`
--
-- Dump `value`.
--
-- @param
--      value                   Value to stream to output.
--      options [optional]      Display options.
--
-- This function dumps a `value` to an output stream.
--
-- The ''options'' is a table, that may contain the following fields:
--
--      stream          Output stream (default: io.stdout).
--      file            Output file name.
--      indent          Indentation string.
--      level           Indentation level.
--      key             Table key.
--      prefix          Prefix for output (usually only for adding a "return" statement).
--      quoted          Always output keys in the ["quoted"] format (default: false)
--      indexes         Index sorting ("first" or "last"; default: last for objects, first otherwise)
--
function io.dump(value, options)
    -- defaults
    options = options or {}
    options.stream = options.stream or io.stdout
    if options.file then
        options.stream = assert(io.open(options.file, "w"))
    end
    options.indent = options.indent or "    "
    options.level = options.level or 0
    options.format = options.format or {}
    options.nocomma = (options.level == 0)
    options.visited = options.visited or {}

    options.root = {
        -- internal
        value = value,
        key = options.key or ""
    }

    -- prefix (if applicable)
    if options.prefix then
        if not options.nodump then
            options.stream:write(string.rep(options.indent, options.level))
        end
        options.stream:write(options.prefix .. " ")
    end

    -- dump
    local retval = io_dump(value, options)
    if options.file then
        options.stream:close()
    end
end

--- `io.readall(fname)`
--
-- Read file.
--
-- @param
--      fname           The file name.
--
-- @returns text, error
function io.readall(fname)
    local f = assert(io.open(fname))
    return f:read("a")
end

--- `io.sed(fname, pattern, replacement, options)`
--
-- Replace file contents using a pattern.
--
-- @param
--      fname           The file name.
--      pattern         A 'gsub' pattern.
--      replacement     Replacement string.
--      options         Currently not supported.
--
function io.sed(fname, pattern, replace, opts)
    message(TRACE, "sed(%q,%q,%q)", fname, pattern, replace)

    opts = opts or {}
    local dryrun = opts.dryrun

    local output = {}
    local modified

    local ins = assert(io.open(fname))
    if dryrun then
        modified = {}
        for line in ins:lines() do
            if line:match(pattern) then
                local rep = line:gsub(pattern, replace)
                tinsert(modified, {[fname] = {line, rep}})
            end
        end
    else
        local ins = assert(io.open(fname))
        for line in ins:lines() do
            if line:match(pattern) then
                local repl = line:gsub(pattern, replace)
                tinsert(output, repl)
                modified = true
            else
                tinsert(output, line)
            end
        end
    end
    ins:close()

    if dryrun then
        for _, t in ipairs(modified) do
            local fname, diff = next(t)

            message(INFO, "%s", fs.relpath(fname, ROODIR))
            message(INFO, "--- %s", diff[1])
            message(INFO, "+++ %s", diff[2])
        end
    else
        local outs = assert(io.open(fname, "w+b"))
        for _, line in ipairs(output) do
            outs:write(line, '\n')
        end
        outs:close()
    end
end

--- `io.command(program, ...)`
--
-- Execute command and read output.
--
-- @param
--          program                 The command to execute (as format string).
--          ...                     Format arguments.
--
-- @returns output,error
--
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
message(TRACE[10], "extended io library")
return io
