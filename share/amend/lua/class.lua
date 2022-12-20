--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --
-- >>[amend.api.lua.class] Classes
--[[
    
FIXME

]] --
class = {}

require "amend.lua.string"
require "amend.lua.table"

local strsplit = string.split
local strformat = string.format
local tinsert = table.insert
local tremove = table.remove
local tconcat = table.concat

--- `class.tag`
local tag = {
    __call = function(self, ...)
        local obj = {}
        setmetatable(obj, self)

        return self.__init(obj, ...) or obj
    end
}

--- `isclass`
function isclass(t)
    return getmetatable(t) == tag
end

--- `isobject`
function isobject(t)
    return isclass(getmetatable(t))
end

--- `resolve(name)`
--
-- Find a class by name.
--
local function resolve(name, root)
    local cls = root or _G

    local namespace = strsplit(name, ".")
    for i, ns in ipairs(namespace) do
        cls = cls[ns]

        if not cls then
            return cls
        end
    end

    return cls
end

--- `class "name" { <declaration> }`
-- 
-- FIXME
--
local function declare_class(t, name, decl, _level)
    local root = t

    -- create or lookup and check namespace
    local namespace = strsplit(name, ".")
    local depth = #namespace

    local function check_namespace(tbl, idx)
        if (type(tbl) ~= 'table') or (getmetatable(tbl) ~= nil) then
            local where = {}
            for j = 1, idx do
                tinsert(where, namespace[j])
            end

            error(strformat("%q is not a namespace (ie. a normal table)", tconcat(where, ".")), _level + 1)
        end
    end

    for i, ns in ipairs(namespace) do
        if not ns:match("^[_%a][_%w]*$") then
            error("class name is not composed of identifiers", _level)
        end
        if i == depth then
            break
        end

        check_namespace(t, i - 1)
        t[ns] = t[ns] or {}
        t = t[ns]
    end
    check_namespace(t, depth - 1)

    -- build class
    local clsname = namespace[depth]

    if t[clsname] then
        error(strformat("%q exists", name), _level)
    end

    -- inheritance
    local __inherit = {}
    local function build_inherit(tree)
        for _, k in ipairs(tree) do
            if type(k) == 'string' then
                k = resolve(k, root) or resolve(k, _G)
            end

            if not isclass(k) then
                error("invalid entry in inheritance list", 3)
            end

            -- recurse first
            build_inherit(k.__inherit)

            -- add element
            tinsert(__inherit, k)
        end
    end
    build_inherit(decl.__inherit or {})
    decl.__inherit = __inherit

    -- constructor
    decl.__init = decl.__init or function(self, ...)
    end

    -- return class
    t[clsname] = decl

    decl.__name = name
    setmetatable(decl, tag)

    return decl
end

local function declare(arg)
    local targ = type(arg)

    if targ == 'table' then
        local t = arg
        return function(arg)
            if type(arg) ~= 'string' then
                error("expected a class name (second argument)", 2)
            end

            local name = arg
            return function(decl)
                if type(decl) ~= 'table' then
                    error("expected a class declaration (table, third argument)", 2)
                end
                return declare_class(t, name, decl, 2)
            end
        end
    elseif targ == 'string' then
        local name = arg
        return function(decl)
            if type(decl) ~= 'table' then
                error("expected a class declaration (table, second argument)", 2)
            end
            return declare_class(_G, name, decl, 2)
        end
    else
        error("invalid first argument passed to 'class' (expected namespace or class name)", 2)
    end
end

setmetatable(class, {
    __call = function(self, arg)
        return declare(arg)
    end
})

--[[ MODULE ]]
class.tag = tag
class.isclass = isclass
class.isobject = isobject
return class
