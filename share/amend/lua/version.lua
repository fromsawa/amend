--[[
    Copyright (C) 2024 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[[>>[amend.api.lua.version] Version number library
]]

require "amend.lua.class"
require "amend.lua.string"

local majormul = 1000;
local minormul = 10000;

--- `version`
--
-- A broken down version number which consist of a major, minor and a patch version. 
--
class 'version' {
    __public = {
        major = 0,
        minor = 0,
        patch = 0
    }
}

--- `version(t)`
--
-- @param 
--      t       Version definition (table of numbers or string).
--
-- A version number is expected to be sequence of three numbers, the
-- major, minor and patch version. Additional version specifications
-- may be provided but are ignored.
--
-- In string notation, the version is 
--
--      "<major>[.<minor>[.<patch>[<punctuation><rest>]]]"
-- 
-- where '[]' denotes optional parts.
-- 
function version:__init(t)
    if type(t) == 'string' then
        local v = t:split('.')
        self.major = tonumber(v[1]) 
        self.minor = tonumber(v[2]) 
        self.patch = tonumber(v[3]) 
    elseif isa(t, 'version') then
        self.major = t.major        
        self.minor = t.minor        
        self.patch = t.patch        
    elseif type(t) == 'table' then
        self.major = t[1]
        self.minor = t[2]
        self.patch = t[3]
    else
        error('Invalid argument passed to version().')
    end

    assert(type(self.major) == 'number', 'Expected the major version part to be a number.')
    assert(type(self.minor) == 'number', 'Expected the minor version part to be a number.')
    assert(type(self.patch) == 'number', 'Expected the patch version part to be a number.')

    assert(self.minor < majormul, "Minor number exceeds the expected range (<1000).")
    assert(self.patch < minormul, "Patch number exceeds the expected range (<10000).")
end

--- `version:tostring()`
--
-- Convert version to a string.
--
function version:tostring() 
    return string.format("%d.%d.%d", self.major, self.minor, self.patch)
end

--- `version:value()`
--
-- Calculate a comparable number.
--
function version:value()
    return ((self.major * majormul) + self.minor) * minormul + self.patch
end

function version:__eq(other)
    return self:value() == version(other):value()
end

function version:__lt(other)
    return self:value() < version(other):value()
end

function version:__le(other)
    return self:value() <= version(other):value()
end

