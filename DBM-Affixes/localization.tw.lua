if GetLocale() ~= "zhTW" then return end
local L

-----------------------
-- <<< M+ Affixes >>> --
-----------------------
L = DBM:GetModLocalization("MPlusAffixes")

L:SetGeneralLocalization({
	name =	"傳奇+ 詞綴"
})

L:SetOptionLocalization({
	MurchalOchkenProshlyapen = "計時條：$spell:396411減益效果持續時間"
})
