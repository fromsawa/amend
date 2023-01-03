--[[
    Copyright (C) 2022-2023 Yogev Sawa
    License: UNLICENSE (see  <http://unlicense.org/>)
]]
return {
    name = "dirs",
    comment = "list component folders in current project",
    scope = "builtin",
    component = function()
        fs.dodir(
            ROOTDIR,
            function(d)
                if fs.exists(fs.concat(d[0], '.amend')) then
                    print(d[0])
                end
            end,
            {exclude = IGNORE, mode = 'directory', recurse = true}
        )
    end
}
