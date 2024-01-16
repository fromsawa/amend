--[[
    Copyright (C) 2022-2024 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[[>>[amend.api.util.rdbl.version] Format.

The typical structure of an RDBL document is:

    # A comment.
    🗎
    # map
    key: value
    another:
        # sequence
        - a: 1
        - b: 2

# General

## Documents

RDBL files contain at least one document. A document starts with

    🗎 document-name

where the 'document-name' is optional. If YAML compatibility is 
required (default in v0.0), the document marker is "---".

## Hierarchy

Hierarchical order is defined by indentation. The document must always use the
same indentation, consisting of number of spaces (default: 4).

Tab characters (ASCII 0x09) are not allowed.

Elements are organized in sequences (starting with a dash) and (unordered) maps.
::footnote
    Note, that the export of maps will list their keys sorted (unless an implementation
    chooses to support an "ORDER" tag).

Sequences are of the form:

    -
    - key:
    - key: value
    - value

FIXME

Maps are of the format

    key:
    key: value

FIXME

## Comments

RDBL files may be commented using the number sign or hash (#). Comments may
only appear prior to an entry using identical indentation, otherwise, the
'#' is recognized as a normal character.

## Keys

RDBL only allows integral or character literals as keys. Other types, such
as floating-point values or boolean types will not be supported, as these are
not generally unambiguous.

## Value types

### `string`

Character sequences are represented in three forms:

1. character literals (unquoted, may contain spaces),
2. quoted, if a string contains or requires escape sequences, and
3. verbatim (multi-line) strings.

Example:
        literal: a string literal may contain spaces
        quoted: "This is a \"quoted\" string."
        verbatim: |
            Verbatim strings
            span multiple lines
            and
                retain
                    their
                indentation

### `integer`

When using integral types (including binary, octal and hexadecimal representation), care
has to be taken, that the target system reading the data does support their size.

### `float`

Floating-point values are supported in scientific notation (e.g. "1.0E-3"). Infinity
is represented as "∞" or "inf". For unrepresentable floats, "NaN" (any case) is used.

### `array`

Arrays may be represented by a comma-separated list of values enclosed in braces.

### user-types

Implementations may choose to support other types by supplying a dictionary
or translation function.

For example, to support boolean and similar values (here, Lua language), a
table of the format 

    {
        ["true"] = true,
        ["false"] = false,
        ["on"] = true,
        ["off"] = false,
        ["yes"] = true,
        ["no"] = false
    }

may be provided to the `import` function.

]]
local M = {
    VERSION = "0.0", -- Library AND specification version.
    PATCH = 1, -- Library patch version.
    YAML_COMPAT = false
}

local function modimport(name)
    local ns = require(name)
    for k, v in pairs(ns) do
        M[k] = v
    end
end
M.modimport = modimport

-- [[ MODULE ]]
return M
