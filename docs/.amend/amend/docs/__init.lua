--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] local M = require 'amend.docs.__module'

local strrep = string.rep

require 'amend.docs.stream'
require 'amend.docs.file'
require 'amend.docs.structure'
require 'amend.docs.generator'

--- `docs.extension`
--
-- File-extension to language mapping.
--
local extension = {}

-- load languages
local moduledir = fs.parts(filename())
fs.dodir(moduledir, function(item)
    local path = item[0]
    local lang = item[2]

    if path ~= moduledir then
        local mod = require("amend.docs." .. lang)
        message(TRACE[1], "loaded 'amend.docs." .. lang .. "'")

        local ext = mod.extension or {}
        for _, x in ipairs(ext) do
            extension[x] = mod
        end

        M[lang] = mod
    end
end, {
    mode = 'directory'
})

--- `docs.notice(level, context, fmt, ...)`
--
-- Output a notice with context.
--
local function notice(level, context, fmt, ...)
    local source, line, column = context.source, context.line, context.column

    if isa(source, M.file) then
        message(level, "In source %q [%d:%d]:", source.file, line, column)
        message(level, "")
        message(level, "    %s", source[line])
        message(level, "%s---^", strrep(" ", column))
        message(level, "")
    else
        message(level, "In source %q [%d:%d]:", tostring(context.source), line, column)
    end

    message(level, fmt, ...)

    while type(level) == 'table' do
        level = table.unpack(level);
    end

    if level <= ERROR[1] then
        os.exit(1)
    end
end

-- [[ MODULE ]]
M.extension = extension
M.notice = notice
return M
