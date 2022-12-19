--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] local M = require 'amend.docs.__module'

local tinsert = table.insert
local tremove = table.remove
local tmake = table.make
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
local function parse(db, data)
    message(TRACE[9], "parse(%q)", data.file)

    local notice = M.notice
    local tokenize = M.tokenize

    -- parse fragments
    -- 1: rank fragment, toss unusable
    local i = 1
    while i <= #data do
        local fragment = data[i]

        local function group_begin()
            if #fragment > 1 then
                tinsert(data, i + 1, tmake(fragment[#fragment], {
                    tag = "group:begin"
                }))

                fragment[#fragment - 1] = nil
                i = i + 1
            else
                fragment.tag = "group:begin"
            end
        end

        local function remove_empty_leading()
            while (#fragment > 0) and fragment[1].text:match("^[%s]*$") do
                tremove(fragment, 1)
            end
        end

        local function remove_empty_trailing()
            while (#fragment > 0) and fragment[#fragment].text:match("^[%s]*$") do
                tremove(fragment, #fragment)
            end
        end

        -- remove leading/trailing empty lines
        remove_empty_leading()
        remove_empty_trailing()

        -- handle fragment by tag
        if fragment.tag == 'fragment' then
            -- check first line
            local first = fragment[1].text
            local last = fragment[#fragment].text

            if first then
                if first:match("^%-") then
                    fragment.tag = "paragraph"

                    if last:match("^[%s]*{[%s]*$") then
                        group_begin()
                        remove_empty_trailing()
                    end
                elseif first:match("^>>[[]") then
                    fragment.tag = "document"

                    if last:match("^[%s]*{[%s]*$") then
                        group_begin()
                        remove_empty_trailing()
                    end
                elseif first:match("^[%s]*{[%s]*$") then
                    fragment.tag = "group:begin"
                elseif first:match("^[%s]*}[%s]*$") then
                    fragment.tag = "group:end"
                else
                    first = nil
                end
            end

            if not first then
                tremove(data, i)
                i = i - 1
            end
        elseif fragment.tag == 'file' then
            -- untouched
        end

        i = i + 1
    end

    -- check
    if data[1] then
        if data[1].tag == 'file' then
            -- untouched
        elseif not (data[1].tag == 'document') then
            notice(WARNING, data[1][1], "file is missing a document reference")
            message(NOTICE, "ignoring %q", data.file)
            return
        end
    end

    if #data == 0 then
        return
    end

    message(STATUS, "parsing %q", data.file)

    -- 2. tokenize
    tokenize(db, data)
end

-- [[ MODULE ]]
M.parse = parse
return M
