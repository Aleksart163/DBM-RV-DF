if GetLocale() ~= "ruRU" then return end
local L

-----------------------
-- <<< M+ Affixes >>> --
-----------------------
L = DBM:GetModLocalization("MPlusAffixes")

L:SetGeneralLocalization({
	name =	"М+ аффиксы"
})

L:SetOptionLocalization({
	MurchalOchkenProshlyapen = "Отсчёт времени действия дебаффа $spell:396411"
})

L:SetMiscLocalization({
	AfRaszageth1 = "Стихии подчиняются мне!",
	AfRaszageth2 = "Молния оставит свой след!"
})
