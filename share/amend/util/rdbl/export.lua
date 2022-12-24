--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[[>>[amend.api.util.rdbl.export] Exporting.

FIXME

]]
local M = require "amend.util.rdbl.version"
local modimport = M.modimport

modimport "amend.util.rdbl.types"

local tinsert = table.insert
local tremove = table.remove
local tunpack = table.unpack
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
local typeof = M.typeof
local isinteger = M.isinteger
local escape = M.escape
local getkeys = M.getkeys
local tokey = M.tokey
local toliteral = M.toliteral

local _DOCUMENT = M._DOCUMENT

local export_mt = {
    -- Setup exporter.
    --
    setup = function(self, opts)
        self._file = opts.file -- output stream
        self._indent = opts.indent -- basic indentation string
        self._level = 0 -- indentation level
        self._last = "EOL" -- last output ("EOL", "KEY", or "DASH")
        self._convert = nil -- user-supplied literal conversion function
        self._compat = opts.compat -- YAML compatibility
    end,
    -- Export a document.
    --
    document = function(self, content, name)
        local f = self._file
        if name then
            fprintf(f, "%s %s\n", _DOCUMENT, tostring(name))
        else
            fprintf(f, "%s\n", _DOCUMENT)
        end

        if content then
            self:dump(content)
        end
    end,
    -- Make indentation string.
    --
    indent = function(self)
        return srep(self._indent, self._level)
    end,
    -- Terminate line.
    --
    terminate = function(self)
        fprintf(self._file, "\n")
        self._last = "EOL"
    end,
    -- In-/decrement level.
    --
    enter = function(self, x)
        self._level = self._level + x
    end,
    --
    leave = function(self, x)
        self._level = self._level - x
    end,
    -- Dump an array (sequence).
    --
    dump_array = function(self, t, subt)
        local f = self._file

        if subt == "table" then
            if self._last ~= "EOL" then
                self:terminate()
            end

            local indents = self:indent()

            self:enter(1)
            for _, v in ipairs(t) do
                fprintf(f, "%s-", indents)
                self._last = "DASH"
                self:dump(v)
            end
            self:leave(1)
        else
            assert(self._last ~= "EOL")

            local function emit(value, comma)
                if type(value) == "string" then
                    fprintf(f, "%q", escape(value))
                else
                    fprintf(f, "%s", tostring(value))
                end

                if comma then
                    fprintf(f, ", ")
                end
            end

            local N = #t
            if N > 8 then
                local traditional = self._compat
                if not traditional then
                    -- strings only, are also traditionally formatted...
                    traditional = true
                    for i, v in ipairs(t) do
                        if type(v) ~= "string" then
                            traditional = false
                            break
                        end
                    end
                end

                if traditional then
                    fprintf(f, "\n")
                    local listindent = self:indent()
                    for i, v in ipairs(t) do
                        fprintf(f, "%s- %s\n", listindent, tostring(v))
                    end
                else
                    local listindent = srep(self._indent, self._level - 1) -- FIXME why - 1 ?
                    fprintf(f, " {\n%s", listindent)
                    for i, v in ipairs(t) do
                        emit(v, i < N)

                        if i % 8 == 0 and i < N then
                            fprintf(f, "\n%s", listindent)
                        end
                    end
                    fprintf(f, "\n")
                end
            else
                fprintf(f, " { ")
                for i, v in ipairs(t) do
                    emit(v, i < N)
                end
                fprintf(f, " }\n")
            end
            self._last = "EOL"
        end
    end,
    -- Dump a map.
    --
    dump_map = function(self, t)
        -- assemble key order
        local order = t[ORDER]
        if order then
            -- note: it's the user's responsibility to get this right
        else
            order = getkeys(t)
        end

        local f = self._file
        local indents = self:indent()

        -- check if indent/newline is required
        local offset = 1
        if self._last ~= "EOL" then
            if #order == 1 and self._last ~= "KEY" then
                if not self._compat then
                    offset = 0
                end
                indents = " "
            else
                self:terminate()
            end
        end

        -- loop
        self:enter(offset)
        for _, k in ipairs(order) do
            -- emit key
            fprintf(self._file, "%s%s:", indents, tokey(k))
            self._last = "KEY"

            -- dump value
            self:dump(t[k])
        end
        self:leave(offset)
    end,
    -- Dump content.
    --
    dump = function(self, t)
        if t == ORDER then
            return
        end

        local f = self._file
        local indents = self:indent()

        local tn, cat, subt = typeof(t)
        if tn == "table" then
            if cat == "array" then
                self:dump_array(t, subt)
            elseif cat == "map" then
                self:dump_map(t)
            elseif cat == "null" then
                fprintf(f, "{}\n")
                self._last = "EOL"
            else
                -- FIXME see import self:error
                error("unsupported table format")
            end
        else
            assert(self._last ~= "EOL")
            t = toliteral(t, self._convert)
            if type(t) == "table" then
                fprintf(f, " |\n")
                for _, l in ipairs(t) do
                    fprintf(f, "%s%s\n", indents, l)
                end
            else
                fprintf(f, " %s\n", t)
            end

            self._last = "EOL"
        end
    end,
    -- Run the exporter.
    --
    run = function(self, t)
        local tn, cat, subt = typeof(t)
        if tn == "null" or cat == "null" then
            return
        end

        if cat ~= "array" or subt ~= "table" then
            error(
                "expected a sequence (array) of documents, got " .. tn .. "|" .. (cat or "?") .. "|" .. (subt or "?"),
                2
            )
        end

        for _, doc in ipairs(t) do
            local name, content = next(doc)

            if isinteger(name) and name == 1 then
                self:document(content)
            else
                self:document(content, name)
            end
        end
    end
}
export_mt.__index = export_mt

-- [[ MODULE ]]

--- `export()` 
-- Export a table.
-- @param
--      t       The table.
--      [opts]  Export options (FIXME).
--
-- The provided table `t` has the format (named an unnamed documents may be mixed):
--
--      { { {doc1_elements} }, {doc2_name = {doc2_elements} }, ...}
--
local function export(t, opts)
    assert(type(t) == "table", "expected a table")

    opts = opts or {}
    opts.file = opts.file or io.stdout
    opts.mode = opts.mode or "w"
    opts.indent = opts.indent or "    "
    -- opts.convert FIXME document
    opts.compat = (opts.compat == nil) and M.YAML_COMPAT or opts.compat

    -- open file (if needed)
    local closefile = false
    if type(opts.file) == "string" then
        opts.file = assert(io.open(opts.file, opts.mode))
        closefile = true
    end

    -- output documents
    local exporter = setmetatable({}, export_mt)
    exporter:setup(opts)
    exporter:run(t)

    -- close file (if needed)
    if closefile then
        opts.file:close()
        opts.file = nil
    end
end
M.export = export

return M
