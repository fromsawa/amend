--[[
    Copyright (C) 2022-2024 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]

--[[>>[amend.api.project.config] Configuration

The CONFIG table has the following entries:

## EXTENSIONS

This table maps language to file extensions. Example:
```.lua
EXTENSIONS = {
    C = {
        ".h",
        ".c",
    },
    CXX = {
        ".hh",
        ".hpp",
        ".hxx",
        ".cc",
        ".cpp",
        ".cxx",
    }
}
```

## LANG

Here, additional processing can be defined, for example:
```.lua
LANG = {
    C = {
        POST = {
            TIDY = "clang-format",
        },
        PRE = {},
    },
    CXX = {
        POST = {
            TIDY = "clang-format",
        },
        PRE = {},
    },
}
```

]]
CONFIG.EXTENSIONS = CONFIG.EXTENSIONS or {}
CONFIG.LANG = CONFIG.LANG or {}

