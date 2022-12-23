--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --

local M = require "amend.docs.lua.__module"

--[[>>[amend.api.docs.api.lua.source] Lua source.
]] --

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
    local thedoc

    local level = 0
    local fragment  -- a markdown fragment
    local function handle_fragment()
        if not thedoc then
            docs.notice(ERROR, fragment[1].origin, "comment is not associated with a document")
        end

        -- parse the fragment
        thedoc:parse(fragment)

        -- set level after introduction
        if level == 0 then
            for _, s in ipairs(thedoc.stack) do
                if s.tag == "section" then
                    level = level + 1
                end
            end

            if level > 0 then
                level = level + 1
            end
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

        -- clear fragment
        fragment = nil
    end

    -- loop over the lines
    local state, pattern
    for aline in stream:lines() do
        ::again::
        if state == "longcomment" then
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
                    state = "longcomment"
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

                        thedoc = md.document()
                        thedoc.id = tostring(reference)

                        level = 0
                        tinsert(self.documents, thedoc)

                        title:trim()
                        if #title > 0 then
                            thedoc:addheading(
                                1,
                                {
                                    text = title,
                                    reference = reference
                                },
                                title.origin
                            )
                        end

                        fragment = docs.stream.file()
                        goto continue
                    end

                    -- fragment
                    local begin = comment:re("^([^%s])")
                    if begin then
                        begin = begin[1]
                        if begin[1] == "-" then
                            -- function/class description
                            local desc = comment:re("-%s*[[]([^]]+)[]]%s+(.*)")
                            if not desc then
                                desc = comment:re("-%s+(.*)")
                            end

                            if not desc then
                                docs.notice(ERROR, comment.origin, "invalid fragment")
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

                            if not thedoc then
                                docs.notice(ERROR, desc.origin, "no document declared")
                            end

                            thedoc:addheading(
                                level,
                                {
                                    text = title,
                                    reference = reference
                                },
                                title.origin
                            )
                        end
                    end

                    -- level up/down
                    if thedoc and thedoc.id then
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

-- function source:__dump(options)
--     options.visited = options.visited or {}
--     options.visited[self.stack] = true
--     io.dump(self, options)
-- end

--}

-- [[ MODULE ]]
return M
