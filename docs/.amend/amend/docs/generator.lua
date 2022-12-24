--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --

local M = require "amend.docs.__module" -- -- --

--[[>>[amend.api.docs.api.core] Generator core.
]] local strsplit = string.split
local strformat = string.format
local strlen = string.len
local tinsert = table.insert
local tremove = table.remove
local tmake = table.make
local thas = table.has
local kpairs = table.kpairs
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
        output = {}
    }
}

function core:__init(config)
    assert(type(config) == "table", "expected a configuration table")

    self.config = config
    self:readall()
end

function core:__dump(options)
    options.key = options.key or "docs"
    options.visited = options.visited or {}
    options.visited[self.config] = true
    options.visited[self.files] = true
    -- options.visited[self.parsed] = true
    io.dump(self, options)
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
            directories = table.unpack(config.include.directories),
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

function core:includeall()
    -- find namespace or create it
    local function namespace(t, name, create)
        local ns = strsplit(name, ".")
        local parent
        for _, n in ipairs(ns) do
            if create then
                t[n] = t[n] or {}
            end

            parent = t
            t = t[n]

            if not t then
                break
            end
        end

        return t, parent
    end

    -- build worklist
    local documents = {}
    local worklist = {}

    local visited = {}
    local function findid(t)
        for _, v in pairs(t) do
            if type(v) == "table" then
                -- avoid infinite recursion
                if not visited[v] then
                    visited[v] = true
                    findid(v)
                end

                -- create worklist entry
                local id = v.id
                if id then
                    if id ~= "index" then
                        local ns, parent = namespace(worklist, id, true)
                        if not thas(ns, id) then
                            tinsert(ns, id)
                            documents[id] = v
                        end
                    end
                end
            end
        end
    end

    findid(self.parsed)
    for _, v in kpairs(worklist) do
        tinsert(v, "index")
        documents["index"] = v
        break
    end

    -- do the including (top to bottom)
    local function include(node)
        if not node[1] then
            return
        end

        local id = node[1]
        local doc = documents[id]
        assert(doc ~= nil, id)

        local function parse(t, theid)
            -- section reference
            if t.tag == "section" then
                local reference = t.reference
                if reference then
                    if reference[1] == "." then
                        assert(type(theid) == "string")
                        theid = theid .. tostring(reference)
                    else
                        theid = tostring(reference)
                    end
                end
            end

            -- recurse over document nodes
            for _, v in ipairs(t) do
                if type(v) ~= "table" then
                    goto continue
                end

                -- deepest elements first
                parse(v, theid)

                -- handle include annotation
                local annotation = v.annotation
                if annotation then
                    assert(v.tag == "text")
                    for i, ann in ipairs(annotation) do
                        if ann.tag == "include" then
                            local content = ann.content

                            -- make reference absolute
                            local reference = content.reference
                            if reference[1] == '.' then
                                reference.text = theid .. reference.text
                            end

                            -- check, document exists
                            local refid = tostring(reference)
                            local refdoc = documents[refid]

                            if not refdoc then
                                M.notice(ERROR, reference.origin, "document does not exist")
                            end

                            -- do the include
                            local indent = content.indent
                            if #indent > 0 then
                                error("indented include not supported (yet)")
                            else
                                local parent = v.parent

                                -- replace node
                                for n, child in ipairs(parent) do
                                    if v == child then
                                        parent[n] = refdoc
                                        documents[refid] = nil
                                        goto done
                                    end
                                end

                                error("internal error: should not be reached")

                                ::done::
                            end
                        end
                    end
                end

                ::continue::
            end
        end

        parse(doc)
    end

    local function workon(t)
        for _, v in kpairs(t) do
            workon(v)
        end

        include(t)
    end
    workon(worklist)

    for k,v in pairs(documents) do
        print(k,v)
    end
    -- io.dump(worklist)
    os.exit()
end
--}

-- [[ MODULE ]]
return M
