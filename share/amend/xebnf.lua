--[[
    Copyright (C) 2022 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
--[[>>[amend.xebnf] 

Extended Backus–Naur form parser with basic Unicode support.

]]
local sfind = string.find
local sformat = string.format
local tinsert = table.insert
local tunpack = table.unpack
local tcopy = table.copy
local ucodes = utf8.codes
local uchar = utf8.char

local bnf = {}
bnf.__index = bnf

function bnf:__init(fname)
    -- initialize
    self.data = {}
    setmetatable(self, bnf)

    -- load file
    if fname then
        self:load(fname)
    end

    return self
end

local function bnferror(pos, msg, ...)
    local args = {...}
    if type(pos) ~= "table" then
        args = {msg, ...}
        msg = pos
    else
        print(sformat("at [%d:%d]:", pos.line, pos.column))
    end

    print(sformat(msg, tunpack(args)))
    os.exit(1)
end

local symbols = {
    ["="] = "definition",
    [","] = "concatenation",
    [";"] = "termination",
    ["|"] = "alternation",
    ["-"] = "exception",
    ["*"] = "repetition"
}

local function iseol(c)
    return (c == "\n")
end

local function isspace(c)
    return (c == " ") or (c == "\t") or (c == "\r")
end

local function isquote(c)
    return (c == "'") or (c == '"')
end

local function isbracket(c)
    return (c == "(") or (c == "[") or (c == "{") or (c == ")") or (c == "]") or (c == "}")
end

local function isidentifier(c)
    return ((c >= "a") and (c <= "z")) or ((c >= "A") and (c <= "Z"))
end

function bnf:tokenize(s)
    local tok = {}
    local tokens = {tok}

    local cursor = {
        line = 1,
        column = 1
    }

    local state, buf, type

    local c, p, it = 0, 0, ucodes(s)
    local function next()
        p, c = it(s, p)
        return uchar(c)
    end

    local endpos = #s
    while p < endpos do
        local ch = next()

        if iseol(ch) then
            cursor.line = cursor.line + 1
            cursor.column = 1
        else
            if isspace(ch) then
                -- ignore
            elseif isquote(ch) then
                -- FIXME escaping ???
                local b, e = s:find(ch, p + 1)
                tinsert(
                    tok,
                    {
                        type = "string",
                        cursor = tcopy(cursor),
                        text = s:sub(p, e)
                    }
                )
                cursor.column = cursor.column + e - p + 1
                p = e + 1
            elseif ch == "?" then
                local b, e = s:find(ch, p + 1)
                tinsert(
                    tok,
                    {
                        type = "special",
                        cursor = tcopy(cursor),
                        text = s:sub(p, e)
                    }
                )
                cursor.column = cursor.column + e - p + 1
                p = e + 1
            elseif ch == ";" then
                tok = {}
                tinsert(tokens, tok)
            elseif isbracket(ch) or symbols[ch] then
                local iscomment = false

                if ch == "(" then
                    -- check comment
                    if s:match("^[(][*]", p) then
                        local b, e = s:find("[*][)]", p + 2)

                        if not b then
                            bnferror(cursor, "found end-of-file while scanning comment")
                        end

                        while p < e do
                            if iseol(next()) then
                                cursor.line = cursor.line + 1
                                cursor.column = 1
                            else
                                cursor.column = cursor.column + 1
                            end
                        end

                        iscomment = true
                    end
                end

                if not iscomment then
                    tinsert(
                        tok,
                        {
                            type = symbols[ch],
                            cursor = tcopy(cursor),
                            text = ch
                        }
                    )
                end
            else
                if not isidentifier(ch) then
                    bnferror(cursor, "expected an identifier character")
                    os.exit(1)
                end

                local b = p
                local curpos = {
                    line = cursor.line,
                    column = cursor.column
                }

                while isidentifier(ch) do
                    ch = next()
                    cursor.column = cursor.column + 1
                end

                while ch == " " do
                    local tmp = p

                    ch = next()
                    if isidentifier(ch) then
                        cursor.column = cursor.column + 1 -- for the previous space
                        while isidentifier(ch) do
                            ch = next()
                            cursor.column = cursor.column + 1
                        end
                    else
                        p = tmp
                        break
                    end
                end

                -- ''while isidentifier(ch)'' overshoots
                cursor.column = cursor.column - 1
                p = p - 1

                tinsert(
                    tok,
                    {
                        type = "name",
                        cursor = curpos,
                        text = s:sub(b, p)
                    }
                )
            end

            cursor.column = cursor.column + 1
        end
    end

    return tokens
end

function bnf:load(fname)
    local f = assert(io.open(fname, "rb"))
    local txt = f:read("a")
    f:close()

    for _, tok in ipairs(self:tokenize(txt)) do
        self:parse(tok)
    end

    self:check()
end

function bnf:parse(sequence)
    if #sequence == 0 then
        return
    end

    local data = self.data
    local name = sequence[1].text

    -- initial sanity checks
    if not sequence[1].type or sequence[1].type ~= "name" then
        bnferror(sequence[1].cursor, "invalid name")
    end

    if not sequence[2].type or sequence[2].type ~= "definition" then
        bnferror(sequence[2].cursor, "expected definition ('=')")
    end

    if type(data[name]) == "table" then
        bnferror(sequence[2].cursor, "%q already defined", name)
    end

    -- initialize
    data[name] = {}

    for i = 3, #sequence do -- adds all required definitions as 'false'
        local ref = sequence[i]

        if ref.type and ref.type == "name" then
            data[ref.text] = data[ref.text] or false
        end
    end
end

function bnf:check()
    -- check if complete
    for k, v in pairs(self.data) do
        if type(v) ~= "table" and not v then
            bnferror("%q not defined", k)
        end
    end
end

-- [[ MODULE ]]
local mod = {}

setmetatable(
    mod,
    {
        __call = function(self, filename)
            return bnf.__init({}, filename)
        end
    }
)

return mod
