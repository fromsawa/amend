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
    local parent = docs.markdown.document

    local stack = self.stack
    local top = stack[#stack]

    local level = 0
    local fragment

    local function handle_fragment()
        if not self.id then
            docs.notice(ERROR, fragment[1].origin, "comment is not associated with a document")
        end

        -- level up/down
        local levelup = fragment[#fragment]:re("^%s-{%s*$")
        if levelup then
            if level == 0 then
                docs.notice(ERROR, levelup.origin, "cannot open a section here")
            end

            level = level + 1
            tremove(fragment, #fragment)
        end

        -- parse the fragment
        parent.parse(self, fragment)
        fragment = nil

        -- set level after introduction
        if level == 0 then
            for _, s in ipairs(stack) do
                if s.tag == 'section' then
                    level = level + 1
                end
            end

            if level > 0 then
                level = level + 1
            end
        end
    end

    local state, pattern
    for aline in stream:lines() do
        ::again::
        top = stack[#stack]

        if state == 'longcomment' then
            -- check for closing pattern
            local comment = aline:re(pattern)
            if comment then
                -- reset state
                state = nil
            else
                comment = {aline}
            end

            -- handle comment
            if fragment then
                fragment:insert(comment[1])
            end

            -- handle fragment
            if fragment and (state == nil) then
                handle_fragment()
            end

            -- parse rest of line after long-comment closing pattern
            if #comment == 2 then
                aline = comment[2]
                goto again
            end
        else
            -- check for long comments
            local comment = aline:re("^[%s]*%-%-[[]([^[]*)[[](.*)")
            if not comment then
                -- check for line comments
                comment = aline:re("^[%s]*%-%-(.*)")
            end

            if comment then
                if #comment == 2 then
                    -- start of long comment
                    state = 'longcomment'
                    pattern = "(.*)[]]" .. tostring(comment[1]) .. "[]](.*)"
                    comment = comment[2]
                else
                    -- normal comment
                    comment = comment[1]
                end

                if not fragment then
                    -- document start
                    local document = comment:re("%s*>>[[]([^]]+)[]]%s*(.*)")
                    if document then
                        local reference, title = tunpack(document)

                        if self.id then
                            docs.notice(ERROR, comment.origin, "document is alread associated")
                        end

                        self.id = tostring(reference)

                        title:trim()
                        if #title > 0 then
                            self:addheading(1, {
                                text = title,
                                reference = reference
                            }, title.origin)
                        end

                        fragment = docs.stream.file()
                        goto continue
                    end

                    -- fragment
                    local begin = comment:re("^([^%s])")
                    if begin then
                        begin = begin[1]
                        if begin[1] == '-' then
                            -- function/class description
                            local desc = comment:re("-%s+[[]([^]]+)[]]%s+(.*)")
                            if not desc then
                                desc = comment:re("-%s+(.*)")
                            end

                            local reference, title
                            if #desc == 2 then
                                reference, title = desc[1], desc[2]
                            else
                                title = desc[1]
                            end

                            if #title == 0 then
                                docs.notice(ERROR, desc.origin, "missing title")
                            end

                            self:addheading(level, {
                                text = title,
                                reference = reference
                            }, title.origin)
                        end
                    end

                    -- level up/down
                    if self.id then
                        local levelup = comment:re("^%s-{%s*$")
                        if levelup then
                            level = level + 1
                        end

                        local leveldown = comment:re("^%s-}%s*$")
                        if leveldown and (level > 0) then
                            level = level - 1

                            if level == 0 then
                                docs.notice(ERROR, leveldown.origin, "stray closing brace")
                            end
                        end
                    end
                else
                    comment = comment:re("%s*(.*)")[1]
                    fragment:insert(comment)
                end
            else
                -- parse fragement (if applicable)
                if fragment then
                    handle_fragment()
                end

                -- reset state
                state = nil
            end
        end
        ::continue::
    end
end
-- } 

-- [[ MODULE ]]
return M
