--[[
    Copyright (C) 2022-2023 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[[>>[amend.api.lua.os] OS-library extensions.
]]

local stringformat = string.format
local osexecute = os.execute

--- `os.command(program, ...)`
-- Execute a command.
function os.command(program, ...)
    local cmd = stringformat(program,...)
    return osexecute(cmd)
end

-- [[ MODULE ]]
message(TRACE[10], "extended os library")
return os
