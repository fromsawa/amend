--[[
    Copyright (C) 2022-2023 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] 

--[[>>[amend.api.logging] Message logging
]] 

local tremove = table.remove
local tunpack = table.unpack
local sformat = string.format
local iowrite = io.write
local printf = function(fmt, ...) 
    iowrite(sformat(fmt, ...))
end

---  `VERBOSE`
-- Default verbosity level.
-- 
VERBOSE = VERBOSE or 2

---  Verbosity levels.
---  ERROR
ERROR = {-2}
---  WARNING
WARNING = {-1}
---  NOTICE
NOTICE = {0}
---  STATUS
STATUS = {1}
---  INFO
INFO = {2}
---  DEBUG
DEBUG = {3}
---  ERROR
TRACE = {4, 5, 6, 7, 8, 9, 10, 11, 12, 13}

--- `message()`
-- @call
--      `message [{<level>}] "<text>"`
--      `message(<level>|<level-name>, "<text>", ...)`
--
-- Emit an informational message.
--
-- @param
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

            local dfile = dbg.short_src:match(".*(amend[/\\].*)$") 
            dfile = dfile or  dbg.short_src
            prefix = sformat("[%s:%d] ", dfile, dbg.currentline)
        else
            local prefs = {
                [ERROR[1]] = "[ERROR] ",
                [WARNING[1]] = "[WARNING] ",
                [NOTICE[1]] = "[NOTICE] ",
                [STATUS[1]] = "[STATUS] ",
                [DEBUG[1]] = "[DEBUG] ",
            }
            
            prefix = prefs[level[1]]
        end

        if prefix then
            printf(prefix)
        end

        -- FIXME add "[<level>]" to output
        print(sformat(tunpack(args)))
    end
end

--- `verbosity [{<level>}]`
--
-- Set verbose level.
--
function verbosity(level)
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

    -- help
    if level == "help" then
        print "Verbosity levels:"
        for _, k in ipairs(known) do
            print('    ' .. k, known[k])
        end
        print "or, alternatively, the respective value."

        os.exit()
    end

    -- unpack tables
    while type(t) == 'table' do
        t = table.unpack(t);
    end

    -- assign verbosity level
    VERBOSE = tonumber(level) or known[level]
    if not VERBOSE then
        print("Verbosity level '" .. tostring(level) .. "' is not know.")
        print("Use 'help' for a list.")
        os.exit(1)
    end

    message(DEBUG, "verbosity set to: %d", VERBOSE)
    return VERBOSE
end

VERBOSE = verbosity(VERBOSE)
