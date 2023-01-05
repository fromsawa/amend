--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --

local M = require "amend.docs.__module"

local function substitute(block, begin, from, to)
    for i = begin, #block do
        local text = block[i].text
        if text:sub(1, 4) ~= "    " then
            -- FIXME should "properly check for indentation"
            break
        end

        block[i].text = text:gsub(from, to)
    end
end

local function call(block, i, macro)
    block[i].text = "*Call*\\\n"
    substitute(block, i + 1, "%s+(.*)", ">   %1\\")
end

local function param(block, i, macro)
    block[i].text = "*Parameters*\\\n"
    substitute(block, i + 1, "%s(.*)", "    %1")
end

local function returns(block, i, macro)
    block[i].text = "*Returns* " .. tostring(macro[3]) .. "\\\n"
    substitute(block, i + 1, "%s(.*)", ">   %1")
end

local function note(block, i, macro)
    block[i].text = "___Note___\\\n"
end

local MACROS = {
    call = call,
    param = param,
    returns = returns,
    note = note
}

local function expand(block)
    ::again::
    for i, line in ipairs(block) do
        local macro = line:re("^(.*)%s*@([a-z]+)%s*(.*)$")
        if macro then
            local mname = tostring(macro[2])
            if not MACROS[mname] then
                M.notice(WARNING, line.origin, "macro %q not defined", mname)
            else
                if MACROS[mname](block, i, macro) then
                    goto again
                end
            end
        end
    end
end

-- [[ MODULE ]]
M.expand = expand
return M
