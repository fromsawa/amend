#!*version [<version>] -- update version number
message "Updating version..."

local concat = table.concat
local unpack = table.unpack
local sed = io.sed

files = {
    ["amend"] = {'(local version = ")([^"]*)(")', "%1"..concat(PROJECT.VERSION, ".").."%3" },
    ["share/amend/version/__init.lua"] = {'(VERSION = {)([^}]*)(})', "%1"..concat(PROJECT.VERSION, ', ')..'%3'},
    ["docs/.amend/amend/docs/__module.lua"] = {'(VERSION = {)([^}]*)(})', "%1"..concat(PROJECT.VERSION, ', ')..'%3'},
}

for file, pat in pairs(files) do
    sed(file, pat[1], pat[2])
end