--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --

local M = require "amend.docs.__module" --

--[[>>[amend.api.docs.api.core] Generator core.
]] local strsplit = string.split
local strformat = string.format
local tinsert = table.insert
local tremove = table.remove
local tmake = table.make
local tconcat = table.concat
local tunpack = table.unpack
local cindex = class.index

--- `core`
--
-- The document generator "core".
--
--{
local core =
    class(M) "core" {
    __public = {
        config = void,
        files = {},
        parsed = {},
        tree = {}
    }
}

function core:__init(config)
    assert(type(config) == "table", "expected a configuration table")

    self.config = config
    self:readall()
end

function core:read(path, language)
    local workdir = self.config.input.directory
    local strip = self.config.input.strip

    -- assemble stripped name
    local name = path
    for _, s in ipairs(strip) do
        local b, e = path:find(s)
        if b == 1 then
            name = path:sub(e + 1)
            break
        end
    end

    -- check
    if self.files[name] and (self.files[name].origin ~= path) then
        error(
            strformat(
                "Files\n    %q and\n    %q\nyield the same stripped name: %q",
                self.files[name].origin,
                path,
                name
            )
        )
    end

    -- read file
    local f = M.stream.file()
    f:load(fs.concat(workdir, path), workdir)
    f.language = language or f.language

    self.files[name] = f
    return f
end

function core:readall()
    local config = self.config
    local workdir = config.input.directory
    local template = self.config.output.template

    -- scan tree
    fs.dodir(
        workdir,
        function(item)
            local path = fs.relpath(item[0], workdir)
            if path == template then
                return
            end

            local alt = config.include.files[item[2]]
            local extension = (alt and alt.language) or item[3]

            if M.extension[extension] then
                self:read(path, extension)
            end
        end,
        {
            mode = "file",
            exclude = {table.unpack(config.exclude.patterns)},
            include = config.include.patterns,
            directories = config.include.directories,
            recurse = true
        }
    )

    -- read index template
    local tmpl = self:read(template)
    tmpl.id = "index"
end

function core:parse(id, thefile)
    thefile = thefile or self.files[id]

    local lang = M.extension[thefile.language]

    self.parsed[id] = lang.parse(thefile)
end

function core:parseall()
    for id, thefile in pairs(self.files) do
        self:parse(id, thefile)
    end
end

function core:__dump(options)
    options.key = options.key or "docs"
    options.visited = options.visited or {}
    options.visited[self.config] = true
    options.visited[self.files] = true
    -- options.visited[self.parsed] = true
    io.dump(self, options)
end

function core:gentree()
    -- make an "id" list
    local idlist = {}

    local visited = {}
    local function findid(t)
        for _, v in pairs(t) do
            if type(v) == "table" then
                if v.id then
                    if not idlist[v.id] then
                        tinsert(idlist, v.id)
                        idlist[v.id] = true
                    end
                end

                if not visited[v] then
                    visited[v] = true
                    findid(v)
                end
            end
        end
    end

    findid(self.parsed)

    -- io.dump(idlist)
    -- os.exit()
end
--}

-- [[ MODULE ]]
return M
