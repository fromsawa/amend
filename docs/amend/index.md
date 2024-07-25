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

A versatile framework is provided for developing 'components'. This includes,
for example, the possibility to update code regions in several files (e.g., 
source files may be updated from an enumeration in a header file).

### Examples


#### Copyright{#amend.example.copyright}

```.lua
local symbol = "(C)" -- copyright symbol
local pattern = {"Yogev Sawa"} -- author pattern(s)
local year = tonumber(OPTIONS[1] or os.date("%Y")) -- current year

function fix_copyright(fname)
    -- read file
    local txt = io.readall(fname)
    if not txt then
        return
    end

    -- find and check copyright
    local bpos, epos, copyright, sym, year_from, year_to, author =
        txt:find("(Copyright)[ ]+([^0-9]*)[ ]+([0-9]+)[ ]*[%-]-[ ]*([0-9]*)[ ]+([^\n]+)")

    -- edit files (if applicable)
    if table.has(pattern, author) then
        year_from = tonumber(year_from)
        year_to = tonumber(year_to)

        if ((year_to or year_from) ~= year) or (sym ~= symbol) then
            local years = string.format("%d", year)
            if year_from ~= year then
                years = string.format("%d-%d", year_from, year)
            end
            message(STATUS, "    updating %s", fname)

            local before, after = txt:sub(1, bpos - 1), txt:sub(epos + 1, -1)
            local newcopyright = string.format("%s %s %s %s", 
                                            copyright, symbol, years, author)

            f = assert(io.open(fname, "w"))
            f:write(before, newcopyright, after)
            f:close()
        end
    end
end

fs.dodir(
    ".",
    function(item)
        fix_copyright(item[0])
    end,
    {
        exclude = IGNORE,
        extension = {".lua", ".cmake", ".md"},
        include = {},
        recurse = true
    }
)
```

## API


### Components{#amend.api.components}

"Amend components" can be created anywhere in the source code tree in a sub-folder ".amend".
The first line of such a component starts with a shebang of the format

    #![indicator]<component-name> [<argument-description>] -- <component-description>

where the 'indicator' is

    *           The component is always executed (even if option 'all' is not used).
    _           This defines a "hidden" component (which is only executed as dependency).

If the \<indicator\> is omitted, the component behaves like a command and is executed only on 
explicit request.

Example:

    #!*check [<arguments>] Check system.
    depends "check-os"
    verbose "Checking system"

    assert(os.command("cmake --version"))

    -- ...

#### `component.help()`

Print components help.

#### `component.find()`

Find all components in the project tree.

#### `component.run(name)`

Run a "component".

#### `depends '<name>'`

Include a dependecy.

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

