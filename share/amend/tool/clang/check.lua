--[[
    Copyright (C) 2022-2024 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] 

local function clang_format()
    local res = fs.exists(fs.concat(ROOTDIR, ".clang-format"))

    if res then
        if not TOOLS["clang-format"] then
            local exe = fs.which("clang-format")
            if not exe then
                message(WARNING, "clang-format executable could not be found")
                return false
            end

            TOOLS["clang-format"] = TOOLS["clang-format"] or auto
        end
    end

    return res
end

local function clang_tidy()
    local res = fs.exists(fs.concat(ROOTDIR, ".clang-tidy"))

    if res then
        if not TOOLS["clang-tidy"] then
            local exe = fs.which("clang-tidy")
            if not exe then
                message(WARNING, "clang-tidy executable could not be found")
                return false
            end

            TOOLS["clang-tidy"] = TOOLS["clang-tidy"] or auto
        end
    end

    return res
end

return function()
    local res = false
    res = clang_format() or res
    res = clang_tidy() or res
    return res
end
