--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] local M = require 'amend.docs.__module'

local strlen = string.len

-- scan for language "extractors"
local extractor = {}
local language = {}

local dirname = fs.parts(filename())
fs.dodir(dirname, function(item)
    local lang = item[2]
    if lang ~= "docs" then
        local mod = require("amend.docs." .. lang)
        language[lang] = mod

        for _, ext in ipairs(mod.extensions) do
            extractor[ext] = mod.parse
        end
    end
end, {
    mode = 'directory'
})

local function generate(config)
    message(STATUS, "Generating documentation...")

    local parse = M.parse

    -- initialize config
    if type(config) == 'string' then
        config = assert(dofile(config))
    end
    assert(type(config) == 'table')

    assert(type(config.input) == 'table', "'input' table in configuration is missing")
    assert(type(config.output) == 'table', "'output' table in configuration is missing")
    assert(type(config.include) == 'table', "'include' table in configuration is missing")
    assert(type(config.exclude) == 'table', "'exclude' table in configuration is missing")
    config.input.tabsize = config.input.tabsize or 8
    -- FIXME ...

    -- setup structure
    local db = {
        config = config,
        files = {},
        structure = {}
    }

    -- generate file list
    local files = db.files
    fs.dodir(config.input.directory, function(item)
        -- file info
        local fullfile = item[0]
        local basename = fs.relpath(fullfile, config.input.directory)
        local extension = item[3]

        -- target name
        local targetname = basename:sub(1, -1 - strlen(extension))

        for _, st in ipairs(config.input.strip or {}) do
            if basename:find("^" .. st) then
                targetname = targetname:sub(strlen(st) + 1)
            end
        end

        targetname = targetname:gsub("[\\/]", ".")

        -- extension overrides
        if config.include.files and config.include.files[basename] then
            if config.include.files[basename].extension then
                extension = config.include.files[basename].extension
            end
        end

        local extract = extractor[extension]
        if extract then
            local node = {
                path = fullfile,
                file = basename,
                target = targetname
            }

            extract(node)
            files[basename] = node
        end
    end, {
        mode = "file",
        exclude = {fs.relpath(fs.currentdir(), config.input.directory), table.unpack(config.exclude.patterns or {})},
        include = config.include.patterns,
        directories = config.include.directories,
        recurse = true
    })

    -- parse sources (and build document structure)
    for _, data in pairs(db.files) do
        parse(db, data)
    end

    io.dump(db, {key = "db"})
end

-- [[ MODULE ]]
M.generate = generate
return M
