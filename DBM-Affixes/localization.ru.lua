if GetLocale() ~= "ruRU" then return end
local L

-----------------------
-- <<< M+ Affixes >>> --
-----------------------
L = DBM:GetModLocalization("MPlusAffixes")

L:SetGeneralLocalization({
	name =	"М+ аффиксы"
})

L:SetMiscLocalization({
	RasAffix1 = "Стихии подчиняются мне!",
	RasAffix2 = "Молния оставит свой след!"
})
