local L

-----------------------
-- <<< M+ Affixes >>> --
-----------------------
L = DBM:GetModLocalization("MPlusAffixes")

L:SetGeneralLocalization({
	name =	"M+ Affixes"
})

L:SetWarningLocalization{
	warnSpiritsleft1	= "The amount of Spirits: %s",
	warnSpiritsleft2	= "Spirits remaining: %s"
}

L:SetOptionLocalization({
	warnSpiritsleft1	= "Show special announce about the number of spirits upon appearance",
	warnSpiritsleft2	= "Show special announce about the number of spirits",
	MurchalOchkenProshlyapen = "Show timer for $spell:396411 debuff"
})

L:SetMiscLocalization({
	AfRaszageth1 = "The elements answer to me!",
	AfRaszageth2 = "Marked by lightning!"
})
