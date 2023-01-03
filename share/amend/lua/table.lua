--[[
    Copyright (C) 2022-2023 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]

--[[>>[amend.api.lua.table] Table library extensions.
]]

local mtointeger = math.tointeger
local tinsert = table.insert
local tremove = table.remove

--- `table.has(tbl, item)`
-- Check if array-part of a table has an element.
-- @param
--      tbl         The table to check.
--      item        The item.
--
function table.has(tbl, item)
    for i, v in ipairs(tbl) do
        if item == v then
            return i
        end
    end

    return nil
end
local thas = table.has

--- `table.kpairs(tbl)`
-- Key-only table iterator.
-- This function ignores integer-valued keys.
function table.kpairs(tbl)
    local function iter(t, k)
        local v
        while true do
            k, v = next(t, k)
            if not mtointeger(k) then
                return k, v
            end
            if k == nil then
                return
            end
        end
    end

    return iter, tbl, nil
end

--- `table.count(tbl)`
-- Count all keys in a table.
function table.count(tbl)
    local n = 0
    for _, _ in pairs(tbl) do
        n = n + 1
    end
    return n
end

local hint_tag = {}

--- `table.hint(tbl)`
-- Get/set "hint" table.
-- FIXME
function table.hint(tbl)
    local mt = getmetatable(tbl)

    if mt then
        if getmetatable(mt) ~= hint_tag then
            return nil
        end
    else
        mt = {}
        setmetatable(mt, hint_tag)
        setmetatable(tbl, mt)
    end

    return mt
end

--- `table.top(tbl, idx)`
-- Get array items from top
function table.top(tbl, idx)
    idx = idx or 0
    return tbl[#tbl - idx]
end

--- `table.copy(tbl)`
-- Create a table copy.
local function tcopy(t)
    if type(t) ~= "table" then
        return t
    else
        local res = {}

        for k, v in pairs(t) do
            res[k] = tcopy(v)
        end

        return res
    end
end
table.copy = tcopy

--- `table.merge(t, other)`
-- Merge another table into ''t''
local function tmerge(t, other)
    assert(type(t) == "table")
    assert(type(other) == "table")

    for k, v in pairs(other) do
        if type(t[k]) == "table" then
            tmerge(t[k], v)
        else
            t[k] = v
        end
    end

    return t
end
table.merge = tmerge

--- `table.make(...)`
-- Create a new table from many.
--
local function tmake(...)
    local res = {}
    for _, t in ipairs({...}) do
        tmerge(res, t)
    end
    return res
end
table.make = tmake

--- `table.unique(t)`
-- Make array elements unique.
function table.unique(t)
    local seen = {}

    local i = 1
    while i <= #t do
        local v = t[i]
        if seen[v] then
            tremove(t, i)
        else
            seen[v] = true
            i = i + 1
        end
    end

    return t
end

--- `table.insert_unique(t, v)`
-- Add a unique value.
function table.insert_unique(t, v)
    if not thas(t, v) then
        tinsert(t, v)
    end

    return t
end

-- [[ MODULE ]]
message(TRACE[10], "extended table library")
return table
