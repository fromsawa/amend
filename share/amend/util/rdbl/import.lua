--[[
    Copyright (C) 2022-2023 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[[>>[amend.api.util.rdbl.import] Importing.

FIXME

]]
local M = require "amend.util.rdbl.version"
local modimport = M.modimport

modimport "amend.util.rdbl.types"

local mtype = math.type
local tinsert = table.insert
local tremove = table.remove
local tunpack = table.unpack
local tconcat = table.concat
local tsort = table.sort
local tcount = table.count
local sformat = string.format
local srep = string.rep
local ssplit = string.split
local slen = string.len

local function fprintf(outs, fmt, ...)
    return outs:write(sformat(fmt, ...))
end

local ORDER = M.ORDER
local NULL = M.NULL

local isnull = M.isnull
local isinteger = M.isinteger
local escape = M.escape
local getkeys = M.getkeys
local tokey = M.tokey
local tovalue = M.tovalue

--- `isdocument()`
-- Check if start of document.
-- @returns boolean, name
local function isdocument(line)
    local tag, name = line:match("^([^ ]+)[ ]*(.*)$")
    if tag == "---" or tag == "🗎" then
        if name:len() > 0 then
            name = name:trim()
        else
            name = nil
        end
        return true, name
    end
end

--- `splitindent()`
-- Split of indentation
--
local function splitindent(line)
    assert(not line:find("\t"), "invalid tab character in stream")
    local indent, content = line:match("([ ]*)(.*)$")
    return indent:len(), content:trim()
end

--- `unindent()`
-- Unindent.
local function unindent(line, n)
    return line:sub(n + 1)
end

--- `checkindent()`
-- Check indentation
--
local function checkindent(iter)
    local indentation = 4

    -- parse all indentations
    -- (this is necessary, as the first entry could be a literal,
    --  where indentation is not strictly defined)
    local seen, stat = {}, {}
    for line in iter do
        local indent, content = splitindent(line)
        if not seen[indent] then
            seen[indent] = true
            tinsert(stat, indent)
        end
    end

    -- FIXME do some more sanity checks?
    assert(stat[1] == 0, "invalid indentation")
    if stat[2] then
        indentation = stat[2]
    end

    -- reset file position
    return indentation
end

--- `import`
--
--{
local import_mt = {
    --- `setup`
    -- Setup importer.
    --
    setup = function(self, opts)
        self._file = opts.file -- input stream
        self._iter = nil -- line iterator
        self._indent = 0 -- number of spaces indicating a single level
        self._documents = {} -- document table
        self._context = {} -- current context
        self._line = 0 -- current line number
        self._literal = opts.literal -- user-supplied literal conversion function
        self._compat = opts.compat -- YAML compatibility
    end,
    --- `error`
    -- Emit error message.
    --
    error = function(self, fmt, ...)
        local txt = sformat(fmt, ...)
        local where = sformat("[line %d]: ", self._line)
        error(where .. txt, 2)
    end,
    --- `assert`
    -- Formatted assertion.
    --
    assert = function(self, expr, fmt, ...)
        if expr then
            if not fmt then
                error("(INTERNAL ERROR) assertion failed", 1)
            else
                local txt = sformat(fmt, ...)
                local where = sformat("[%d]: ", self._line)
                error(where .. txt, 1)
            end
        end
    end,
    --- `next`
    -- Get next line.
    -- @returns <level>, "<content>"
    next = function(self)
        local line = self._iter()
        if line then
            local n, content = splitindent(line)
            self._line = self._line + 1
            return n // self._indent, content
        else
            return -1
        end
    end,
    --- `literal`
    -- Get next "literal" line.
    -- @param
    --      n       Spaces count.
    -- @returns <content>
    --      literal content, or ''nil'' when end is reached
    --
    literal = function(self, n)
        local value, next, content = {}, -1

        for line in self._iter do
            self._line = self._line + 1

            local sp = line:find("[^ ]") or (line:len() + 1)

            -- some editors erreanously will remove all spaces of empty lines...
            if line:len() == 0 then
                sp = n + 1
            end

            if sp <= n then
                n, content = splitindent(line)
                next, content = n // self._indent, content
                break
            end

            tinsert(value, line:sub(1 + n))
        end

        return tconcat(value, "\n") .. "\n", next, content
    end,
    --- `parse`
    -- Parse elements in current context (ie. indentation level).
    -- @param
    --      level       Current indentation level.
    --      content     Current line content.
    --
    parse = function(self, context, level, content)
        local next  -- next level
        local sequence  -- parsing a sequence or map
        repeat
            local isseq, key, value

            -- new document
            if level == 0 then
                local isdoc, docname = isdocument(content)
                if isdoc then
                    context = {}

                    if docname then
                        tinsert(
                            self._documents,
                            {
                                [docname] = context
                            }
                        )
                    else
                        tinsert(self._documents, {context})
                    end

                    goto nextline
                end
            end

            -- skip comments and empty lines
            if content:len() == 0 or content:sub(1, 1) == "#" then
                goto nextline
            end

            -- check if sequence
            isseq = (content:sub(1, 1) == "-")
            if isseq then
                content = content:sub(2):trim()
            end

            if sequence == nil then
                sequence = isseq
            elseif sequence ~= isseq then
                self:error("sequence and map entries may not be mixed")
            end

            -- check if key-value pair
            key, value = content:match("([^:]+):[ ]*(.*)$")

            key = tokey(key)

            if value and value:len() == 0 then
                value = nil
            end

            -- content?
            if key or content:len() == 0 then
                content = nil
            end

            if not isseq and not key and not content then
                self:error("unrecognized line contents")
            end

            -- handle the cases
            --      -
            --      - key:
            --      - key: value
            --      - content
            --      key:
            --      key: value
            if sequence then
                if content then
                    -- case: "- content"
                    content = tovalue(content, self._literal)
                    tinsert(context, content)
                elseif key then
                    if value then
                        -- case "- key: value"
                        local ch = value:sub(1, 1)
                        if ch == "{" then
                            if value == "{}" then
                                tinsert(
                                    context,
                                    {
                                        [key] = tovalue(value, self._literal)
                                    }
                                )
                            else
                                self:error("arrays not allowed here")
                            end
                        elseif ch == "|" then
                            self:error("literals not allowed here")
                        else
                            -- tinsert(context, {[key] = tovalue(value, self._literal)})
                            local tbl = {
                                [key] = tovalue(value, self._literal)
                            }
                            tinsert(context, tbl)

                            next, content = self:next()
                            if next > level then
                                if next ~= level + 1 then
                                    self:error("invalid indentation")
                                end
                                next, content = self:parse(tbl, next, content)
                            end

                            goto continue
                        end
                    else
                        -- case "- key:"
                        next, content = self:next()

                        if next > level then
                            if next ~= level + 1 then
                                if next ~= level + 2 or not self._compat then
                                    self:error("invalid indentation")
                                end
                            end

                            local map = {}
                            tinsert(
                                context,
                                {
                                    [key] = map
                                }
                            )
                            next, content = self:parse(map, next, content)
                        else
                            tinsert(
                                context,
                                {
                                    [key] = NULL
                                }
                            )
                        end

                        goto continue
                    end
                else
                    -- case "-"
                    next, content = self:next()

                    if next > level then
                        if next ~= level + 1 then
                            self:error("invalid indentation")
                        end

                        local tbl = {}
                        tinsert(context, tbl)
                        next, content = self:parse(tbl, next, content)
                        goto continue
                    else
                        self:error("empty sequence item")
                    end
                end
            else
                if value then
                    -- case "key: value"
                    local ch = value:sub(1, 1)
                    if ch == "{" then
                        if value:match("^{.*}$") then
                            context[key] = tovalue(value, self._literal)
                        else
                            error("FIXME multi-line array")
                        end
                    elseif value:match("^[[].*[]]$") then
                        context[key] = tovalue(value, self._literal)
                    elseif ch == "|" then
                        value, next, content = self:literal(self._indent * (level + 1))
                        context[key] = value
                        goto continue
                    else
                        context[key] = tovalue(value, self._literal)
                    end
                else
                    if not key then
                        self:error("expected a key")
                    end

                    -- case "key:"
                    next, content = self:next()

                    if next > level then
                        if next ~= level + 1 then
                            self:error("invalid indentation")
                        end

                        local map = {}
                        context[key] = map
                        next, content = self:parse(map, next, content)
                    else
                        context[key] = NULL
                    end

                    goto continue
                end
            end

            ::nextline::
            next, content = self:next()

            ::continue::
            if next > level then
                self:error("unexpected indentation")
            end
        until next < level

        -- done
        return next, content
    end,
    --- `run`
    -- Run the importer.
    --
    run = function(self)
        -- check if file starts with a document
        local lineiter = self._file:lines()

        -- check for document start
        local line = lineiter()
        while line:match("^#") do
            line = lineiter()
        end

        if not isdocument(line) then
            error("file is missing document start")
        end

        -- check indentation
        self._indent = checkindent(lineiter)

        -- reset file position and parse
        self._file:seek("set", 0)
        self._iter = self._file:lines()
        self:parse(self._documents, self:next())

        -- strip tables for single documents
        local t = self._documents
        if #t == 1 then
            t = t[1]

            -- strip if unnamed document
            if #t == 1 then
                t = t[1]
            end
        end

        return t
    end
}
import_mt.__index = import_mt
--}

-- [[ MODULE ]]
--- Import data.
-- @param
--      [opts]  Import options (FIXME).
--
local function import(opts)
    opts = opts or {}
    opts.file = opts.file or io.stdin
    opts.compat = (opts.compat == nil) and M.YAML_COMPAT or opts.compat

    -- open file (if needed)
    local closefile = false
    local filename = opts.file
    if type(opts.file) == "string" then
        opts.file = assert(io.open(opts.file, opts.mode))
        closefile = true
    else
        filename = "stdin"
    end

    -- output documents
    local importer = setmetatable({}, import_mt)
    importer:setup(opts)
    local status, data = pcall(importer.run, importer)
    if not status then
        local where, msg = data:match("(.*:[0-9]+:)(.*)$")
        error(filename .. msg .. "\nfrom " .. where, 2)
    end

    -- close file (if needed)
    if closefile then
        opts.file:close()
        opts.file = nil
    end

    return data
end
M.import = import

return M
