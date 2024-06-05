if GetLocale() ~= "ruRU" then return end

local L

--Прошляпанное очко Мурчаля [✔]

----------------
-- Заклинания --
----------------
L= DBM:GetModLocalization("RaidSpells")

L:SetGeneralLocalization({
	name = "Рейдовые заклинания"
})

L:SetWarningLocalization({
	Rebirth 		= "%s применяет %s на %s",
	Heroism 		= "%s применяет %s",
	Food			= "%s ставит %s",
	RaidCooldown 	= "%s применяет %s",
	MobileBanking	= "%s ставит %s"
})

L:SetOptionLocalization({
	RaidCooldown	 		= "Сообщать, когда кто-то применяет заклинание $spell:97462 или аналогичные ему",
	Rebirth			 		= "Сообщать, когда на кого-то применили $spell:20484 или аналогичные ему",
	YellOnMassRes 			= "Сообщать, когда кто-то применяет заклинание $spell:212036 или аналогичные ему",
	Heroism		 			= "Сообщать, когда кто-то применяет заклинание $spell:32182 или аналогичные ему",
	YellOnPortal 			= "Сообщать, когда кто-то открывает $spell:224871 или аналогичные ему",
	YellOnSoulwell 			= "Сообщать, когда кто-то применяет заклинание $spell:29893",
	YellOnSoulstone 		= "Сообщать, когда на кого-то применили $spell:20707",
	YellOnRitualofSummoning = "Сообщать, когда кто-то применяет заклинание $spell:698",
	YellOnSummoning 		= "Сообщать, когда вы применяете заклинание $spell:7720",
	Food		 			= "Сообщать, когда кто-то ставит $spell:382427 или аналогичные ему",
	YellOnRepair 			= "Сообщать, когда кто-то ставит $spell:199109 или аналогичные ему",
	MobileBanking 			= "Сообщать, когда кто-то ставит $spell:83958",
	YellOnToys 				= "Сообщать, когда кто-то ставит игрушки типо $spell:61031",
	AutoSpirit 				= "Автоматически покидать тело"
})

L:SetMiscLocalization{
	SpellFound 		= "%s применяет %s",
--	WhisperThanks 	= "%s Спасибо тебе за %s!",
	SpellNameYell 	= "Использую %s!",
	SpellNameYell2 	= "Использую %s на %s!",
	HeroismYell 	= "%s %s использует %s!",
	PortalYell 		= "%s %s открывает %s!",
	SoulwellYell 	= "%s %s ставит %s!",
	SoulstoneYell 	= "%s %s применяет %s на %s!",
	SummoningYell 	= "%s %s начинает %s!"
}
