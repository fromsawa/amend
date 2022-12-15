--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] local M = require 'amend.docs.module'

local tinsert = table.insert
local tremove = table.remove
local strsplit = string.split
local strtrim = string.trim
local strlen = string.len

local function tokenize_line(res, text, context)
    local bpos,epos

    -- reference/link
    bpos, epos = text:find("[[][^][]*[]]")
    if bpos then
        tokenize_line(res, text:sub(1, bpos - 1), context)

        local reference = {
            tag = "ref",
            link = text:sub(bpos + 1, epos - 1)
        }
        tinsert(res, reference)

        if text:sub(epos + 1, epos + 1) == '(' then
            bpos, epos = text:find("[(][^)]*[)]", epos + 1)
            reference.tag = "link"
            reference.text = reference.link
            reference.link = text:sub(bpos + 1, epos - 1)
        end

        tokenize_line(res, text:sub(epos + 1), context)
        return
    end
    
    -- "pure" text
    if strlen(text) > 0 then
        tinsert(res, {
            tag = "text",
            text = text
        })
    end
end

local function tokenize(piece, context)
    -- remove leading/trailing empty lines
    while (#piece > 0) and strlen(piece[1][1]) == 0 do
        tremove(piece, 1)
    end

    while (#piece > 0) and strlen(piece[#piece][1]) == 0 do
        tremove(piece)
    end

    -- rest can be tokenized
    local res = {}

    for i, line in ipairs(piece) do
        tokenize_line(res, line[1], {source = context.source, line = line[2], column = line[3]})
        
        if i < #line then
            tinsert(res, { tag = 'newline' })    
        end
    end

    if #res == 0 then
        res = nil
    end
    return res
end

-- [[ MODULE ]]
M.tokenize = tokenize
return M
