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
        patterns = {".vscode", "[.]amend", table.unpack(IGNORE)}
    }
}

docgen = docs.core(config)
docgen:parseall() 
docgen:includeall()
docgen:runmacros()
docgen:resolveall()
io.dump(docgen, { key = 'docgen', file = "/tmp/docgen.lua"})
docgen:write()

if fs.exists("../../fromsawa.github.io/amend") then
    message(NOTICE, "updating fromsawa.github.io/amend/index.html")
    os.command("pandoc -f markdown -t html --standalone --template template.html amend/index.md -o ../../fromsawa.github.io/amend/index.html")
end