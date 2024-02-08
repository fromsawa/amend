--[[
    Copyright (C) 2022-2024 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --
--[[>>[amend.api.util.rdbl.types] Types.
]] --
local M = require "amend.util.rdbl.version"

local mnan = 0 / 0
local minf = 1 / 0
local mtointeger = math.tointeger
local mtype = math.type
local sformat = string.format
local tinsert = table.insert
local tremove = table.remove
local tconcat = table.concat
local tsort = table.sort
local utf8codes = utf8.codes
local utf8char = utf8.char

--- `ORDER`
--
-- Element order.
--
local ORDER = {}
M.ORDER = ORDER

--- `NULL`
--
-- Non-destructive ''nil''.
--
-- Empty values, are represented as 'null', otherwise, in Lua,
-- the table entry would be deleted.
--
local NULL = {}
M.NULL = NULL

--- `isnull`
--
-- Check if 'null'.
--
local function isnull(t)
    return t == NULL
end
M.isnull = isnull

--- `isinteger`
--
--  Check if value is an integer.
--
local function isinteger(x)
    return mtype(x) == "integer"
end
M.isinteger = isinteger

--- `typeof`
--
-- Get type of a value.
--
-- @param
--      x       Value to get type of.
--      fine    "Fine-grained" type (default: true).
-- @returns typename [, category [, subtype]]
--
-- This function returns the standard return values of Lua's ''type'', but additionally
-- the strings
--
--      "null"      if ''x'' is a NULL,
--      "integer"   if ''x'' is an integral number.
--
-- If ''fine'' is ''true'', the returned ''subtype'' is
--
--      "null"      if empty,
--      "array"     for arrays containing only tables (then, the ''subtype'' is identified),
--      "map"       otherwise.
--
-- Note, that tables containing array or sequence elements with additional map entries
-- (as available in Lua) are not identified.
--
local function typeof(x, fine)
    fine = (fine == nil) and true or fine

    local itsa = type(x)
    if itsa == "table" then
        if x == NULL then
            return "null"
        elseif fine then
            if #x > 0 then
                local t = type(x[1])

                -- check if all same
                local same = true
                for _, v in ipairs(x) do
                    if type(v) ~= t then -- using "type" here, as we need not to differentiate between "integer" and "number"
                        same = false
                        break
                    end
                end

                if not same then
                    return itsa
                end

                return itsa, "array", t
            else
                local k, _ = next(x)
                if k == nil then
                    return "null"
                else
                    return itsa, "map"
                end
            end
        end
    elseif itsa == "number" then
        return mtype(x)
    end

    return itsa
end
M.typeof = typeof

--- `escape()`
--
-- Escape a string.
--
local escape_table = {
    [0] = "\\x00",
    "\\x01",
    "\\x02",
    "\\x03",
    "\\x04",
    "\\x05",
    "\\x06",
    "\\a",
    "\\b",
    "\\t",
    "\\n",
    "\\v",
    "\\f",
    "\\r",
    "\\x0E",
    "\\x0F",
    [34] = '\\"',
    [127] = "\\x7F"
}

local function escape(s)
    local res = {}
    -- FIXME table.setn(res, s:len())
    for _, c in utf8codes(s) do
        if c < 32 or c == 127 then
            tinsert(res, escape_table[c])
        else
            tinsert(res, utf8char(c))
        end
    end
    return tconcat(res)
end
M.escape = escape

--- `unescape`
--
-- Unescape a string.
--
local unescape_table = {
    ["\\a"] = 0x07,
    ["\\b"] = 0x08,
    ["\\t"] = 0x09,
    ["\\n"] = 0x0A,
    ["\\v"] = 0x0B,
    ["\\f"] = 0x0C,
    ["\\r"] = 0x0D,
    ["\\\\"] = 0x5C
}

local function unescape(s)
    local res = {}
    -- FIXME table.setn(res, s:len())

    local esc
    local nesc = 0

    for _, c in utf8codes(s) do
        if nesc > 0 then
            esc = esc .. utf8char(c)
            nesc = nesc + 1

            if nesc == 2 then
                local c = unescape_table[esc]
                if c then
                    tinsert(res, utf8char(c))
                    nesc = 0
                end
            end

            if nesc > 0 then
                local ch = esc:sub(2, 2)
                if ch == "x" then
                    error("FIXME")
                elseif ch == "u" then
                    error("FIXME")
                end
            end
        else
            if c == 0x5C then
                esc = "\\"
                nesc = 1
            else
                tinsert(res, utf8char(c))
            end
        end
    end

    assert(nesc == 0, "invalid escape sequence")

    return tconcat(res)
end
M.unescape = unescape

--- `getkeys()`
--
-- Get sorted list of keys.
--
-- @param
--      t           The table.
-- @returns
--      Array of keys in `t`.
--
local precedence = {
    integer = 0,
    float = 1,
    string = 2,
    any = 99
}
local function getkeys(t)
    local keys = {}
    for k, _ in pairs(t) do
        tinsert(keys, k)
    end

    tsort(
        keys,
        function(a, b)
            local ta, tb = mtype(a) or type(a), mtype(b) or type(b)
            if ta == tb then
                return a < b
            else
                ta = precedence[ta] or precedence.any
                tb = precedence[tb] or precedence.any

                return ta < tb
            end
        end
    )

    return keys
end
M.getkeys = getkeys

--- `tovalue()`
--
-- Convert literal to a value.
--
-- @param
--      s       Character string.
--      [fn]    User-supplied conversion function (optional).
local function tovalue(s, fn)
    opts = opts or {}

    -- check user-supplied converter
    if fn then
        local res, isstr = fn(s)
        if res ~= nil then
            return res, isstr
        end
    end

    -- arrays
    local ch1 = s:sub(1, 1)
    if s == "{}" then
        return NULL
    elseif ch1 == "{" or ch1 == "[" then
        local rev = {["{"] = "}", ["["] = "]"}
        assert(s:sub(-1, -1) == rev[ch1], "array not closed")

        s = s:sub(2, -2)

        local res = {}
        local q = 0
        local val = ""
        for p, c in utf8.codes(s) do
            local ch = utf8char(c)
            if q == 0 then
                if ch == "," then
                    val = val:trim()
                    val = tovalue(val)
                    tinsert(res, val)
                    val = ""
                else
                    val = val .. ch
                    if ch == '"' then
                        q = 1
                    end
                end
            else
                val = val .. ch
                if ch == '"' then
                    q = 0
                end
            end
        end
        if val:len() > 0 then
            val = val:trim()
            val = tovalue(val)
            tinsert(res, val)
        end

        return res
    end

    -- check numbers and related
    if s == "-∞" or s == "-inf" then
        return -1 / 0
    elseif s == "∞" or s == "+∞" or s == "inf" or s == "+inf" then
        return 1 / 0
    elseif s:lower() == "nan" then
        return 0 / 0
    end

    if s:match("^0b") then
        error("FIXME binary")
    elseif s:match("^0[0-9]*") then
        error("FIXME octal")
    else
        -- FIXME 1.0×10¯³ ???
        local num = tonumber(s)
        if num then
            return num
        end
    end

    -- check strings (possibly "unquote" them)
    local ch = s:sub(1, 1)
    if ch == '"' or ch == "'" then
        assert(s:sub(-1, -1) == ch, "invalidly quoted string")
        s = unescape(s:sub(2, -2))
    end

    return s:trim(), true
end
M.tovalue = tovalue

--- `toliteral()`
--
-- Convert value to a literal.
--
-- @param
--      x       Lua value.
--      [fn]    User-supplied conversion function (optional).
local function toliteral(x, fn)
    if fn then
        local res = fn(x)
        if res then
            return res
        end
    end

    local tn, cat, subt = typeof(x)

    if tn == "table" then
        if cat == "array" then
            if subt == "number" then
                local t = {}
                for _, v in ipairs(x) do
                    tinsert(t, toliteral(v, fn))
                end
                return "{ " .. tconcat(t, ", ") .. " }"
            elseif subt == "string" then
                local t = {}
                for _, v in ipairs(x) do
                    tinsert(t, '"' .. escape(v) .. '"')
                end
                return "{ " .. tconcat(t, ", ") .. " }"
            elseif fn then
                local t = {}
                for _, v in ipairs(x) do
                    local altv = fn(v)
                    if altv == "nil" then
                        return
                    end
                end
                return "{ " .. tconcat(t, ", ") .. " }"
            end
        end
    else
        if tn == "string" then
            if x:find("\n") then
                local res = x:split("\n")
                if res[#res]:len() == 0 then
                    tremove(res)
                end
                return res
            else
                x = x:trim()
                local alt = escape(x)
                if x ~= alt then
                    return '"' .. alt .. '"'
                else
                    return x
                end
            end
        elseif tn == "integer" then
            return tostring(x)
        elseif tn == "float" then
            if x ~= x then
                return "NaN"
            elseif x == minf then
                return "∞"
            elseif x == -minf then
                return "-∞"
            else
                return tostring(x)
            end
        elseif tn == "null" then
            return "{}"
        end
    end

    return nil -- invalid
end
M.toliteral = toliteral

--- `tokey()`
--
-- Transform into a key.
--
-- @param
--      x           The value to convert.
-- @returns
--      FIXME
--
local function tokey(x)
    local itsa = type(x)

    if itsa == "string" then
        if x:sub(1, 1) == '"' then
            return x:sub(2, -2)
        else
            return x
        end
    elseif itsa == "number" then
        return tostring(x)
    else
        error("invalid table key type: " .. itsa)
    end
end
M.tokey = tokey

-- Start of document.
if M.YAML_COMPAT then
    M._DOCUMENT = "---"
else
    M._DOCUMENT = "🗎"
end

-- [[ MODULE ]]
return M