See [Projects](#amend.api.project) for details.

### Logging{#amend.api.logging}

#### `VERBOSE`

The global verbosity level (default: INFO).

#### Verbosity levels

     ERROR
     WARNING
     NOTICE
     STATUS
     INFO
     DEBUG

#### `message(level, fmt, ...)`

Emit an informational message.

*Call*\

>   `message "<text>"`\
>   `message {<level>} "<text>"`\
>   `message(<level>|<level-name>, fmt, ...)`\

*Parameters*\

        level           The verbosity level (see above).
        fmt,...         Format string and arguments.

#### `verbosity(level)`

Set verbosity level.

*Call*\

>   `verbosity "<level>"`\
>   `verbosity {<level>}`\
>   `verbosity(level)`\

### Lua extensions{#amend.api.lua}


#### Classes{#amend.api.lua.class}

Here we provide a simple class implementation supporting inheritance.

##### `class.tag`

This class tag serves two purposes, first to mark a table as 'class'
and second, provides the meta-method `__call` for class instatiation.

##### `void`

A place-holder (for `__public` fields).

##### `isvoid(t)`

Check if `t` is `void`.

##### `isclass(t)`

Check if `t` is a `class`.

##### `isobject(t)`{#isobject}

Check if `t` is an object.

##### `isa(obj, ...)`

*Call*\

>   `isa(obj, T)`\

Check if `obj` is of type `T`. Here, `T` may also be
a string as it would be returned by `type()` or `math.type()`.

*Call*\

>   `isa(obj, {T})`\

Check if `obj` is or is derived from type `T`. This requires
`obj` to be an object (see [isobject](#isobject)).

##### `class.index(t,k)`

Retrieve index `k` from table `t` in the same way, standard `__index` does it,
however, using 'rawget' internally.

##### `class.newindex`

Standard `__newindex` meta-method for classes.

This disallows unknown dictionary keys while integer keys (ie. array keys)
are allowed.

##### `class "name" { <declaration> }`

Declare a class.

*Call*\

>   `class "name" { <declaration> }`\
>   `class(t) "name" { <declaration> }`\

*Parameters*\

        t               Destination table (default: `_G`).
        name            Class name (dot-separated identifiers).

*Declaration*\

     {
         __inherit = { <inheritance-list> },
         __public = {
             <variables>
         },
         <methods>
     }

#### ``io`` library{#amend.api.lua.io}

##### `io.printf(...)`

Equivalent to C's ''printf''

##### `io.dump(value, options)`

Dump `value`.

*Parameters*\

        value                   Value to stream to output.
        options [optional]      Display options.

This function dumps a `value` to an output stream.

The ''options'' is a table, that may contain the following fields:

     stream          Output stream (default: io.stdout).
     file            Output file name.
     indent          Indentation string.
     level           Indentation level.
     key             Table key.
     prefix          Prefix for output (usually only for adding a "return" statement).
     quoted          Always output keys in the ["quoted"] format (default: false)
     indexes         Index sorting ("first" or "last"; default: last for objects, first otherwise)

##### `io.readall(fname)`

Read file.

*Parameters*\

        fname           The file name.

*Returns* text, error\


##### `io.sed(fname, pattern, replacement, options)`

Replace file contents using a pattern.

*Parameters*\

        fname           The file name.
        pattern         A 'gsub' pattern.
        replacement     Replacement string.
        options         Currently not supported.

##### `io.command(program, ...)`

Execute command and read output.

*Parameters*\

            program                 The command to execute (as format string).
            ...                     Format arguments.

*Returns* output,error\


#### `os` library{#amend.api.lua.os}

##### `os.command(program, ...)`

Execute a command.

*Parameters*\

            program                 The command to execute (as format string).
            ...                     Format arguments.

#### `package` library{#amend.api.lua.package}

___Note___\

In addition to standard [Lua](https://github.com/lua/lua/blob/master/luaconf.h) 
conventions, here, also the `?/__init.lua` file is searched.

##### `package:addpath(path)`

Add search directory to script search path.

##### `package:pushpath(path)`

Temporarily add a script search path.

##### `package:poppath()`

Remove previously added script search path.

#### Version number library{#amend.api.lua.version}

##### `version`

A broken down version number which consist of a major, minor and a patch version. 

##### `version(t)`

*Parameters*\

        t       Version definition (table of numbers or string).

A version number is expected to be sequence of three numbers, the
major, minor and patch version. Additional version specifications
may be provided but are ignored.

In string notation, the version is 

     "<major>[.<minor>[.<patch>[<punctuation><rest>]]]"

where '[]' denotes optional parts.

##### `version:tostring()`

Convert version to a string.

##### `version:value()`

Calculate a comparable number.

#### `string` library{#amend.api.lua.string}

##### `string.any(s, tbl, exact)`

Match elements from a table.

*Parameters*\

        s                   The string.
        tbl                 Table with regex-patterns.
        exact [optional]    If ''true'', the matched part must be identical to the full string.

*Returns* \

>       Matched string, otherwise ''nil''.

##### `string.trim(s)`

Trim string.

##### `string.title(s)`

Make string "titlecase".

##### `string.untitle(s)`

Undo "titlecase".

##### `string:split(sSeparator, nMax, bRegexp)`

String split.
See http://lua-users.org/wiki/SplitJoin

##### `string.wrap(s, col)`

Wrap string (each line is detected as a paragraph) to specified column-width.

#### `table` library{#amend.api.lua.table}

##### `table.has(tbl, item)`

Check if array-part of a table has an element.

*Parameters*\

        tbl         The table to check.
        item        The item.

##### `table.keys(tbl)`

Get list of keys in a table.

##### `table.kpairs(tbl)`

Key-only table iterator.

This function ignores integer-valued keys.

##### `table.count(tbl)`

Count all keys in a table.

##### `table.top(tbl, idx)`

Get array items from top

##### `table.copy(tbl)`

Create a table copy.

##### `table.merge(t, other)`

Merge another table into `t`.

##### `table.make(...)`

Create a new table from many.

##### `table.unique(t)`

Make array elements unique.

##### `table.insert_unique(t, v)`

Add a unique value.

### Projects{#amend.api.project}


#### Settings{#amend.api.project.settings}

The `PROJECT` settings table contains two required entries:

    NAME            Project name.
    VERSION         Project version ({major, minor[, patch[, tweak]]}).

as well as 

    USES            List of tools in use.

Users are free to add additional entries.

#### Configuration{#amend.api.project.config}

The CONFIG table has the following entries:

##### EXTENSIONS

This table maps language to file extensions. Example:
```.lua
EXTENSIONS = {
    C = {
        ".h",
        ".c",
    },
    CXX = {
        ".hh",
        ".hpp",
        ".hxx",
        ".cc",
        ".cpp",
        ".cxx",
    }
}
```

##### LANG

Here, additional processing can be defined, for example:
```.lua
LANG = {
    C = {
        POST = {
            TIDY = "clang-format",
        },
        PRE = {},
    },
    CXX = {
        POST = {
            TIDY = "clang-format",
        },
        PRE = {},
    },
}
```

#### Tools{#amend.api.project.tools}

The `TOOLS` table associates an external command with a "tool". For example:

```.lua
TOOLS = {
    ["git"] = auto,
    ["clang"] = "/usr/bin/clang-15"
}
```

will tell `amend` to automatically detect the git command and version, while
clang will explicitely use major version 15.

See the [external tools](#amend.api.use) chapter for further information.

### External tools{#amend.api.use}


#### CMake support{#amend.api.use.cmake}

##### `update(configfile)`

Update PROJECT configuration from the 'CMakeLists.txt' file.

##### `check()`

Check if project uses CMake and update PROJECT settings.

#### Git support{#amend.api.use.git}

##### `check()`

Check if project uses git and update PROJECT settings.

#### CLang support{#amend.api.use.clang}

#### C support{#amend.api.use.c}

TBD

#### CXX support{#amend.api.use.cxx}

TBD

### Utilities{#amend.api.util}


#### Extensions to LuaFileSystem{#amend.api.util.filesystem}

##### `fs.exists(filename)`

Check if file exists.

*Parameters*\

        filename        Path or file-name to check.

*Returns* \

>       ''true'' if file or path exists, ''false'' otherwise.

##### `fs.isnewer(file, another)`

Check if a ''file'' is newer than ''another''.

*Returns* \

>       ''nil'' if `file` does not exist,
>       ''true'' if `file` is newer or `another` does not exist,
>       ''false'' otherwise.

##### `fs.anynewer(file, ...)`

Check if any other file is newer than `file`.

##### `fs.concat(...)`

Concatenate path elements.

*Parameters*\

        ...             List of path elements.
*Returns* \

>       Concatenated path elements using builtin directory seperator.

##### `fs.parts(fname)`

Get parts of a file name (path, file and extension).

*Parameters*\

        fname           The file- or path-name.
*Returns* \<path\>,\<file-name\>,\<extension\>\


##### `fs.relpath(path, root)`

Get relative path with respect to a "root".

*Parameters*\

        path            The 'path' to split.
        root [optional] The root path.
*Returns* \<relative-path\>\


##### `fs.readwild(file, tbl)`

Read a wildcard pattern file.

*Parameters*\

        file                The file name (containing wildcard patterns and comments).
        tbl [optional]      Existing table (with regex patterns).

##### `fs.dodir(path, callback, options)`

Execute a function for each directory element possibly recursively.

*Parameters*\

        path                    The path to iterate over.
        callback                Callback function for elements (must return true for recursion).
        options [optional]      Options.

This function executes the `callback` for each element in the alpha-numerically
sorted directory list. Arguments passed to the callback are:

     [0]     Full path to file.
     [1]     The directory part.
     [2]     The file name part.
     [3]     The file extension.
     attr    The attribute table as returned by `symlinkattributes`.
     options The options table (from the arguments).

The callback may return a boolean value overriding option ''recurse''.

Options:

     exclude             List of regex-patterns of files or directories to ignore (default: {'[.]', '[.][.]'}).
     include             List of regex-patterns of files or directories to include (overrides 'exclude').
     directories         Additional directories to search.
     extension           Only report files or directories matching list of given extensions.
     mode                File type (`mode` field of `attributes()` function).
     follow              Follow symbolic links (default: false)
     recurse             Enable directory recursion (default: false).
     depth               Directory depth (default: 0)

##### `fs.pushd(dir)`

"Push" directory.

Equivalent of shell command ''pushd''.

##### `fs.popd()`

"Pop" directory.

Equivalent of shell command ''popd''.

##### `fs.rmkdir(fpath)`

Recursively create directory.

*Parameters*\

        fpath       The directory-path to create.
*Returns* \<status\>[, \<error-message\>]\


##### `fs.grep(fname, pattern)`

Grep-like matching

##### `fs.filetype(fname)`

Get file type (from extension).

##### `fs.which(executable)`

Get full path to an executable.

##### `fs.touch(...)`

Touch all files, ensuring same access and modification time.

*Parameters*\

        files...    File names to touch.
        [options]   Options (last argument).

**Options**:
     ''atime''   The file access time (current time if omitted).
     ''mtime''   The file modification time (current time if omitted).

##### `fs.fullpath(path)`

Retrieve full path of a possibly relative `path`.

#### Editing{#amend.api.util.edit}

Amend provides several utilities for editing files.

##### `clear()`

Clear contents.

##### `add(code, ...)`

Add code to current line.

##### `addln(code, ...)`

*Call*\

>   addln()\
>   addln(<table>)\
>   addln(<plain string>)\
>   addln(<format>, <format arguments...>)\

Add a code line with formatting or array of lines.

##### `sed(pattern, replace)`

In-place sed.

##### `write(stream)`

Write section to a stream.

##### **section**`()`

Constructor.

##### `parse(path)`

Parse file (into sections)

##### `update()`

Update file.

##### `sed(pattern, replace)`

In-place sed.

##### `edit.file{fname, ...}`

Edit a single or multiple files.

Example:
Assuming we have a file 'myfile.hh' with the following 
```.hh
constexpr const char *version_s = "1.2.3";
constexpr int version[] = {
    //@AMEND{myfile:version}
    //@END{myfile:version}
}
```
then we can use the following script snippet to automatically
update the contents:
```.lua
local version = {0,1,2,3}
local code = edit.file{'myfile.hh'}
code:sed('(constexpr const char [*]version_s) = .*;', '%1 = %q', table.concat(version, "."))
code['myfile:version']:clear()
for _, v in ipairs(version) do
    code['myfile:version']:addln("%d,", v)
end
code:update()
```

#### CSV-file tools{#amend.api.util.csv}

##### `csv.load(fname, opts)`

 Read a CSV file.

*Parameters*\

        fname               File name.
        opts [optional]     Options.

Options:

    {
        comment = '<pattern>',
        separator = 'separator',
        columns = { <column-names-list> },   
        filter = <item-filter-function>
    }

#### ReaDaBLe{#amend.api.util.rdbl}

Configuration files suck - yet they are invaluable. They are especially valuable if they are
_indeed_ human readable and possibly even grep'able (oh yes, the good ol' days of text-only files).

There are a number of good syntaxes, that provide sensible approaches - note, under the
precondition of structured and hierarchical representation of data. Most of them, however,
do either not follow the [KISS principle](https://www.urbandictionary.com/define.php?term=KISS%20principle),
are hardly human readable (without an IDE), or, simply lack the possibility of annotations
(read: comments).

Well, you heard it, YAML to the rescue: yes, but [No thanks!](https://noyaml.com)
(the author does recognize the ideas behind YAML; he also wants to express, 
that alternatives, such as XML or JSON, have their merit). 

RDBL provides a [simple sub-set](https://xkcd.com/927/) of YAML, is easy to parse and consitent.


##### Format{#amend.api.util.rdbl.version}

The typical structure of an RDBL document is:

    # A comment.
    🗎
    # map
    key: value
    another:
        # sequence
        - a: 1
        - b: 2

##### General

###### Documents

RDBL files contain at least one document. A document starts with

    🗎 document-name

where the 'document-name' is optional. If YAML compatibility is 
required (default in v0.0), the document marker is "---".

###### Hierarchy

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

Maps are of the format

    key:
    key: value

###### Comments

RDBL files may be commented using the number sign or hash (#). Comments may
only appear prior to an entry using identical indentation, otherwise, the
'#' is recognized as a normal character.

###### Keys

RDBL only allows integral or character literals as keys. Other types, such
as floating-point values or boolean types will not be supported, as these are
not generally unambiguous.

###### Value types

####### `string`

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

####### `integer`

When using integral types (including binary, octal and hexadecimal representation), care
has to be taken, that the target system reading the data does support their size.

####### `float`

Floating-point values are supported in scientific notation (e.g. "1.0E-3"). Infinity
is represented as "∞" or "inf". For unrepresentable floats, "NaN" (any case) is used.

####### `array`

Arrays may be represented by a comma-separated list of values enclosed in braces.

####### user-types

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

##### API


###### Types{#amend.api.util.rdbl.types}

####### `ORDER`

Element order.

####### `NULL`

Non-destructive ''nil''.

Empty values, are represented as 'null', otherwise, in Lua,
the table entry would be deleted.

####### `isnull`

Check if 'null'.

####### `isinteger`

 Check if value is an integer.

####### `typeof`

Get type of a value.

*Parameters*\

        x       Value to get type of.
        fine    "Fine-grained" type (default: true).
*Returns* typename [, category [, subtype]]\


This function returns the standard return values of Lua's ''type'', but additionally
the strings

     "null"      if ''x'' is a NULL,
     "integer"   if ''x'' is an integral number.

If ''fine'' is ''true'', the returned ''subtype'' is

     "null"      if empty,
     "array"     for arrays containing only tables (then, the ''subtype'' is identified),
     "map"       otherwise.

Note, that tables containing array or sequence elements with additional map entries
(as available in Lua) are not identified.

####### `escape()`

Escape a string.

####### `unescape`

Unescape a string.

####### `getkeys()`

Get sorted list of keys.

*Parameters*\

        t           The table.
*Returns* \

>       Array of keys in `t`.

####### `tovalue()`

Convert literal to a value.

*Parameters*\

        s       Character string.
        [fn]    User-supplied conversion function (optional).

####### `toliteral()`

Convert value to a literal.

*Parameters*\

        x       Lua value.
        [fn]    User-supplied conversion function (optional).

####### `tokey()`

Transform into a key.

*Parameters*\

        x           The value to convert.
*Returns* \

>       FIXME

###### Importing{#amend.api.util.rdbl.import}

FIXME

####### `isdocument()`

Check if start of document.

*Returns* boolean, name\


####### `splitindent()`

Split of indentation

####### `unindent()`

Unindent.

####### `checkindent()`

Check indentation

####### `import`

######## `setup`

Setup importer.

######## `error`

Emit error message.

######## `assert`

Formatted assertion.

######## `next`

Get next line.

*Returns* <level>, "<content>"\


######## `literal`

Get next "literal" line.

*Parameters*\

        n       Spaces count.
*Returns* <content>\

>       literal content, or ''nil'' when end is reached

######## `parse`

Parse elements in current context (ie. indentation level).

*Parameters*\

        level       Current indentation level.
        content     Current line content.

######## `run`

Run the importer.

####### Import data

*Parameters*\

        [opts]  Import options (FIXME).

###### Exporting{#amend.api.util.rdbl.export}

FIXME

####### `export()`

Export a table.

*Parameters*\

        t       The table.
        [opts]  Export options (FIXME).

The provided table `t` has the format (named an unnamed documents may be mixed):

     { { {doc1_elements} }, {doc2_name = {doc2_elements} }, ...}

--
