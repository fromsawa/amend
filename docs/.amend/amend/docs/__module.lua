--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]] --

--[[
    Please note, the complexity of this implementation is an academic exercise 
    used as a test-bed for something else...
]] --

--[[>>[amend.api.docs] Amend's simple documentation generator.

**Module**: `amend.docs` (global ''docs'')

This documentation generator uses a form of annotated markdown to generate
source documentation. 

While markdown documents are used as is, documentation can be generated 
from source-code files. From the latter, only comments are extracted
which are, depending on annotation, transformed into markdown sections
or documents.

The output is optimized for further processing using [pandoc](https://pandoc.org/).

## [.syntax] Syntax

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
    -->>[reference]                 Generate a document (title follows in next fragment).
    -->>[reference] <title>         Generate a document with a title.

### [.annotation] Annotations

    # [reference] Title.

## [.configuration] Configuration

FIXME

## API
]] --
return {
    --- `VERSION`
    --
    -- Document generator version.
    --
    VERSION = {0, 91}
}
