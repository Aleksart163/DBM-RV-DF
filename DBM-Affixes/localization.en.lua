local L

-----------------------
-- <<< M+ Affixes >>> --
-----------------------
L = DBM:GetModLocalization("MPlusAffixes")

L:SetGeneralLocalization({
	name =	"M+ Affixes"
})

L:SetWarningLocalization{
	warnSpiritsleft = "Spirits remaining: %s"
}

L:SetOptionLocalization({
	warnSpiritsleft = "Show special announce about the number of spirits.",
	MurchalOchkenProshlyapen = "Show timer for $spell:396411 debuff"
})

L:SetMiscLocalization({
	AfRaszageth1 = "The elements answer to me!",
	AfRaszageth2 = "Marked by lightning!"
})
