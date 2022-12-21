--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] local M = require 'amend.docs.lua.__module'

local md = require "amend.docs.markdown"

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

    if mtype == 'integer' then
        level = fmt
        fmt = args[1]
        tremove(args, 1)
    end

    local msg = strformat(fmt, tunpack(args))
    error(msg, level + 1)
end

--- `document`
-- 
-- FIXME
--
-- {
local document = class(M) "document" {
    __inherit = {md.document},
    __public = {
    }
}

function document:__init(options)
    md.document.__init(self, options)
end

function document:parse(stream)   
end
-- } 

-- [[ MODULE ]]
return M
