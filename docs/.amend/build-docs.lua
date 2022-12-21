#!build-docs -- generate source documentation

message "Generating source documentation..."

local docs = require "amend.docs"

local config = {
    input = {
        directory = ROOTDIR,
        strip = {"share/", "docs/.amend/"},
        tabsize = 4
    },
    output = {
        directory = "docs/amend",
        template = "docs/index.in.md"
    },
    include = {
        patterns = {},
        directories = {"docs/.amend", "docs/.amend/amend", "docs/.amend/amend/docs"},
        files = {
            ["amend"] = {
                extension = ".lua"
            }
        }
    },
    exclude = {
        patterns = {".vscode", "[.]amend", "share", table.unpack(IGNORE)}
    }
}

-- local g = docs.core(config)
-- g:parse("README.md")
-- g:parse("amend/docs/__module.lua")
-- io.dump(g)

local f = docs.file("../README.md")
-- for line,context in f:lines() do
--     io.dump(line)
--     io.dump(context)
-- end
print("#f", #f)
