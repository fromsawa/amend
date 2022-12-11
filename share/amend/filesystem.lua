--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[[>>[amend.api.filesystem] #+ Extensions to LuaFileSystem.
]]
local mod = {}

local dirsep = package.config:sub(1, 1)

require "amend.lua.table"
require "amend.lua.string"

local tconcat = table.concat
local tinsert = table.insert
local tremove = table.remove
local tsort = table.sort
local thas = table.has
local sany = string.any

local fs = require "lfs"
for i, f in pairs(fs) do
    mod[i] = f
end
local attributes = fs.attributes
local symlinkattributes = fs.symlinkattributes
local dir = fs.dir
local currentdir = fs.currentdir
local chdir = fs.chdir
local mkdir = fs.mkdir
local touch = fs.touch

-->> ##+ `fs.exists(filename)`
-- Check if file exists.
-- ::args
--      filename        Path or file-name to check.
-- ::returns
--      ''true'' if file or path exists, ''false'' otherwise.
--
local function exists(filename)
    return attributes(filename) ~= nil
end

-->> ##+ `fs.isnewer(file, another)`
-- Check if a ''file'' is newer than ''another''.
-- ::returns
--      ''nil'' if `file` does not exist,
--      ''true'' if `file` is newer or `another` does not exist,
--      ''false'' otherwise.
--
local function isnewer(file, another)
    if exists(file) then
        if exists(another) then
            local a = attributes(file)
            local b = attributes(another)

            return a.modification > b.modification
        else
            return true
        end
    end
end

-->> ##+ `fs.anynewer(file, ...)`
-- Check if any other file is newer than `file`.
--
-- FIXME
--
local function anynewer(file, ...)
    if exists(file) then
        local retval
        for _, other in ipairs {...} do
            retval = false
            if isnewer(other, file) then
                return true
            end
        end
        return retval
    else
        for _, other in ipairs {...} do
            if exists(other) then
                return true
            end
        end
    end
end

-->> ##+ `fs.concat(...)`
-- Concatenate path elements.
-- ::args
--      ...             List of path elements.
-- ::returns
--      Concatenated path elements using builtin directory seperator.
--
local function concat(...)
    return tconcat({...}, dirsep)
end

-->> ##+ `fs.parts(fname)`
-- Get parts of a file name (path, file and extension).
-- ::args
--      fname           The file- or path-name.
-- ::returns <path>,<file-name>,<extension>
--
local function parts(fname)
    -- see https://stackoverflow.com/questions/5243179/what-is-the-neatest-way-to-split-out-a-path-name-into-its-components-in-lua/12191225
    --     (though one commenter is correct: regex is overkill...)
    local p, f, e = fname:match("(.-)([^\\/]-%.?([^%.\\/]*))$")
    if p:sub(-1, -1) == "/" then
        p = p:sub(1, -2)
    end
    if e == f then
        e = ""
    else
        e = "." .. e
        if e == f then
            -- file name starts with a "."
            e = ""
        end
    end
    if #p == 0 then
        p = "/"
    end
    return p, f, e
end

