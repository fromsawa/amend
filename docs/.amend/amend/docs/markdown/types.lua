--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] local M = require "amend.docs.markdown.__module"

local docs = require "amend.docs.__module"

local text = class(M) "text" {
    __inherit = {docs.node},
    __public = {
        tag = 'text',
        content = {},
        context = void
    }
}

local paragraph = class(M) "paragraph" {
    __inherit = {docs.node},
    __public = {
        tag = 'paragraph',
        substitutions = {},
        context = void
    }
}

local section = class(M) "section" {
    __inherit = {docs.node},
    __public = {
        tag = 'section',
        title = void,
        level = void,
        attributes = void,
        reference = void
    }
}

-- [[ MODULE ]]
return M
