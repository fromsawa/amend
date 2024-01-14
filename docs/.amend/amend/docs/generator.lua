--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --

local M = require "amend.docs.__module"

--[[>>[amend.api.docs.api.core] Generator core.
]] 
local strsplit = string.split
local strformat = string.format
local strlen = string.len
local tinsert = table.insert
local tremove = table.remove
local tmake = table.make
local thas = table.has
local tcount = table.count
local tconcat = table.concat
local kpairs = table.kpairs
local tsort = table.sort
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
    -- options.visited = options.visited or {}
    -- options.visited[self.config] = true
    -- options.visited[self.files] = true
    -- options.visited[self.parsed] = true
    io.dump(self, options)
end

function core:read(path, language)
    message(STATUS, "reading %q", path)
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
            else
                message(STATUS, "ignoring %q", path)
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

    self.parsed[id] = lang.parse(self, thefile)
end

function core:parseall()
    for id, thefile in pairs(self.files) do
        self:parse(id, thefile)
    end
end

function core:processall()
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

    -- gather documents by id, build hierarchy
    local documents = {}
    local hierarchy = {}

    local visited = {}
    local function findid(t)
        for _, v in pairs(t) do
            if type(v) == "table" then
                -- avoid infinite recursion
                if not visited[v] then
                    visited[v] = true
                    findid(v)
                end

                -- create id entry
                local id = v.id
                if id then
                    if id ~= "index" then
                        local ns, parent = namespace(hierarchy, id, true)
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
    for _, v in kpairs(hierarchy) do
        tinsert(v, "index")
        documents["index"] = self.parsed[self.config.output.template]
        break
    end

    -- helper for recursing the structure
    local function recurse(t, fn)
        for _, v in kpairs(t) do
            recurse(v, fn)
        end

        fn(t)
    end

    -- do the including (top to bottom)
    local function make(id, node)
        local ns = namespace(hierarchy, id)

        message(INFO, "creating document %q", id)
        local md = M.markdown.document()
        md.id = id

        if ns then
            -- sort keys
            local keys = {}
            for k, _ in pairs(ns) do
                tinsert(keys, k)
            end
            -- FIXME should sort by heading...
            tsort(keys)

            -- loop over keys
            for _, k in ipairs(keys) do
                local n = ns[k]
                local refid = n[1]
                if not refid then
                    refid = id .. "." .. k
                    make(refid, ns)
                end
                local refdoc = documents[refid]
                assert(refdoc ~= nil)
                tinsert(md, refdoc)
                documents[refid] = nil
            end
            ns[1] = id
        else
            message(WARNING, "document %q is empty", id)
        end

        documents[id] = md
        return md
    end

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
                            if reference[1] == "." then
                                reference.text = theid .. reference.text
                            end

                            -- check, document exists
                            local refid = tostring(reference)
                            local refdoc = documents[refid]

                            if not refdoc then
                                refdoc = make(refid, node)
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

    recurse(hierarchy, include)

    -- resolve autolinks
    -- for id, doc in pairs(documents) do
    --     print(id, doc)
    --     if id == 'amend.api.lua.io' then
    --         print("IO")
    --     end
    -- end
    
    -- build output
    local function make_output(t)
        for k, v in kpairs(t) do
            make_output(v)

            local doc = documents[v[1]]
            if doc then
                v[1] = doc
            else
                v[1] = nil
            end

            if tcount(v) == 0 then
                t[k] = nil
            end
        end
    end
    make_output(hierarchy)
    self.output = hierarchy
end

function core:writeall()
    local output = self.output
    local directory = self.config.output.directory
    local rootdir = self.config.input.directory

    local path = fs.concat(rootdir, directory, "..")
    fs.mkdir(path)
    fs.pushd(path)

    local function emit(node)
        for k, v in kpairs(node) do
            fs.mkdir(k)
            fs.pushd(k)

            local doc = v[1]
            if doc then
                local basename = doc.id
                basename = basename:match(".*[.]([^.]+)$") or basename
                basename = basename .. ".md"

                doc:write(basename)
            end

            emit(v)
            fs.popd(k)
        end
    end

    emit(self.output)

    fs.popd(path)
end
--}

-- [[ MODULE ]]
return M
