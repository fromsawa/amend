--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] local M = require 'amend.docs.__module'

require 'amend.docs.file'

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
        local mod = require("amend.docs."..lang)
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
    message(level, "In source %q [%d:%d]:", context.source, context.line, context.column)
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
