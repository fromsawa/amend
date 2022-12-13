--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]

--[[>>[amend.api.logging] Message logging
]]

local tremove = table.remove
local tunpack = table.unpack
local sformat = string.format
local printf = io.printf

--- #+ `VERBOSE`
-- Default verbosity level.
-- 
VERBOSE = VERBOSE or 2

--- #+ Verbosity levels.
--- ##+ ERROR
ERROR = {-2}
--- ##+ WARNING
WARNING = {-1}
--- ##+ NOTICE
NOTICE = {0}
--- ##+ STATUS
STATUS = {1}
--- ##+ INFO
INFO = {2}
--- ##+ DEBUG
DEBUG = {3}
--- ##+ ERROR
TRACE = {4, 5, 6, 7, 8, 9, 10, 11, 12, 13}

local known = {
    'error',
    'warning',
    'notice',
    'info',
    'status',
    'debug',
    'trace',
    error = ERROR[1],
    warning = WARNING[1],
    notice = NOTICE[1],
    status = STATUS[1],
    info = INFO[1],
    debug = DEBUG[1],
    trace = TRACE[#TRACE]
}

-- >> #+ `message [{<level>}] "<text>"`
-- >> #+ `message(<level>|<level-name>, "<text>", ...)`
-- Emit an informational message.
--
-- ::args
-- FIXME
--
function message(...)
    local args = {...}
    local level = {0} -- NOTICE

    if type(args[1]) == "table" then
        while type(t) == 'table' do
            t = table.unpack(t);
        end

        level = tremove(args, 1)

        if #args == 0 then
            -- shell-style invocation
            return function(msg)
                message(level, msg)
            end
        end
    elseif type(args[1]) == "number" then
        level = {tremove(args, 1)}
    end

    if level[1] <= VERBOSE then
        local prefix

        if level[1] >= TRACE[1] then
            local dbg = debug.getinfo(2)

            local _, dfile, _ = fs.parts(dbg.short_src)
            prefix = sformat("[%s:%d] ", dfile, dbg.currentline)
        end

        if prefix then
            printf(prefix)
        end

        -- FIXME add "[<level>]" to output
        print(sformat(tunpack(args)))
    end
end
