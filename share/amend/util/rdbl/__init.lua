--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[==========================================================================[>>[amend.api.util.rdbl] ReaDaBLe

    @foreword
    Configuration files suck - yet they are invaluable. They are especially valuable if they are
    _indeed_ human readable and possibly even grep'able (oh yes, the good ol' days of text-only files).
    
    There are a number of good syntaxes, that provide sensible approaches - note, under the
    precondition of structured and hierarchical representation of data. Most of them, however,
    do either not follow the [KISS principle](https://www.urbandictionary.com/define.php?term=KISS%20principle),
    are hardly human readable (without an IDE), or, simply lack the possibility of annotations
    (read: comments).
    
    FIXME

    [XML](FIXME)
    [JSON](FIXME)
    [YAML](https://yaml.org)
    Well, you heard it, YAML to the rescue: yes, but [No thanks!](noyaml.com).::footnote
        The author does recognize the ideas behind YAML. He also wants to express, that alternatives,
        such as XML or JSON, have their merit. 

    RDBL provides a simple sub-set of YAML, is easy to parse and consitent.

    @image<
        @type comic
        @titel "How standards proliferate"
        @subtitle FIXME ...
    >[Standards (xkcd)](https://xkcd.com/927/)

    ::[.version]
    ::[.types]
    ::[.import]
    ::[.export]
--]==========================================================================]

local M = require "amend.util.rdbl.version"
local modimport = M.modimport

-- TODO:
-- - use "array" or "sequence" - or even have array for {} and sequence for -?

modimport "amend.util.rdbl.types"
modimport "amend.util.rdbl.export"
modimport "amend.util.rdbl.import"

-- [[ MODULE ]]
message(TRACE[10], "loaded util.rdbl module")
return M
