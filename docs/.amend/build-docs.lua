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
                language = ".lua"
            }
        }
    },
    exclude = {
        patterns = {".vscode", "[.]amend", "share", table.unpack(IGNORE)}
    }
}

local g = docs.core(config)
g:parse("README.md")
-- g:parseall()
io.dump(g)

io.dump(g.files)
