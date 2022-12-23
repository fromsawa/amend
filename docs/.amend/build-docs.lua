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

docgen = docs.core(config) -- FIXME needs to be global (see markdown/document.lua)
docgen:parseall() 
docgen:gentree()
-- io.dump(docgen)

for k,_ in pairs(docgen.files) do
    print(k)
end
