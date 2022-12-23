--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --
local M = require "amend.docs.__module"

local mtype = math.type
local tinsert = table.insert
local cnewindex = class.newindex

--- `node`
--
-- FIXME
--
--{
local node =
    class(M) "node" {
    __public = {
        tag = void,
        parent = void,
        context = void,
        annotation = void
    }
}

function node:__init(tag, parent)
    self.tag = tag or "root"
    self.parent = parent
end

function node:__newindex(k, v)
    if mtype(k) == "integer" then
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
        assert(mtype(k) == "integer")
        for i = k, #self - 1 do
            rawset(self, i, rawget(self, i + 1))
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
    if isa(v, M.annotation) then
        self.annotation =
            self.annotation or
            {
                offset = 0
            }
        tinsert(self.annotation, v)
    elseif isa(v, {node}) then
        rawset(self, #self + 1, v)
        v.parent = self
    else
        print("FIXME node:add")
        io.dump(v)
        os.exit(1)
    end
end

function node:__dump(options)
    options.visited = options.visited or {}
    options.visited[self.parent] = true
    io.dump(self, options)
end
--}

--- `annotation`
--
-- FIXME
--
-- @see [amend.api.docs.syntax.annotation]
--{
local annotation =
    class(M) "annotation" {
    __public = {
        tag = void,
        content = void,
        context = void
    }
}

function annotation:__init(tag, content, context)
    self.tag = tag
    self.content = content
    self.context = context
end

function annotation:__dump(options)
    options.visited = options.visited or {}
    options.visited[self.context] = true
    io.dump(self, options)
end
--}

-- [[ MODULE ]]
return M
