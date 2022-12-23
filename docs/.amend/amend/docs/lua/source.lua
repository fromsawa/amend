--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --

local M = require "amend.docs.lua.__module"

local md = require "amend.docs.markdown"
local docs = require "amend.docs.__module"

local mtype = math.type
local tinsert = table.insert
local tremove = table.remove
local tunpack = table.unpack
local tmake = table.make
local strlen = string.len
local strformat = string.format
local strtrim = string.trim
local strrep = string.rep

local fmterror = function(fmt, ...)
    local args = {...}
    local level = 0

    if mtype == "integer" then
        level = fmt
        fmt = args[1]
        tremove(args, 1)
    end

    local msg = strformat(fmt, tunpack(args))
    error(msg, level + 1)
end

--- `source`
--
-- Source file representation (yields multiple markdown documents).
--
--{
local source =
    class(M) "source" {
    __inherit = {},
    __public = {
        options = {},
        documents = {}
    }
}

function source:__init(options)
    -- md.source.__init(self, options)
    for k, v in pairs(options or {}) do
        self.options[k] = v
    end
end

function source:parse(stream)
end

-- function source:__dump(options)
--     options.visited = options.visited or {}
--     options.visited[self.stack] = true
--     io.dump(self, options)
-- end

--}

-- [[ MODULE ]]
return M
