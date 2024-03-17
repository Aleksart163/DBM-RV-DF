if GetLocale() ~= "koKR" then return end
local L

-----------------------
-- <<< M+ Affixes >>> --
-----------------------
L = DBM:GetModLocalization("MPlusAffixes")

L:SetGeneralLocalization({
	name =	"신화+ 어픽스"
})

L:SetOptionLocalization({
	MurchalOchkenProshlyapen = "$spell:396411 디버프 타이머 바 보기"
})
