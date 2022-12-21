--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] local M = require 'amend.docs.__module'

local tinsert = table.insert
local cindex = class.index

local context = M.context

--- `file`
--
-- {
local file = class(M) "file" {
    __inherit = {M.stream},
    __public = {
        path = void, -- @var `path` Full file path.
        file = void, -- @var `file` Relative file path.
        extension = {}, -- @var `extension` File extension.
    }
}

function file:__init(path, workdir)
    if path then
        self:load(path, workdir)
    end
end

function file:load(path, workdir)
    local iter, errmsg = io.lines(path)
    if not iter then
        error(errmsg, 2)
    end

    path = fs.fullpath(path)
    workdir = workdir or ROOTDIR

    self.path = path
    self.file = fs.relpath(path, workdir)
    local _, _, extension = fs.parts(path)
    self.extension = extension

    local lines = self
    for line in iter do
        if line:match("[\t]") then
            error("TAB characters are not supported.")
        end

        tinsert(lines, line)
    end
end
-- }

-- [[ MODULE ]]
return M
