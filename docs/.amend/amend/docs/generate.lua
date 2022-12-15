--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] 

local M = require 'amend.docs.module'

M.syntax = {}
M.syntax.lua = require 'amend.docs.lua.syntax'
M.syntax.md = require 'amend.docs.markdown.syntax'

local function generate(config)
    message(STATUS, "Generating documentation...")

    -- initialize config
    if type(config) == 'string' then
        config = assert(dofile(config))
    end
    assert(type(config) == 'table')

    assert(type(config.input) == 'table', "'input' table in configuration is missing")
    assert(type(config.output) == 'table', "'output' table in configuration is missing")
    assert(type(config.include) == 'table', "'include' table in configuration is missing")
    assert(type(config.exclude) == 'table', "'exclude' table in configuration is missing")
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
        local file = fs.relpath(fullfile, config.input.directory)
        local ext = item[3]
        
        -- find syntax 'extractor'
        local tag = ext:sub(2)
        local syntax = M.syntax[tag]
        if not syntax then
            tag = config.include.files and config.include.files[file] and config.include.files[file].syntax
            syntax = M.syntax[tag]
        end

        -- do extract...
        if syntax then
            files[file] = {
                tag = tag,
                file = file,
                path = fullfile,
            }

            syntax(files[file])
        end
    end, {
        mode = "file",
        exclude = {fs.relpath(fs.currentdir(), config.input.directory), table.unpack(config.exclude.patterns or {})},
        recurse = false
    })

    -- parse sources (and build document structure)
    for _,file in pairs(db.files) do
        M.parse(db, file)
    end

    io.dump(db, {key = "db"})
end

-- [[ MODULE ]]
M.generate = generate
return M
