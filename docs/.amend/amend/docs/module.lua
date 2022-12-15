--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --
-- >>[amend.docs] Amend's documentation generator.
--[[-

This documentation generator uses a form of annotated markdown to generate
source documentation. 

While markdown documents are used as is, documentation can be generated 
from source-code files. From the latter, only comments are extracted
which are, depending on annotation, transformed into markdown sections
or documents.

The output is optimized for further processing using [pandoc](https://pandoc.org/).

## Configuration

FIXME

## Syntax

### Source code

Amend-docs scans source files and extracts all comments. These comments
are scanned and only used if certain annotations (e.g. comparable to
other code documenters such as [doxygen](http://www.doxygen.org) are 
present on the first line:

Example:
```.lua
--- A paragraph or section heading.
-- Explanation...
--
```

List:
    --- <heading>.                  Starts a paragraph or section.
    -- >>[reference]                Generate a document (title follows in next part).
    -- >>[reference] <title>        Generate a document with a title.

### Annotations

#### Documents

For a source-code file to be considered, the first annotation must be

    -- >>[reference] title          Generate a document with a title.

where the ''title'', if not provided, will be supplemented from the next part.



]] --
-- >>[amend.docs.api] 
return {
    --- Document generator version.
    -- 
    VERSION = {0, 0}
}
