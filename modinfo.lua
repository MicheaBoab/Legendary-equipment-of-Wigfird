name = "女武神的登神长阶——代罚者薇格弗德"

description = [[
    污秽之物不可容忍！
]]
author = "我真的好美好美(魔改 by MicheaBoab)"
version = "3.2"

forumthread = ""

dst_compatible = true
all_clients_require_mod= true
api_version = 10  

icon_atlas = "modicon.xml"
icon = "modicon.tex"


local keys = {}
local VALID_CHARS = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"} --[[ABCDEFGHJKLMNPQRSTUVWXYZ]]
for i = 1, 26 do
    keys[i] =  {description = "KEY_"..VALID_CHARS[i], data = i+96}
end

configuration_options =
{
    {
        name = "KEYKEYKEY",
        label = "技能按键",
        hover = "技能按键",
        options = keys,
        default = 103,
    },
	--[[
	{
		name = "Lighting_CD_config",
		label = "闪电CD",
		hover = "Lighting CD config",
		options =	{
			{description = "超短CD", data = 5, hover = "5s"},
			{description = "短CD", data = 10, hover = "10s"},
			{description = "默认CD", data = 25, hover = "25s"},
		},
		default = 25,
	},
	]]--
}

