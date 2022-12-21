--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] local M = require 'amend.docs.__module'

local mtype = math.type
local cnewindex = class.newindex

--- `node`
--
-- FIXME
--
-- {
local node = class(M) "node" {
    __public = {
        tag = void,
        parent = void,
        context = void
    }
}

function node:__init(tag, parent)
    self.tag = tag or "root"
    self.parent = parent
end

function node:__newindex(k, v)
    if mtype(k) == 'integer' then
        rawset(self, k, v)

        if isa(v, {node}) then
            v.parent = self
        end
    else
        cnewindex(self, k, v)
    end
end

function node:clear()
    while #self > 0 do
        rawset(self, #self, nil)
    end
end

function node:remove(k)
    if k then
        assert(mtype(k) == 'integer')
        for i = k,#self-1 do
            rawset(self, i, rawget(self, i+1))
        end
        rawset(self, #self, nil)
    else
        local parent = self.parent
        if parent then
            for i, t in ipairs(parent) do
                if self == t then
                    parent:remove(i)
                    break
                end
            end 
        end
    end
end

function node:add(v)
    if not isa(v, {node}) then
        io.dump(v)
    end
    assert(isa(v, {node}))
    rawset(self, #self+1, v)
    v.parent = self
end
-- }

--- `substitution`
--
-- FIXME
--
local substitution = class(M) "substitution" {
    __public = {
        tag = void,
        content = void,
        context = void
    }
}

function substitution:__init(tag, content, context)
    self.tag = tag
    self.content = content
    self.context = context
end

-- [[ MODULE ]]
return M
