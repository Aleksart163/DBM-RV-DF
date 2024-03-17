if GetLocale() ~= "zhCN" then return end
local L

-----------------------
-- <<< M+ Affixes >>> --
-----------------------
L = DBM:GetModLocalization("MPlusAffixes")

L:SetGeneralLocalization({
	name =	"神话+词缀"
})

L:SetOptionLocalization({
	MurchalOchkenProshlyapen = "计时条：$spell:396411减益效果持续时间"
})
