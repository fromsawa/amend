% Amend

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

## Overview

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

- [Lua 5.3](https://www.lua.org/download.html)
- [LuaFileSystem](https://github.com/lunarmodules/luafilesystem)

## Quick start

TODO

- project configuration
- components
- libraries
- framework basics

### Project file

To use `amend` within a project the file `.amend/project.lua`:
```.lua
PROJECT = {}
```
must be created. As `amend` updates this configuration file each run automatically
(based on project and operating system features it can detect), the command `amend --update`
must be run. 

### Examples


#### Copyright

TODO


#### Tools

FIXME


#### License

##### UNLICENSE

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>

# API


## Components

"Amend components" can be created anywhere in the source code tree in a sub-folder ".amend".
The first line of such a component starts with a shebang of the format

    #![indicator]<component-name> [<argument-description>] -- <component-description>

where the 'indicator' is

    *           The component is always executed (even if option 'all' is not used).
    _           This defines a "hidden" component (which is only executed as dependency).

If the <indicator> is omitted, the component behaves like a command and is executed only on 
explicit request.

Example:

    #!*check [<arguments>] Check system.
    depends "check-os"
    verbose "Checking system"

    assert(os.command("cmake --version"))

    -- ...
    

### ⎔ `help()`

### ⎔ `shebang()`

### ⎔ `scandir()`

### ⎔ `find()`

### ⎔ `_run()`

### ⎔ `run()`

### ⎔ `depends '<name>'`

 The following global variables are set or determined at startup:

      EXECDIR             Path, where ''amend.lua'' was started.
      ROOTDIR             Project root (where ''.amend/project.lua'' was found).
      PROJECTFILE         Full path to the ''.amend/project.lua'' file.

 To separate source from other files, the variable

      IGNORE              Files or directories generally to ignore.

 is populated (regular expressions) at startup. This list is automatically
 extended if ''amend'' finds the following files, containing wild-card patterns,
 in the ''ROOTDIR'':

      .amend/ignore
      .gitignore

 The project file contains the general configuration variables:

      PROJECT             Project settings.
      CONFIG              Amend settings.
      TOOLS               System tools (see 'amend/tools.lua')
      PATHS               Additional module paths.

 See [amend.api.project] for details.

## Message logging

### ⎔ `VERBOSE`

### ⎔ Verbosity levels

### ⎔ ERROR

### ⎔ WARNING

### ⎔ NOTICE

### ⎔ STATUS

### ⎔ INFO

### ⎔ DEBUG

### ⎔ ERROR

### ⎔ `message()`

### ⎔ `verbosity [{<level>}]`

## Lua extensions


### Classes

    
FIXME

#### ⎔ `class.tag`

#### ⎔ `void`

#### ⎔ `isvoid(t)`

#### ⎔ `isclass(t)`

#### ⎔ `isobject(t)`

#### ⎔ `resolve(...)`

#### ⎔ `isa(obj, ...)`

#### ⎔ `newindex`

#### ⎔ `class "name" { <declaration> }`

#### ⎔ `index(t,k)`

### IO-library extensions

#### ⎔ `io.printf(...)`

#### ⎔ `io.dump(value, options)`

#### ⎔ `io.readall(fname)`

#### ⎔ `io.command(program, ...)`

### OS-library extensions

#### ⎔ `os.command(program, ...)`

### `package`

 @note
 In addition to standard [Lua](https://github.com/lua/lua/blob/master/luaconf.h) conventions,
 here, also the /?/__init.lua/ file is searched.

#### ⎔ `package:addpath(path)`

#### ⎔ `package:pushpath(path)`

#### ⎔ `package:poppath()`

#### ⎔ Remove previously added script search path

### String library extensions

#### ⎔ `string.any(s, tbl, exact)`

#### ⎔ `string.trim(s)`

#### ⎔ `string.title(s)`

#### ⎔ `string.untitle(s)`

#### ⎔ `string:split(sSeparator, nMax, bRegexp)`

#### ⎔ `string.wrap(s, col)`

### Table library extensions

#### ⎔ `table.has(tbl, item)`

#### ⎔ `table.kpairs(tbl)`

#### ⎔ `table.count(tbl)`

#### ⎔ `table.hint(tbl)`

#### ⎔ `table.top(tbl, idx)`

#### ⎔ `table.copy(tbl)`

#### ⎔ `table.merge(t, other)`

#### ⎔ `table.make(...)`

#### ⎔ `table.unique(t)`

#### ⎔ `table.insert_unique(t, v)`

## Projects

FIXME


### Configuration

    Project settings.

    This table contains two required entries:

        NAME            Project name.
        VERSION         Project version.

    as well as 

        USES            List of tools in use.

    Users are free to add additional entries.

### Settings

FIXME

### Tools

FIXME

## External tools

FIXME


### CMake support

--

#### ⎔ `parse_args(options, one_value_keywords, multi_value_keywords, ...)`

#### ⎔ `update(configfile)`

#### ⎔ `check()`

### C support

--

### C++ support

--
--

## CSV-file tools

### ⎔ `csv.load(fname, [opts])`

## Editing

Amend provides several utilities for editing files.

### ⎔ `clear()`

### ⎔ `addln(code, ...)`

### ⎔ `add(code, ...)`

### ⎔ `sed(pattern, replace)`

### ⎔ `write(stream)`

### ⎔ **section**`()`

### ⎔ `parse(path)`

### ⎔ `update()`

### ⎔ `sed(pattern, replace)`

### ⎔ `edit.file(fname)`

## Extensions to LuaFileSystem

### ⎔ `fs.exists(filename)`

### ⎔ `fs.isnewer(file, another)`

### ⎔ `fs.anynewer(file, ...)`

### ⎔ `fs.concat(...)`

### ⎔ `fs.parts(fname)`

### ⎔ `fs.relpath(path, root)`

### ⎔ `fs.readwild(file, tbl)`

### ⎔ `fs.dodir(path, callback, options)`

### ⎔ `fs.pushd(dir)`

### ⎔ `fs.popd()`

### ⎔ `fs.rmkdir(fpath)`

### ⎔ `fs.grep(fname, pattern)`

### ⎔ `fs.filetype(fname)`

### ⎔ `fs.which(executable)`

### ⎔ `fs.touch(...)`

### ⎔ `fs.fullpath(path)`

## ReaDaBLe

Configuration files suck - yet they are invaluable. They are especially valuable if they are
_indeed_ human readable and possibly even grep'able (oh yes, the good ol' days of text-only files).

There are a number of good syntaxes, that provide sensible approaches - note, under the
precondition of structured and hierarchical representation of data. Most of them, however,
do either not follow the [KISS principle](https://www.urbandictionary.com/define.php?term=KISS%20principle),
are hardly human readable (without an IDE), or, simply lack the possibility of annotations
(read: comments).

Well, you heard it, YAML to the rescue: yes, but [No thanks!](noyaml.com).@footnote
    The author does recognize the ideas behind YAML. He also wants to express, that alternatives,
    such as XML or JSON, have their merit. 

RDBL provides a [simple sub-set](https://xkcd.com/927/) of YAML, is easy to parse and consitent.


### Format

The typical structure of an RDBL document is:

    # A comment.
    🗎
    # map
    key: value
    another:
        # sequence
        - a: 1
        - b: 2

#### General

##### Documents

RDBL files contain at least one document. A document starts with

    🗎 document-name

where the 'document-name' is optional. If YAML compatibility is 
required (default in v0.0), the document marker is "---".

##### Hierarchy

Hierarchical order is defined by indentation. The document must always use the
same indentation, consisting of number of spaces (default: 4).

Tab characters (ASCII 0x09) are not allowed.

Elements are organized in sequences (starting with a dash) and (unordered) maps.
::footnote
    Note, that the export of maps will list their keys sorted (unless an implementation
    chooses to support an "ORDER" tag).

Sequences are of the form:

    -
    - key:
    - key: value
    - value

FIXME

Maps are of the format

    key:
    key: value

FIXME

##### Comments

RDBL files may be commented using the number sign or hash (#). Comments may
only appear prior to an entry using identical indentation, otherwise, the
'#' is recognized as a normal character.

##### Keys

RDBL only allows integral or character literals as keys. Other types, such
as floating-point values or boolean types will not be supported, as these are
not generally unambiguous.

##### Value types

###### ''string''

    Character sequences are represented in three forms:

    1. character literals (unquoted, may contain spaces),
    2. quoted, if a string contains or requires escape sequences, and
    3. verbatim (multi-line) strings.

    Example:
            literal: a string literal may contain spaces
            quoted: "This is a \"quoted\" string."
            verbatim: |
                Verbatim strings
                span multiple lines
                and
                    retain
                        their
                    indentation

###### ''integer''

    When using integral types (including binary, octal and hexadecimal representation), care
    has to be taken, that the target system reading the data does support their size.

###### ''float''

    Floating-point values are supported in scientific notation (e.g. "1.0E-3"). Infinity
    is represented as "∞" or "inf". For unrepresentable floats, "NaN" (any case) is used.

###### ''array''

    Arrays may be represented by a comma-separated list of values enclosed in braces.

###### user-types

    Implementations may choose to support other types by supplying a dictionary
    or translation function.

    For example, to support boolean and similar values (here, Lua language), a
    table of the format 

        {
            ["true"] = true,
            ["false"] = false,
            ["on"] = true,
            ["off"] = false,
            ["yes"] = true,
            ["no"] = false
        }

    may be provided to the `import` function.

### API


#### Types

FIXME

##### ⎔ `ORDER`

##### ⎔ `NULL`

##### ⎔ `isnull`

##### ⎔ `isinteger`

##### ⎔ `typeof`

##### ⎔ `escape()`

##### ⎔ `unescape`

##### ⎔ `getkeys()`

##### ⎔ `tovalue()`

##### ⎔ `toliteral()`

##### ⎔ `tokey()`

#### Importing

FIXME

##### ⎔ `isdocument()`

##### ⎔ `splitindent()`

##### ⎔ `unindent()`

##### ⎔ `checkindent()`

##### ⎔ `import`

###### ⎔ `setup`

###### ⎔ `error`

###### ⎔ `assert`

###### ⎔ `next`

###### ⎔ `literal`

###### ⎔ `parse`

###### ⎔ `run`

##### ⎔ Import data

#### Exporting

FIXME

##### ⎔ `export()` 

--
