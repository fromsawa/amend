--[[
    Copyright (C) 2022-2024 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --
--[[>>[amend.api.lua.class] Classes.

Here we provide a simple class implementation supporting inheritance.

]] --
class = {}

require "amend.lua.string"
require "amend.lua.table"

local strsplit = string.split
local strformat = string.format
local tinsert = table.insert
local tremove = table.remove
local tconcat = table.concat
local tmake = table.make
local mtype = math.type

-- Simple deep table copy.
local function tcopy(t)
    local res = {}

    for k, v in pairs(t) do
        if type(v) == "table" then
            res[k] = tcopy(v)
        else
            res[k] = v
        end
    end

    setmetatable(res, getmetatable(t))
    return res
end

-- Internal marker denoting an "implemented" class.
--
-- This marker (see class.tag) allows out-of-order method declarations 
-- for inheritance.
local implemented = {}

--- `class.tag`
--
-- This class tag serves two purposes, first to mark a table as 'class'
-- and second, provides the meta-method `__call` for class instatiation.
--
local tag = {
    __call = function(decl, ...)
        -- inherit methods (first time only)
        if not decl[implemented] then
            -- inherit
            local excluded = {
                __public = true,
                __inherit = true,
                __init = true
            }

            local methods = {}
            for _, parent in ipairs(decl.__inherit) do
                for k, v in pairs(parent) do
                    if not excluded[k] and type(v) == "function" then
                        methods[k] = methods[k] or v
                    end
                end
            end

            for k, v in pairs(methods) do
                decl[k] = decl[k] or v
            end

            -- constructor
            decl.__init = decl.__init or function(self, ...)
            end

            -- member access
            decl.__index = decl.__index or decl
            decl.__newindex = decl.__newindex or newindex

            -- __dump
            local function dumper(self, options)
                io.dump(self, tmake(options, {
                    prefix = self.__name .. ":table"
                }))
            end
            decl.__dump = decl.__dump or dumper

            -- :table
            local function table(self, v)
                setmetatable(v, self)
                return v
            end
            decl.table = decl.table or table

            decl[implemented] = true
        end

        -- instantiate
        local obj = {}
        setmetatable(obj, decl)

        -- initialize member variables
        for k, v in pairs(decl.__public) do
            if type(v) == "table" then
                if v == void then
                    obj[k] = nil
                else
                    obj[k] = tcopy(v)
                end
            else
                obj[k] = v
            end
        end

        -- construct and return object
        -- (note: this allows singletons!)
        return decl.__init(obj, ...) or obj
    end
}

--- `void`
--
-- A place-holder (for `__public` fields).
--
void = {}
setmetatable(void, {
    __name = "void",
    __dump = function(self, options)
        options.stream:write("void")
    end
})

--- `isvoid(t)`
--
-- Check if `t` is `void`.
--
function isvoid(t)
    return t == void
end

--- `isclass(t)`
--
-- Check if `t` is a `class`.
--
function isclass(t)
    return getmetatable(t) == tag
end

---[isobject] `isobject(t)`
--
-- Check if `t` is an object.
--
function isobject(t)
    return isclass(getmetatable(t))
end

-- `resolve(...)`
--
-- Find a class by name.
--
-- @call
--      `resolve(name)`
--      `resolve(name, root)`
--
-- @param
--      name            The class name.
--      root            The root namespace (default: _G)
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

--- `isa(obj, ...)`
-- @call
--      `isa(obj, T)`
--
-- Check if `obj` is of type `T`. Here, `T` may also be
-- a string as it would be returned by `type()` or `math.type()`.
--
-- @call
--      `isa(obj, {T})`
--
-- Check if `obj` is or is derived from type `T`. This requires
-- `obj` to be an object (see [isobject](#isobject)).
--
function isa(obj, T)
    local mtype = math.type

    if isobject(obj) then
        if isclass(T) then
            return getmetatable(obj) == T
        elseif type(T) == "string" then
            if (mtype(obj) or type(obj)) == T then
                return true
            end

            local R = resolve(T)
            if not R then
                error(strformat("unknown class or type %q", T), 2)
            end

            return isa(obj, R)
        else
            if (type(T) ~= "table") or (#T ~= 1) then
                error("expected a table with a single element", 2)
            end
            T = T[1]
            if type(T) == "string" then
                T = resolve(T)
            end

            local mt = getmetatable(obj)
            if mt == T then
                return true
            end

            local __inherit = mt.__inherit
            for i = #__inherit, 1, -1 do
                if T == __inherit[i] then
                    return true
                end
            end

            return false
        end
    else
        if type(T) == "string" then
            return (mtype(obj) or type(obj)) == T
        end
    end
end

--- `class.index(t,k)`
--
-- Retrieve index `k` from table `t` in the same way, standard `__index` does it,
-- however, using 'rawget' internally.
--
local function index(t, k)
    return rawget(t, k) or rawget(getmetatable(t), k)
end

--- `class.newindex`
--
-- Standard `__newindex` meta-method for classes.
--
-- This disallows unknown dictionary keys while integer keys (ie. array keys)
-- are allowed.
--
local function newindex(self, k, v)
    if mtype(k) ~= 'integer' then
        if not getmetatable(self).__public[k] then
            error(strformat("variable %q is not a public member variable", tostring(k)), 2)
        end
    end

    rawset(self, k, v)
end

--- `class "name" { <declaration> }`
-- 
-- Declare a class.
--
-- @call
--      `class "name" { <declaration> }`
--      `class(t) "name" { <declaration> }`
-- 
-- @param
--      t               Destination table (default: `_G`).
--      name            Class name (dot-separated identifiers).
-- 
-- *Declaration*\
-- 
--      {
--          __inherit = { <inheritance-list> },
--          __public = {
--              <variables>
--          },
--          <methods>
--      }
-- 
-- 
local function declare_class(t, name, decl, _level)
    local root = t

    -- create or lookup and check namespace
    local namespace = strsplit(name, ".")
    local depth = #namespace

    local function check_namespace(tbl, idx)
        if (type(tbl) ~= "table") or (getmetatable(tbl) ~= nil) then
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
            if type(k) == "string" then
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

    local __public = {}
    for _, parent in ipairs(__inherit) do
        for k, v in pairs(parent.__public) do
            __public[k] = v
        end
    end
    for k, v in pairs(decl.__public or {}) do
        __public[k] = v
    end
    decl.__public = __public

    -- return class
    t[clsname] = decl

    decl.__name = name
    setmetatable(decl, tag)

    return decl
end

local function declare(arg)
    local targ = type(arg)

    if targ == "table" then
        local t = arg
        return function(arg)
            if type(arg) ~= "string" then
                error("expected a class name (second argument)", 2)
            end

            local name = arg
            return function(decl)
                if type(decl) ~= "table" then
                    error("expected a class declaration (table, third argument)", 2)
                end
                return declare_class(t, name, decl, 2)
            end
        end
    elseif targ == "string" then
        local name = arg
        return function(decl)
            if type(decl) ~= "table" then
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
class.isa = isa
class.void = void
class.isvoid = isvoid
class.index = index
class.newindex = newindex
return class
