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

local function check_ref(ref)
    local keys = strsplit(ref, ".")

    for _, k in ipairs(keys) do
        if not k:match("[_%l][_%l%d]*") then
            return false
        end
    end

    return true
end

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
        elseif fragment.tag == 'text' then
            -- untouched
        end

        i = i + 1
    end

    -- check
    if #data == 0 then
        return
    end

    if data.tag == 'source' and not (data[1].tag == 'document') then
        notice(WARNING, data[1][1], "file is missing a document reference")
        message(NOTICE, "ignoring %q", data.file)
        return
    end

    message(STATUS, "parsing %q", data.file)

    -- 2. tokenize
    if data.tag == 'file' then
        -- FIXME
    elseif data.tag == 'source' then
        local doc

        for _, fragment in ipairs(data) do
            if fragment.tag == 'document' then
                local line = fragment[1].text

                local ref, title = line:match(">>[[]([^]]*)[%s]*(.*)[%s]*$")
                if not check_ref(ref) then
                    notice(ERROR, tmake(fragment[1], {
                        column = fragment[1].column + 4
                    }), "invalid reference (dot separated list of lower-case identifiers)")
                end

                doc = find_or_create(db, ref)
                if strlen(title) > 0 then
                    -- FIXME
                end
            else
                -- FIXME
            end

            -- io.dump(fragment, {
            --     key = 'fragment'
            -- })
            -- os.exit()
        end

        -- io.dump(data, {
        --     key = 'data'
        -- })
        -- os.exit()
    end
end

-- [[ MODULE ]]
M.parse = parse
return M
