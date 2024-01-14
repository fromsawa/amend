#!docs -- generate source documentation

message "Generating source documentation..."

local docs = require "amend.docs"

local config = {
    input = {
        directory = ROOTDIR,
        strip = {"share/"},
        tabsize = 4
    },
    output = {
        directory = "docs/amend",
        template = "docs/index.in.md"
    },
    include = {
        patterns = {},
        directories = {},
        files = {
            ["amend"] = {
                language = ".lua"
            }
        }
    },
    exclude = {
        patterns = {".vscode", "[.]amend", "docs", table.unpack(IGNORE)}
    }
}

local docgen = docs.core(config)
docgen:parseall()
docgen:processall()
docgen:writeall()

if fs.exists("../../fromsawa.github.io/amend") then
    message(NOTICE, "updating fromsawa.github.io/amend/index.html")
    os.command(
        "pandoc -f markdown -t html --standalone --template template.html amend/index.md -o ../../fromsawa.github.io/amend/index.html"
    )
    -- os.command(
    --     "pandoc -f markdown -t gfm amend/index.md -o amend/index.md"
    -- )
end
