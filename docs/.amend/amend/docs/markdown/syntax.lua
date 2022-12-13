--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] 

local tinsert = table.insert

return function(node)
    message(STATUS, "extracting %q...", node.file)
    node.type = "document"


    local lineno = 1
    for line in io.lines(node.path) do
        tinsert(node, {line, lineno, 1})
        lineno = lineno + 1
    end
end