--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] local M = require "amend.docs.markdown.__module"

require 'amend.docs.markdown.types'

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

    if mtype == 'integer' then
        level = fmt
        fmt = args[1]
        tremove(args, 1)
    end

    local msg = strformat(fmt, tunpack(args))
    error(msg, level + 1)
end

local section = M.section
local paragraph = M.paragraph
local text = M.text

--- `document`
-- 
-- FIXME
--
-- {
local document = class(M) "document" {
    __inherit = {docs.node},
    __public = {
        options = {
            tabsize = 4
        },
        stack = void
    }
}

function document:__init(options)
    docs.node.__init(self)

    for k, v in pairs(options) do
        self.options[k] = v
    end

    self.stack = {self}
end

function document:addheading(level, tbl, context)
    local stack = self.stack
    local top = stack[#stack]

    while #stack > level do
        tremove(stack)
    end
    top = stack[#stack]

    if #stack < level then
        docs.notice(ERROR, context, "invalid header (no superior)")
    end

    local sec = section()
    sec.level = level
    sec.title = tbl.text
    sec.attributes = tbl.attributes
    sec.reference = tbl.reference
    sec.context = context

    top:add(sec)
    tinsert(stack, sec)
end

function document:parse(stream)
    local stack = self.stack

    for line, ctxt in stream:lines() do
        local top = stack[#stack]

        -- HEADING
        local heading, spaces, title = line:match("^(#+)([%s]+)(.*)")
        if heading then
            -- disect heading
            heading = strlen(heading)

            local line = title
            local attributes = {title:find("{[^}]*}")}
            local link = {title:find("[[][^]]+[]]")}

            if attributes[1] then
                local tmp = line:sub(attributes[1] + 1, attributes[2] - 1)
                line = line:sub(1, attributes[1] - 1) .. line:sub(attributes[2] + 1)
                attributes = tmp
            else
                attributes = nil
            end

            if link[1] then
                local tmp = line:sub(link[1] + 1, link[2] - 1)
                -- FIXME check link format
                line = line:sub(1, link[1] - 1) .. line:sub(link[2] + 1)
                link = tmp
            else
                link = nil
            end

            line = strtrim(line)
            local line, point, rest = line:match("^([^.]+)([.]?)(.*)")
            if not line then
                fmterror("Internal error: could not parse %q", title)
            end
            if strlen(rest) > 0 then
                local column = strlen(heading) + strlen(spaces) + strlen(link) + strlen(line) + strlen(point) + 1
                docs.notice(ERROR, ctxt, "trailing garbage after fullstop")
            end

            self:addheading(heading, {
                text = line,
                attributes = attributes,
                reference = link
            }, ctxt)

            goto continue
        end

        -- PARAGRAPHS
        if strlen(line) == 0 then
            if isa(top, paragraph) then
                tremove(stack)
            end

            goto continue
        end

        local para = top
        if not isa(top, paragraph) then
            para = paragraph()
            top:add(para)

            tinsert(stack, para)
            top = para
        end

        -- INCLUDE
        local before, include, after = line:match("(.*)<<[[]([^]]+)[]](.*)")
        if include then
            if not before:match("^[%s]*$") then
                docs.notice(ERROR, stream:context(i, 1), "garbage before include")
            elseif not before:match("^[%s]*$") or not after:match("^[%s]*$") then
                docs.notice(ERROR, stream:context(i, strlen(before) + strlen(include) + 5),
                            "trailing garbage after include")
            end

            local sub = docs.substitution("include", {
                indent = before,
                reference = include
            }, stream:context(i))
            tinsert(para.substitutions, sub)
            tremove(stack)

            goto continue
        end

        -- TEXT
        local t = text()
        t.content = line
        t.context = stream:context(i)

        para:add(t)

        -- SUBSTITUTIONS
        while true do
            local bpos, epos, tag, content

            -- [text](link)
            bpos, epos = line:find("[[][^]]+[]][(][^)]+[)]")
            if bpos then
                content = line:sub(bpos, epos)
                tag = 'link'

                line = line:sub(epos + 1)
            end

            -- [link]
            if not bpos then
                bpos, epos = line:find("[[][^]]+[]]")
                if bpos then
                    content = line:sub(bpos, epos)
                    tag = 'link'

                    line = line:sub(epos + 1)
                end
            end

            -- @macro
            if not bpos then
                bpos, epos = line:find("@[%l]+")
                if bpos then
                    content = line:sub(bpos, epos)
                    tag = 'macro'

                    line = line:sub(epos + 1)
                end
            end

            if tag then
                local sub = docs.substitution(tag, content, t)
                tinsert(para.substitutions, sub)
            else
                break
            end
        end

        ::continue::
    end
end

function document:write(path)
    local f = assert(io.open(path, "w"))

    local function emit(part, level)
        if part.tag == 'section' then
            f:write("\n", strrep('#', level), ' ', part.title)

            if part.reference then
                -- FIXME
            end

            if part.attributes then
                f:write(" {", part.attributes, "}")
            end

            f:write("\n")

            for _, v in ipairs(part) do
                emit(v, level + 1)
            end
        elseif part.tag == 'paragraph' then
            f:write("\n")

            for _, v in ipairs(part) do
                emit(v, level)
            end
        elseif part.tag == 'text' then
            f:write(part.content, "\n")
        else
            io.dump(part)
            os.exit()
        end
    end

    f:write("% ", self[1].title, "\n")

    for _, sec in ipairs(self) do
        emit(sec, 1)
    end

    f:close()
end
-- }

-- [[ MODULE ]]
return M