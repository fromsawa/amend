--[[
    Copyright (C) 2022-2023 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]

local cmd = TOOLS["clang-tidy"]
if cmd == auto then
    cmd = fs.which("clang-tidy")
end

return function(...)
    -- FIXME
end
