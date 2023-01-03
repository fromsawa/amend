--[[
    Copyright (C) 2022-2023 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]

--[[>>[amend.api.project.config] Configuration
    Project settings.

    This table contains two required entries:

        NAME            Project name.
        VERSION         Project version.

    as well as 

        USES            List of tools in use.

    Users are free to add additional entries.
]]
CONFIG.EXTENSIONS = CONFIG.EXTENSIONS or {}
CONFIG.LANG = CONFIG.LANG or {}

