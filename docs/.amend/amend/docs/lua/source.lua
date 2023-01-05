--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --

local M = require "amend.docs.lua.__module" --

--[[>>[amend.api.docs.api.lua.source] Lua source.
]] local md = require "amend.docs.markdown"
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
        core = void,
        documents = {}
    }
}

function source:__init(core)
    self.core = core
end

function source:parse(stream)
    local thedoc, level

    local function parse_comment(block)
        ::retry::
        if not block[0] then
            return
        end

        -- remove leading/trailing empty lines
        while (#block > 0) and block[1]:re("^%s*$") do
            tremove(block, 1)
        end
        while (#block > 0) and block[#block]:re("^%s*$") do
            tremove(block, #block)
        end

        -- check for "group start"
        local openbrace
        if #block > 0 then
            local brace = block[#block]:re("^{(.*)")
            if brace and brace[1]:re("^%s*$") then
                openbrace = {[0] = block[#block]}
                tremove(block, #block)
            end
        end

        -- expand/process macros
        docs.expand(block)

        -- parse
        local first = block[0]

        -- DOCUMENT
        local document = first:re("%s*>>[[]([^]]+)[]]%s*(.*)")
        if document then
            local reference, title = tunpack(document)

            thedoc = md.document(self.core)
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
        end

        -- sanity check (document required)
        if not thedoc then
            docs.notice(ERROR, first.origin, "comment is not associated with a document")
        end

        -- PARAGRAPH
        local paragraph = first:re("^%-(.*)")
        if paragraph then
            local line = paragraph[1]
            if not line:re("^%s*$") then
                local reference, title

                local tmp = line:re("^[[]([^]]+)[]]%s*(.*)")
                if tmp then
                    reference, title = tunpack(tmp)
                else
                    title = line:trim()
                end

                thedoc:addheading(
                    level + 1,
                    {
                        text = title,
                        reference = reference
                    },
                    title.origin
                )
            end
        end

        -- LEVEL UP/DOWN
        if first:re("^{") then
            if level == 0 then
                docs.notice(ERROR, first.origin, "cannot open a section here")
            end

            level = level + 1
            return
        elseif first:re("^}") then
            level = level - 1
            if level == 0 then
                docs.notice(ERROR, first.origin, "stray closing brace")
            end
            return
        end

        -- parse the fragment
        local fragment = docs.stream.file()
        for _, line in ipairs(block) do
            fragment:insert(line)
        end
        thedoc:parse(fragment)

        -- set level after introduction
        if level == 0 then
            for _, s in ipairs(thedoc.stack) do
                if s.tag == "section" then
                    level = level + 1
                end
            end
        end

        -- handle hanging "--{"
        if openbrace then
            block = openbrace
            goto retry
        end
    end

    -- loop over the lines
    local state, pattern
    local block
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

            if block then
                -- add lines
                if state or (#comment[1] > 0) then
                    tinsert(block, comment[1])
                end

                -- parse comment block
                if state == nil then
                    parse_comment(block)
                    block = nil
                end
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
                -- check for single-line comments
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

                    -- strip (single) space after "--"
                    if block then
                        comment = comment:re("%s?(.*)")[1] or comment
                    end
                end

                -- make a block (if applicable)
                if not block then
                    local text = tostring(comment)

                    if text:match("^%-") then
                    elseif text:match("^>>") then
                    elseif text:match("^[{}]") then
                    else
                        goto continue
                    end

                    block = {
                        [0] = comment
                    }
                else
                    tinsert(block, comment)
                end
            else
                -- parse comment block (if applicable)
                if block then
                    parse_comment(block)
                    block = nil
                end

                -- reset state
                state = nil
            end
        end
        ::continue::
    end

    if block then
        parse_comment(block)
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
