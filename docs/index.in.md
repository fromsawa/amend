# Amend 

Source code revision tool.

## Description

A lot of software is accompanied by additional developer tools to update or check
certain features of the source code. This may, for example, include updating a date,
such as in the copyright notice. In other cases the developer is required to "grep"
through multiple source files to ensure correct order of elements (such as is the
case in the [Lua](https://www.lua.org) [source code](https://github.com/lua), for example
the ''OP'' [order](https://github.com/lua/lua/blob/master/lopcodes.h)) — a task fit for
automation.

The author(s) of ''amend'' have repeatedly reinvented wheels (read utilities)
to prepare software releases for each new software they were working on. The ''amend''
package is (a possibly [futile](https://xkcd.com/927/)) attempt to create a generic
tool for such purposes: yet, the author(s) are using it succesfully in several projects
and, therefore, disclose it to the public.

## Installation

TODO

## Overview

TODO

## Examples

<<[amend.example]

## API

### Globals

<<[amend.api.globals]

### Project configuration

<<[amend.api.project]

### Components

<<[amend.api.components]

### Tools

<<[amend.tools]

### Utilities

<<[amend.api.logging]
<<[amend.api.util]

### [amend.api.lua] Lua extensions

<<[amend.api.lua]

### [amend.api.use] Tools

<<[amend.api.use]

<<[amend.license] 

