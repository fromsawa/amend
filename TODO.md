- grep FIXME -R ...
- io.escape: function does not escape some sequences
- builtin/tools.lua: needs implementation
- fs.which: needs a port for Windows
- rdbl: many loose ends to close
- tool.__init: M might need a fence:
    local mt = {
        __index = function(t, k)
            -- ...
            return rawget(t, k)
        end,
        __newindex = function(t, k, v)
            -- ...
            rawset(t, k, v)
        end
    }
    setmetatable(M, mt)
- tool.git: missing implementation
- tool.clang.format: missing implementation
- tool.clang.tidy: missing implementation
- docs/amend: check local md documents
