--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --

local M = require "amend.docs.__module" -- --

--[[>>[amend.api.docs.api.core] Generator core.
]] local strsplit = string.split
local strformat = string.format
local strlen = string.len
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
    local index
    local idlist = {}

    local visited = {}
    local function findid(t)
        for _, v in pairs(t) do
            if type(v) == "table" then
                if v.id then
                    if v.id == "index" then
                        index = v
                    elseif not idlist[v.id] then
                        tinsert(idlist, v.id)
                        idlist[v.id] = v
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

    -- span tree
    local function span(name)
        local ns = strsplit(name, ".")
        assert(strlen(ns[1]) > 0, "internal error: a sequential reference appeared")

        local res = self.tree
        for _, k in ipairs(ns) do
            res[k] = res[k] or {}
            res = res[k]
        end

        return res
    end

    for _, ns in ipairs(idlist) do
        local t = span(ns)
        t.__id = ns
    end

    local root
    for k, v in pairs(self.tree) do
        -- note: we only expect a single root node!
        v.__id = "index"
        root = v
        break
    end

    -- resolve "imports"
    local visited = {}

    local function find(name)
        local ns = strsplit(name, ".")
        local res, key, parent = self.tree, nil, nil
        for _, k in ipairs(ns) do
            key = k
            parent = res
            res = res[k]
            if not res then 
                break
            end
        end

        return res, key, parent
    end

    local function handleinc(t, ns, src, dst)
        if type(t) == "table" then
            visited[t] = true

            for _, v in pairs(t) do
                if isa(v, M.annotation) then
                    if v.tag == "include" then
                        local content = v.content
                        local reference = content.reference
                        local import, key, parent = find(tostring(reference))
                        if not import then
                            M.notice(ERROR, reference.origin, "reference does not exist")
                        end

                        dst.__import = dst.__import or {}
                        tinsert(dst.__import, {[key] = import})
                    end
                elseif (type(v) == "table") and not visited[v] then
                    handleinc(v, ns, src, dst)
                end
            end
        end
    end

    handleinc(index, root.__id, index, root)
    for _, ns in ipairs(idlist) do
        print(ns)
        local src = idlist[ns]
        local dst = find(ns)

        assert(isa(src, M.markdown.document))
        handleinc(src, ns, src, dst)
    end

    io.dump(self.tree)
    os.exit()
end
--}

-- [[ MODULE ]]
return M
