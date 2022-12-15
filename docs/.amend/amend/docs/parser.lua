--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] local M = require 'amend.docs.module'

local tinsert = table.insert
local tremove = table.remove
local strsplit = string.split
local strtrim = string.trim
local strlen = string.len

local function find_or_create(db, ref)
    local keys = strsplit(ref, ".")
    local top = db.structure
    local node = {}

    for _, k in ipairs(keys) do
        top[k] = top[k] or {}
        top = top[k]

        tinsert(node, top)
    end

    return node
end

--- Parse files into document structure.
--
local function parse(db, file)
    local raise = M.raise

    if file.type == 'document' then
        -- documents are left alone...
        return
    elseif file.type == 'source' then
        -- local top = db.structure
        -- local node = {}

        -- for _, piece in ipairs(file) do
        --     if piece.tag == 'comment' then
        --         -- a comment block must start with a recognizable first line
        --         local heading
        --         local first = piece[1][1]
        --         local last = piece[#piece][1]
        --         local context = {
        --             source = file.file,
        --             line = piece[1][2],
        --             column = piece[1][3]
        --         }
        --         if first:match("^>>") then
        --             -- [ document ]
        --             local ref, rest = first:match("^>>[[]([^]]*)[]][ \t]*(.*)[ \t]*$")
        --             if not ref then
        --                 raise(context, "Invalid document declaration, expected '>>[<ref>]'.")
        --             end

        --             node = find_or_create(db, ref)

        --             heading = rest
        --             tremove(piece, 1)
        --         elseif first:match("^-") then
        --             -- [ paragraph ]
        --             if #node == 0 then
        --                 raise(context, "No document declared (missing '>>[<ref>]' at start of file).")
        --             end

        --             heading = first:match("^-[ \t]*(.*)[ \t]*")
        --             tremove(piece, 1)
        --         elseif first:match("^[}]") then
        --             -- [ sub-paragraph end ]
        --             if #node == 0 then
        --                 raise(context, "Unbalanced sub-paragraph ('--}').")
        --             end

        --             -- done with sub-group
        --             tremove(node)
        --         else
        --             -- no documentation
        --         end

        --         if last:match("^[{]") then
        --             -- [ sub-paragraph begin ]
        --             if #node == 0 then
        --                 raise(context, "A sub-paragraph cannot start here (maybe missing document).")
        --             end

        --             -- add sub group
        --             local current = node[#node]
        --             current[#current + 1] = {}

        --             tinsert(node, current[#current])
        --             tremove(piece)
        --         end

        --         -- tokenize rest
        --         if heading then
        --             if #node == 0 then
        --                 raise(context, "Cannot add text here (maybe missing document).")
        --             end

        --             local toks = M.tokenize(piece, context)
        --             tinsert(node[#node], toks)

        --             heading = strtrim(heading)
        --             if strlen(heading) > 0 then
        --                 if toks then
        --                     toks.heading = heading
        --                 else
        --                     node[#node].heading = heading
        --                 end
        --             end
        --         end
        --     end
        -- end

        -- -- cleanup source, not needed anymore
        -- while #file > 0 do
        --     tremove(file)
        -- end
    end
end

-- [[ MODULE ]]
M.parse = parse
return M
