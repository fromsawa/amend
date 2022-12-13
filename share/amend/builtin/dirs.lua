--[[
    Copyright (C) 2022 Yogev Sawa
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
                print(d[0])
            end,
            {exclude = IGNORE, mode = 'directory', recurse = true}
        )
    end
}
