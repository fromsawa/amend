--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --

--[===[>>[amend.api.tools] External tools.

FIXME

--]===] --

local M = {}

-- local mt = {
--     __index = function(t, k)
--         -- FIXME
--         return rawget(t, k)
--     end,
--     __newindex = function(t, k, v)
--         -- FIXME
--         rawset(t, k, v)
--     end
-- }
-- setmetatable(M, mt)

local dirsep = package.config:sub(1, 1)
local pathsep = package.config:sub(3, 3)
local modulemark = package.config:sub(5, 5)
local searchpattern = "^([^" .. modulemark .. "]*)"

local paths = string.split(package.path, pathsep)
for _, p in ipairs(paths) do
    if not p:match("init[.]lua$") then
        p = p:match(searchpattern)
        p = p .. "amend" .. dirsep .. "tool"
        if fs.exists(p) then
            message(TRACE[1], "search tool directory %q...", p)

            fs.dodir(p, function(item)
                -- skip root directory
                if item[2] == "tool" then
                    return true
                end

                -- load at least the check method
                local attr = item.attr
                local status, name, module, lib
                if attr.mode == 'file' then
                    name = item[2]:sub(1, -string.len(item[3]) - 1)
                    module = "amend.tool." .. name
                    status, lib = pcall(require, module)
                    if not status then
                        message(ERROR, "error while loading %q:", module)
                        print(lib)
                        os.exit(1)
                    else                        
                        if not lib.check then
                            message(ERROR, "module %q does not have a check function, ignoring...", module)
                        else
                            lib.use = function()
                                return lib 
                            end

                            M[name] = lib
                        end
                    end
                elseif attr.mode == 'directory' then
                    name = item[2]
                    module = "amend.tool." .. name

                    local check
                    status, check = pcall(require, module .. ".check")
                    if not status then
                        message(ERROR, "error while loading %q:", module .. ".check")
                        print(check)
                        os.exit(1)
                    end

                    lib = {}
                    lib.check = check
                    lib.use = function(self)
                        local res = require(module)
                        M[name] = module
                        return res
                    end

                    M[name] = lib
                end
            end, {
                exclude = {".", "..", "init.lua"}
            })
        end
    end
end

-- [[ MODULE ]]
message(TRACE[10], "loaded tool module")
return M
