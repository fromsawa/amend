#!build-docs -- generate source documentation

message "Generating source documentation..."

local docs = require "amend.docs"

local config = {
    version = {1,0},
    input = {
        directory = ROOTDIR,
        strip = { "share/", "docs/.amend/" },
        tabsize = 4
    },
    output = {
        directory = "docs/amend",
        template = ".amend/index.in.md"
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

