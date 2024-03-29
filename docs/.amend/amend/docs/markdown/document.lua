--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --

local M = require "amend.docs.markdown.__module" --

--[[>>[amend.api.docs.api.markdown.document] Markdown documents.
]] require "amend.docs.markdown.types"

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

local section = M.section
local paragraph = M.paragraph
local text = M.text

--- `document`
--
-- FIXME
--
--{
local document =
    class(M) "document" {
    __inherit = {docs.node},
    __public = {
        core = void,
        stack = void,
        id = void
    }
}

function document:__init(core)
    docs.node.__init(self)
    self.core = core
    self.stack = {self}
end

function document:addheading(level, tbl, context)
    local stack = self.stack
    local top = stack[#stack]

    assert(level > 0)

    -- go to heading level
    while #stack > level do
        tremove(stack)
    end
    top = stack[#stack]

    if #stack < level then
        docs.notice(ERROR, context, "invalid header (no superior)")
    end

    -- check title text
    local title = tbl.text
    if title then
        local tmp = strtrim(title.text)
        if tmp:sub(-1, -1) == "." then
            title.text = tmp:sub(1, -2)
        end
    end

    -- create section
    local sec = section()
    sec.title = title
    sec.reference = tbl.reference
    sec.context = context

    top:add(sec)
    tinsert(stack, sec)
end

function document:parse(stream)
    -- set id
    if not self.id then
        self.id = stream.id
    end

    -- parse document (or fragment)
    local stack = self.stack

    for aline in stream:lines() do
        local top = stack[#stack]

        -- HEADING
        local heading = aline:re("^(#+)(.*)")
        if heading then
            local depth, rest = tunpack(heading)

            -- amend annotation
            local title
            local reference = rest:re("%s*[[]")
            if reference then
                reference = rest:re("%s*[[]([^]]*)[]]%s*(.*)")
                if not reference then
                    docs.notice(ERROR, aline.origin(1), "invalid annotation: expected a closing bracket")
                end

                reference, title = tunpack(reference)
            else
                title = rest
            end

            -- disect heading
            depth = #depth
            title:trim()

            self:addheading(
                depth,
                {
                    text = title,
                    reference = reference
                },
                aline.origin
            )

            goto continue
        end

        -- PARAGRAPHS
        if #aline == 0 then
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

        -- TEXT
        local textnode = text(aline)
        para:add(textnode)

        -- ANNOTATION
        local thedocument = stack[1]

        -- include
        local include = aline:re("(.*)<<[[]([^]]+)[]](.*)")
        if include then
            local indentation, reference, trailing = tunpack(include)

            if not indentation:re("^[%s>]*$") then
                docs.notice(ERROR, indentation.origin, "invalid indentation before include")
            elseif not trailing:re("^%s*$") then
                docs.notice(ERROR, trailing.origin, "trailing garbage after include")
            end

            if reference[1] == '"' then
                local fname = tostring(reference:sub(2, -2))
                local include = self.core.files[fname]
                if not include then
                    docs.notice(ERROR, reference.origin, "file does not exist")
                end

                -- FIXME this is wrong - and indentation is not handled...
                para:remove()
                self:parse(include)
            else
                local ann =
                    docs.annotation(
                    "include",
                    {
                        indent = indentation,
                        reference = reference
                    },
                    textnode
                )
                textnode:add(ann)
            end

            goto continue
        end

        local function annotate(left, right)
            -- left fragment
            if not left or (#left == 0) then
                return
            end

            local fragment

            -- MACRO
            fragment = left:re("([@][%l]+)")
            if fragment then
                local head, tail = left:sub(1, fragment[0][1] - 1), left:sub(fragment[0][2] + 1)
                local name = tunpack(fragment)
                annotate(head)

                local ann =
                    docs.annotation(
                    "macro",
                    {
                        sub = fragment[0],
                        name = tostring(name)
                    },
                    textnode
                )
                textnode:add(ann)

                annotate(tail)
                return
            end

            -- LINKS
            fragment = left:re("[[]([^]]+)[]][(]([^)]+)[)]")
            if not fragment then
                fragment = left:re("[[]([^]]+)[]]")
            end

            if fragment then
                local head, tail = left:sub(1, fragment[0][1] - 1), left:sub(fragment[0][2] + 1)
                local text, ref = tunpack(fragment)
                if #fragment == 1 then
                    ref = text
                    text = nil
                end

                annotate(head)

                local ann =
                    docs.annotation(
                    "link",
                    {
                        sub = fragment[0],
                        reference = ref,
                        text = text
                    },
                    textnode
                )
                textnode:add(ann)

                annotate(tail)
                return
            end

            -- right fragment
            if right and #right > 0 then
                annotate(right)
            end
        end

        -- FIXME is this correct
        if not aline:re("^[%s>]+") then
            annotate(aline)
        end

        ::continue::
    end
end

function document:write(path)
    local f = assert(io.open(path, "w"))

    local function emit(part, level)
        if part.tag == "document" then
            for _, v in ipairs(part) do
                emit(v, level + 1)
            end
        elseif part.tag == "section" then
            f:write("\n", strrep("#", level))

            f:write(" ", tostring(part.title))

            local has_attr = part.reference or part.attributes
            if has_attr then
                f:write("{")

                if part.reference then
                    f:write('#', tostring(part.reference))
                end

                if part.attributes then
                    f:write(part.attributes)
                end

                f:write("}")
            end

            f:write("\n")

            for _, v in ipairs(part) do
                emit(v, level + 1)
            end
        elseif part.tag == "paragraph" then
            f:write("\n")

            for _, v in ipairs(part) do
                emit(v, level)
            end
        elseif part.tag == "text" then
            f:write(tostring(part.content), "\n")
        elseif (part.tag == "document") or (part.tag == "root") then
            for _, v in ipairs(part) do
                emit(v, level)
            end
        else
            io.dump(part)
            error("internal error: unrecognized part '" .. part.tag .. "'")
        end
    end

    f:write("% ", tostring(self[1].title), "\n")

    for _, sec in ipairs(self) do
        emit(sec, 1)
    end

    f:close()
end

function document:__dump(options)
    options.visited = options.visited or {}
    options.visited[self.stack] = true
    io.dump(self, options)
end
--}

-- [[ MODULE ]]
return M
