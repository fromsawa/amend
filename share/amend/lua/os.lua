--[[
    Copyright (C) 2022-2024 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[[>>[amend.api.lua.os] `os` library
]]

local stringformat = string.format
local osexecute = os.execute

--- `os.command(program, ...)`
--
-- Execute a command.
--
-- @param
--          program                 The command to execute (as format string).
--          ...                     Format arguments.
function os.command(program, ...)
    local cmd = stringformat(program,...)
    return osexecute(cmd)
end

-- [[ MODULE ]]
message(TRACE[10], "extended os library")
return os
