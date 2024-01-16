--[[
    Copyright (C) 2022-2024 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]

local cmd = TOOLS["clang-format"]
if cmd == auto then
    cmd = fs.which("clang-format")
end

return function(...)
    -- FIXME
end