-->> ##+ `fs.relpath(path, root)`
-- Get relative path with respect to a "root".
-- ::args
--      path            The 'path' to split.
--      root [optional] The root path.
-- ::returns <relative-path>
--
local function relpath(path, root)
    -- prepare "root"
    root = root or currentdir()
    if root == "/" then
        return path
    elseif root:sub(-1) == dirsep then
        root = root:sub(1, -2)
    end

    -- strip root
    if path:match("^" .. root) then
        rpath = path:sub(#root + 1)
        if #rpath == 0 then
            return "."
        elseif rpath:sub(1, 1) == dirsep then
            return rpath:sub(2, -1)
        else
            return path
        end
    else
        return path
    end
end

-- Convert wildcard to regex.
local function wildtorx(s)
    s = s:gsub("[.]", "[.]")
    s = s:gsub("[*]", ".*")
    s = s:gsub("[?]", ".")
    return s
end

-->> ##+ `fs.readwild(file, tbl)`
-- Read a wildcard pattern file.
-- ::args
--      file                The file name (containing wildcard patterns and comments).
--      tbl [optional]      Existing table (with regex patterns).
local function readwild(file, tbl)
    tbl = tbl or {}

    local f = io.open(file)
    if f then
        for pattern in f:lines() do
            pattern = pattern:match "^%s*(.-)%s*$" -- trim

            if not pattern:match("^#") and #pattern > 0 then
                pattern = wildtorx(pattern)
                tinsert(tbl, pattern)
            end
        end
    end
    f:close()

    return tbl
end

-->> ##+ `fs.dodir(path, callback, options)`
-- Execute a function for each directory element possibly recursively.
-- ::args
--      path                    The path to iterate over.
--      callback                Callback function for elements (must return true for recursion).
--      options [optional]      Options.
--
-- This function executes the `callback` for each element in the alpha-numerically
-- sorted directory list. Arguments passed to the callback are:
--      [1]     Table with entries as returned by `fs.parts` and the absolute path at index 0.
--              The table also contains the key 'attr' with file attributes as returned by `symlinkattributes`,
--              and 'options', with the `options` table.
-- If recursion is enabled, FIXME
--
-- Options:
--      exclude             List of regex-patterns of files or directories to ignore (default: {'[.]', '[.][.]'}).
--      include             List of regex-patterns of files or directories to include (overrides 'exclude').
--      extension           Only report files or directories matching list of given extensions.
--      mode                File type (`mode` field of `attributes()` function).
--      follow              Follow symbolic links (default: false)
--      recurse             Enable directory recursion (default: false).
--      depth               Directory depth (default: 0)
--
local function __ls(path, options)
    local t = {}
    for file in dir(path) do
        local exclude = sany(file, options.exclude, true)
        local include = sany(file, options.include, true)
        if not exclude or include then
            tinsert(t, file)
        end
    end
    tsort(t)
    return t
end

local function __dodir(fname, callback, options, first)
    -- get file attributes
    local attr = symlinkattributes(fname)
    if attr.target and not options.follow then
        return
    end
    local mode = attr.mode
    local isdir = mode == "directory"
    local path, file, extension = parts(fname)

    -- check conditions (to execute callback)
    local docall = true

    if options.mode then
        docall = docall and thas(options.mode, mode)
    end

    if options.extension then
        local use = thas(options.extension, extension)

        -- may be overriden by "include"
        use = use or sany(file, options.include, true)

        docall = docall and use
    end

    -- execute callback
    local retval
    if docall then
        retval =
            callback(
            {
                path,
                file,
                extension,
                [0] = fname,
                attr = attr,
                options = options
            }
        )
    end

    -- check if we do recursion
    local recurse = options.recurse
    if retval ~= nil then
        -- callback overrides default
        recurse = retval
    end

    -- recurse
    if isdir and (first or recurse) then
        options.depth = options.depth + 1
        local files = __ls(fname, options)
        for _, f in ipairs(files) do
            __dodir(concat(fname, f), callback, options)
        end
        options.depth = options.depth - 1
    end
end

local function dodir(path, callback, options)
    -- defaults
    options = options or {}
    options.exclude = options.exclude or {"[.]", "[.][.]"}
    options.include = options.include or {}
    options.follow = options.follow or false
    options.recurse = options.recurse or false
    options.depth = options.depth or 0
    if options.mode then
        if type(options.mode) ~= "table" then
            options.mode = {options.mode}
        end
    end

    -- run it
    __dodir(path, callback, options, true)
end

-- pushd/popd
local stackd = {}
setmetatable(
    stackd,
    {
        __gc = function(obj)
            if #stackd > 0 then
                print("ERROR: unbalanced pushd/popd")
            end
        end
    }
)

-->> ##+ `fs.pushd(dir)`
-- "Push" directory.
--
-- Equivalent of shell command ''pushd''.
--
local function pushd(dir)
    tinsert(stackd, currentdir())
    chdir(dir)
end

-->> ##+ `fs.popd()`
-- "Pop" directory.
--
-- Equivalent of shell command ''popd''.
--
local function popd()
    chdir(stackd[#stackd])
    tremove(stackd)
end

-->> ##+ `fs.rmkdir(fpath)`
-- Recursively create directory.
-- ::args
--      fpath       The directory-path to create.
-- ::returns <status>[, <error-message>]
--      The value of LuaFilesystem's [mkdir](https://keplerproject.github.io/luafilesystem/manual.html#mkdir) command.
--
local function rmkdir(fpath)
    local parent = parts(fpath)
    if not attributes(parent) then
        local x, msg = rmkdir(parent)
        if not x then
            return x, msg
        end
    end

    return mkdir(fpath)
end

-->> ##+ `fs.grep(fname, pattern)`
-- Grep-like matching
--
local function grep(fname, pattern)
    local f = io.open(fname)
    if f then
        local txt = f:read("a")
        return txt:match(pattern)
    end
end

-->> ##+ `fs.filetype(fname)`
-- Get file type (from extension).
-- FIXME
local function filetype(fname)
    local _, _, ext = parts(fname)
    return EXTENSION[ext]
end

--- Touch all files, ensuring same access and modification time.
-- ::args
--      files...    File names to touch.
--      [options]   Options (last argument).
--
--  FIXME
--
local function touchall(...)
    local args = {...}
    local options
    if type(args[#args]) == "table" then
        options = tremove(args)
    end

    local atime = options.atime or options.mtime or os.time()
    local mtime = options.mtime or atime

    for _, f in ipairs(args) do
        touch(f, atime, mtime)
    end
end

-- [[ MODULE ]]
mod.exists = exists
mod.isnewer = isnewer
mod.anynewer = anynewer
mod.concat = concat
mod.parts = parts
mod.relpath = relpath
mod.readwild = readwild
mod.dodir = dodir
mod.stackd = stackd
mod.pushd = pushd
mod.popd = popd
mod.remove = os.remove
mod.rename = os.rename
mod.rmkdir = rmkdir
mod.grep = grep
mod.filetype = filetype
mod.touchall = touchall

return mod
