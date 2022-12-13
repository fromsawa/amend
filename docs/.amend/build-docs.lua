#!build-docs -- generate source documentation
message "Generating source documentation..."

local docs = require "amend.docs"

local config = {
    input = {
        directory = ROOTDIR
    },
    output = {
        directory = "amend",
        template = ".amend/index.in.md",
        reference = "amend"
    },
    include = {
        patterns = {},
        files = {
            ["amend"] = {
                syntax = "lua"
            }
        }
    },
    exclude = {
        patterns = {
            "[.]amend",
            table.unpack(IGNORE)
        }
    }
}

docs.generate(config)
