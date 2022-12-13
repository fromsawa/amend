--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] local M = require 'amend.docs.module'

local strsplit = string.split

local function find_or_create(db, ref)
    local keys = strsplit(ref, ".")
    local hier = db.hierarchy

    for _, k in ipairs(keys) do
        hier[k] = hier[k] or {}
        hier = hier[k]
    end

    return hier
end


--- Parse files into hierarchy.
--
local function parse(db, node)
    local raise = M.raise

    if node.type == 'document' then
        -- documents are left alone...
        return
    elseif node.type == 'source' then
        local hier

        for _, piece in ipairs(node) do
            if piece.tag == 'comment' then
                -- a comment block must start with a recognizable first line
                local title
                local first = piece[1][1]
                local context = {
                    source = node.file,
                    line = piece[1][2],
                    column = piece[1][3]
                }
                if first:match("^>>") then
                    local ref, rest = first:match("^>>[[]([^]]*)[]][ \t]*(.*)[ \t]*$")
                    if not ref then
                        raise(context, "Invalid association, expected '>>[<ref>]'.")
                    end

                    hier = find_or_create(db, ref)
                    title = rest
                elseif first:match("^-") then
                    if not hier then
                        raise(context, "Documentation not associated (missing '>>[<ref>]' at start of file).")
                    end

                    title = first:match("^-[ \t]*(.*)[ \t]*")
                else
                    -- no documentation
                end

                -- tokenize rest
                if title then
                    print("TITLE", title)
                    -- os.exit()


                    
                end
            end
        end
    end
end

-- [[ MODULE ]]
M.parse = parse
return M
