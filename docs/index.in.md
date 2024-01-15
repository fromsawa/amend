# Amend 

A source code revision tool.

## Description

A lot of software is accompanied by additional developer tools to update or check
certain features of the source code. This may, for example, include updating a date,
such as in the copyright notice. In other cases the developer is required to "grep"
through multiple source files to ensure correct order of elements (such as is the
case in the [Lua](https://www.lua.org) [source code](https://github.com/lua), for example
the `OP` [order](https://github.com/lua/lua/blob/master/lopcodes.h)) — a task fit for
automation.

The author(s) of `amend` have repeatedly reinvented wheels (read utilities)
to prepare software releases for each new software they were working on. The `amend`
package is (a possibly [futile](https://xkcd.com/927/)) attempt to create a generic
tool for such purposes: yet, the author(s) are using it succesfully in several projects
and, therefore, disclose it to the public.

## Installation

The `amend` software is intended to be installed either as a sub-module in an existing
project or on a per-user basis — and, in fact, the authors do not intend to provide 
or encourage packaged versions.

To use `amend` clone the [repository](https://github.com/fromsawa/amend) in your favorite
location. On systems that support the [shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)#:~:text=In%20computing%2C%20a%20shebang%20is,bang%2C%20or%20hash%2Dpling.)
users may add the directory to the `PATH` environment variable or symbolically link the 
`amend` script into an existing `PATH` directory. Alternatively, a batch script must be 
created.

**Required packages**:

- [Lua 5.4](https://www.lua.org/download.html)
- [LuaFileSystem](https://github.com/lunarmodules/luafilesystem)

## Quick start

### Project file

To use `amend` within a project the file `.amend/project.lua`:
```.lua
PROJECT = {}
```
must be created and the command `amend --update` must be run.

This project file may be updated automatically in some circumenstances (such as a new CMake file).

See the [Projects](#amend.api.project) API for further details.

### Components and Libraries

Components (i.e. an executable script) may be created on a per directory basis 
inside a sub-directory `.amend/`. These components are executed within the 
directory (as work directory). Also, the `.amend/`-subdirectory is added as
search path for Lua scripts. See the [copyright updater](#amend.example.copyright) 
as example, and, as well, the [full](#amend.api.components) documentation.

### Framework fundamentals

TODO

### Examples

<<[amend.example]

## API

<<[amend.api]
