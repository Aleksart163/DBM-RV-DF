local L

--Прошляпанное очко Мурчаля [✔]

------------
-- Spells --
------------
L= DBM:GetModLocalization("Spells")

L:SetGeneralLocalization({
	name = "Raid Spells"
})

L:SetWarningLocalization({
	Rebirth 		= "%s uses %s on %s",
	Heroism 		= "%s uses %s",
	Food			= "%s puts %s",
	RaidCooldown 	= "%s uses %s",
	MobileBanking	= "%s puts %s"
})

L:SetOptionLocalization({
	RaidCooldown	 		= "Announce when someone is casting a spell $spell:97462 or equivalent",
	Rebirth			 		= "Announce when someone has been subjected to $spell:20484 or equivalent",
	YellOnMassRes 			= "Announce when someone is casting a spell $spell:212036 or equivalent",
	Heroism		 			= "Announce when someone is casting a spell $spell:32182 or equivalent",
	YellOnPortal 			= "Announce when someone opens $spell:224871 or equivalent",
	YellOnSoulwell 			= "Announce when someone is casting a spell $spell:29893",
	YellOnSoulstone 		= "Announce when someone has been subjected to $spell:20707",
	YellOnRitualofSummoning = "Announce when someone is casting a spell $spell:698",
	YellOnSummoning 		= "Announce when you cast a spell $spell:7720",
	Food		 			= "Announce when someone puts $spell:382427 or equivalent",
	YellOnRepair 			= "Announce when someone puts $spell:199109 or equivalent",
	MobileBanking 			= "Announce when someone puts $spell:83958",
	YellOnToys 				= "Announce when someone puts toys like $spell:61031",
	AutoSpirit 				= "Auto-release spirit"
})

L:SetMiscLocalization{
	SpellFound 		= "%s uses %s",
--	WhisperThanks 	= "%s Thank you for %s!",
	SpellNameYell 	= "Using %s!",
	SpellNameYell2 	= "Using %s on %s!",
	HeroismYell 	= "%s %s uses %s!",
	PortalYell 		= "%s %s opens %s!",
	SoulwellYell 	= "%s %s puts %s!",
	SoulstoneYell	= "%s %s applies %s to %s!",
	SummoningYell 	= "%s %s begins %s!"
}
