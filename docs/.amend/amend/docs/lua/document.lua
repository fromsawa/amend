--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] local M = require 'amend.docs.lua.__module'

local md = require "amend.docs.markdown"
local docs = require 'amend.docs.__module'

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
    __public = {}
}

function document:__init(options)
    md.document.__init(self, options)
end

function document:parse(stream)
    local stack = self.stack
    local top = stack[#stack]
    local state, pattern
    local fragment

    local function addcomment(txt)
        local ref,text = txt:match("^>>[[]([^]]*)[]][%s]*(.*)")
        if ref then
            self:addheading(1, {
                text = text,
                attributes = nil,
                reference = ref
            })
            fragment = docs.stream()
            top = stack[#stack]
        end
    end

    for line, ctxt in stream:lines() do
        ::again::
        top = stack[#stack]

        if state == 'longcomment' then
            local comment, rest = line:match(pattern)
            if comment then
                state = nil
                if fragment then
                    io.dump(fragment)
                    os.exit()
                end
            else
                comment = line
            end

            addcomment(comment)

            if rest then
                line = rest
                goto again
            end
        else
            local comment = line:match("[%s]*%-%-(.*)")
            if comment then
                local sample, rest = comment:match("^[[]([^[]*)[[][%s]*(.*)")
                if sample then
                    state = 'longcomment'
                    pattern = "(.*)[]]" .. sample .. "[]](.*)"
                else
                    rest = comment:match("[%s]*(.*)")
                end

                addcomment(rest)
            else
                state = nil
                -- FIXME
            end
        end
    end
end
-- } 

-- [[ MODULE ]]
return M
