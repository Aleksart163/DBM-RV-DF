local mod	= DBM:NewMod("RaidSpells", "DBM-Raid-Spells")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240826070000")
mod:SetZone()
--mod:SetZone(DBM_DISABLE_ZONE_DETECTION)

mod:RegisterEvents(
	"SPELL_CAST_START 61994 212040 212056 212036 212048 212051 7720 361178",
	"SPELL_CAST_SUCCESS 391776 31821 61994 381301 391054 272678 57724 264667 385403 61999 20484 95750 161399 157757 80353 32182 90355 2825 160452 10059 11416 11419 32266 49360 11417 11418 11420 32267 49361 33691 53142 88345 88346 132620 132626 176246 176244 224871 29893 83958 21169 97462 205223 62618 64901 390386 740 64843 363534",
	"SPELL_AURA_APPLIED 34477 57934 6940 204018 20707 33206 116849 1022 29166 64901 102342 357170 47788 10060 369459",
	"SPELL_AURA_REMOVED 29166 64901 197908",
	"SPELL_SUMMON 67826 199109 199115 195782 98008 207399 256153",
	"SPELL_CREATE 698 201351 185709 88304 61031 49844 382423 371515 371519 371521 406963 406964 406965 383063 382427",
--	"SPELL_RESURRECT 20484 95750 61999",
	"PLAYER_DEAD",
--	"LOADING_SCREEN_DISABLED",
	"GOSSIP_SHOW"--[[,
	"UNIT_SPELLCAST_SUCCEEDED"]]
)

--Прошляпанное очко Мурчаля Прошляпенко на рейдовых спеллах [✔✔✔]
local warnMisdirection				= mod:NewYouAnnounce(34477, 1) --Перенаправление
local warnTricksTheTrade			= mod:NewYouAnnounce(57934, 1) --Маленькие хитрости

local warnMassres					= mod:NewTargetSourceAnnounce2(212036, 1) --Массовое воскрешение (прист) --
--local warnMassres1					= mod:NewTargetSourceAnnounce2(212040, 1) --Ободрение (друид) --
--local warnMassres2					= mod:NewTargetSourceAnnounce2(212056, 1) --Отпущение (пал) --
--local warnMassres3					= mod:NewTargetSourceAnnounce2(212036, 1) --Массовое воскрешение (прист) --
--local warnMassres4					= mod:NewTargetSourceAnnounce2(212048, 1) --Древнее видение (шаман) --
--local warnMassres5					= mod:NewTargetSourceAnnounce2(212051, 1) --Повторное пробуждение (монк) --
--local warnMassres6					= mod:NewTargetSourceAnnounce2(361178, 1) --Массовое возвращение (драктир)
--инженерия
local warnJeeves					= mod:NewTargetSourceAnnounce2(67826, 1) --Дживс
local warnAutoHammer				= mod:NewTargetSourceAnnounce2(199109, 1) --Автоматический молот
--героизм
--local warnTimeWarp					= mod:NewSpellAnnounce(80353, 1) --Искажение времени
--local warnFuryoftheAspects			= mod:NewSpellAnnounce(390386, 1) --Ярость Аспектов
--local warnHeroism					= mod:NewSpellAnnounce(32182, 1) --Героизм
--local warnBloodlust					= mod:NewSpellAnnounce(2825, 1) --Кровожадность
--local warnFeralHideDrums			= mod:NewSpellAnnounce(381301, 1) --Барабаны из дикой шкуры
--local warnTimeWarp				= mod:NewAnnounce("Heroism", 1, 80353) --Искажение времени
--local warnFuryoftheAspects		= mod:NewAnnounce("Heroism", 1, 390386) --Ярость Аспектов
--local warnHeroism					= mod:NewAnnounce("Heroism", 1, 32182) --Героизм
--local warnBloodlust				= mod:NewAnnounce("Heroism", 1, 2825) --Кровожадность
--local warnFeralHideDrums			= mod:NewAnnounce("Heroism", 1, 381301) --Барабаны из дикой шкуры
local warnTimeWarp					= mod:NewTargetSourceAnnounce2(80353, 1) --Искажение времени
local warnFuryoftheAspects			= mod:NewTargetSourceAnnounce2(390386, 1) --Ярость Аспектов
local warnHeroism					= mod:NewTargetSourceAnnounce2(32182, 1) --Героизм
local warnBloodlust					= mod:NewTargetSourceAnnounce2(2825, 1) --Кровожадность
local warnFeralHideDrums			= mod:NewTargetSourceAnnounce2(381301, 1) --Барабаны из дикой шкуры
local warnHysteria					= mod:NewSpellAnnounce(90355, 1) --Древняя истерия
local warnNetherwinds				= mod:NewSpellAnnounce(160452, 1) --Ветер пустоты
local warnPrimalRage				= mod:NewSpellAnnounce(264667, 1) --Исступление
local warnSated						= mod:NewSpellAnnounce(57724, 1) --Пресыщение
local warnPrimalRage2				= mod:NewSpellAnnounce(272678, 1) --Исступление
--бр
local warnRebirth					= mod:NewAnnounce("Rebirth", 1, 20484) --Возрождение
--local warnRebirth					= mod:NewTargetSourceAnnounce(20484, 1) --Возрождение
--другое
local warnRitualofSummoning			= mod:NewTargetSourceAnnounce2(698, 1) --Ритуал призыва
local warnEndlessCloaks				= mod:NewTargetSourceAnnounce2(391789, 1) --Шкафчик с множеством плащей
local warnRearranger				= mod:NewTargetSourceAnnounce2(256155, 1) --Портативный трансмогрификатор

--еда и поты
local warnYusasHeartyStew			= mod:NewTargetSourceAnnounce2(382423, 1) --Сытная похлебка Юсы
local warnGrandBanquet				= mod:NewTargetSourceAnnounce2(382427, 1) --Большой калуакский банкет
local warnDraconicDelicacies		= mod:NewTargetSourceAnnounce2(383063, 1) --Гора драконьих деликатесов
local warnPotionCauldronofPower		= mod:NewTargetSourceAnnounce2(371515, 1) --Котел с зельями мощи, 371519, 371521
local warnPotionCauldronofPower2	= mod:NewTargetSourceAnnounce2(370672, 1) --Котел с зельями великой мощи, 406964, 406965

local warnSoulstone					= mod:NewTargetNoFilterAnnounce(20707, 1) --Камень души
--рейд сейвы
local warnRallyingCry				= mod:NewTargetSourceAnnounce2(97462, 1) --Ободряющий клич
local warnPowerWordBarrier			= mod:NewTargetSourceAnnounce2(62618, 1) --Слово силы: Барьер
local warnRewind					= mod:NewTargetSourceAnnounce2(363534, 1) --Перемотка
local warnDivineHymn				= mod:NewTargetSourceAnnounce2(64843, 1) --Божественный гимн
local warnTranquility				= mod:NewTargetSourceAnnounce2(740, 1) --Спокойствие
local warnAncestralProtectionTotem	= mod:NewTargetSourceAnnounce2(207399, 1) --Тотем защиты Предков
--local warnPowerWordBarrier			= mod:NewAnnounce("RaidCooldown", 1, 62618) --Слово силы: Барьер
--local warnRewind					= mod:NewAnnounce("RaidCooldown", 1, 363534) --Перемотка
--local warnDivineHymn				= mod:NewAnnounce("RaidCooldown", 1, 64843) --Божественный гимн
--local warnTranquility				= mod:NewAnnounce("RaidCooldown", 1, 740) --Спокойствие
--local warnAncestralProtectionTotem	= mod:NewAnnounce("RaidCooldown", 1, 207399) --Тотем защиты Предков
--Мобильный банк
local warnMobileBanking				= mod:NewTargetSourceAnnounce2(83958, 1) --Мобильный банк
--local warnMobileBanking				= mod:NewAnnounce("MobileBanking", 1, 83958) --Мобильный банк

local specWarnSoulstone				= mod:NewSpecialWarningYou(20707, nil, nil, nil, 1, 2) --Камень души
local specWarnBlessingSpellwarding	= mod:NewSpecialWarningYou(204018, nil, nil, nil, 1, 2) --Благословение защиты от заклинаний
local specWarnBlessingSacrifice		= mod:NewSpecialWarningYou(6940, nil, nil, nil, 1, 2) --Жертвенное благословение
local specWarnSourceofMagic			= mod:NewSpecialWarningYou(369459, nil, nil, nil, 1, 2) --Магический источник
local specWarnPrimalRage			= mod:NewSpecialWarningYou(264667, nil, nil, nil, 1, 2) --Исступление
local specWarnPowerInfusion			= mod:NewSpecialWarningYou(10060, nil, nil, nil, 1, 2) --Придание сил
local specWarnGuardianSpirit		= mod:NewSpecialWarningYou(47788, nil, nil, nil, 1, 2) --Оберегающий дух
local specWarnTimeDilation			= mod:NewSpecialWarningYou(357170, nil, nil, nil, 1, 2) --Растяжение времени
local specWarnPainSuppression		= mod:NewSpecialWarningYou(33206, nil, nil, nil, 1, 2) --Подавление боли
local specWarnLifeCocoon			= mod:NewSpecialWarningYou(116849, nil, nil, nil, 1, 2) --Исцеляющий кокон
local specWarnBlessingofProtection	= mod:NewSpecialWarningYou(1022, nil, nil, nil, 1, 2) --Благословение защиты
local specWarnRebirth 				= mod:NewSpecialWarningYou(20484, nil, nil, nil, 1, 2) --Возрождение
local specWarnIronbark				= mod:NewSpecialWarningYou(102342, nil, nil, nil, 1, 2) --Железная кора
local specWarnInnervate 			= mod:NewSpecialWarningYou(29166, nil, nil, nil, 1, 2) --Озарение
local specWarnInnervate2			= mod:NewSpecialWarningEnd(29166, nil, nil, nil, 1, 2) --Озарение
local specWarnSymbolHope 			= mod:NewSpecialWarningYou(64901, nil, nil, nil, 1, 2) --Символ надежды
--local specWarnSymbolHope2			= mod:NewSpecialWarningEnd(64901, nil, nil, nil, 1, 2) --Символ надежды
local specWarnManaTea2				= mod:NewSpecialWarningEnd(197908, nil, nil, nil, 1, 2) --Маначай

local timerEndlessCloaks			= mod:NewCastTimer(300, 391789, nil, nil, nil, 7) --Шкафчик с множеством плащей
local timerRearranger				= mod:NewCastTimer(120, 256155, nil, nil, nil, 7) --Портативный трансмогрификатор
--local timerRallyingCry				= mod:NewBuffActiveTimer(10, 97462, nil, nil, nil, 7) --Ободряющий клич

local yellEndlessCloaks				= mod:NewShortYell(391776, nil, nil, nil, "YELL") --Шкафчик с множеством плащей
local yellRearranger				= mod:NewShortYell(256153, nil, nil, nil, "YELL") --Портативный трансмогрификатор
local yellMobileBanking				= mod:NewShortYell(83958, nil, nil, nil, "YELL") --Мобильный банк
local yellTimeWarp					= mod:NewShortYell(80353, nil, nil, nil, "YELL") --Искажение времени
local yellFuryoftheAspects			= mod:NewShortYell(390386, nil, nil, nil, "YELL") --Ярость Аспектов
local yellHeroism					= mod:NewShortYell(32182, nil, nil, nil, "YELL") --Героизм
local yellBloodlust					= mod:NewShortYell(2825, nil, nil, nil, "YELL") --Кровожадность
local yellFeralHideDrums			= mod:NewShortYell(381301, nil, nil, nil, "YELL") --Барабаны из дикой шкуры
local yellAuraMastery				= mod:NewShortYell(31821, nil, nil, nil, "YELL") --Владение аурами
local yellRitualSummoning			= mod:NewShortYell(698, nil, nil, nil, "YELL") --Ритуал призыва
local yellRewind					= mod:NewShortYell(363534, nil, nil, nil, "YELL") --Перемотка
local yellDivineHymn				= mod:NewShortYell(64843, nil, nil, nil, "YELL") --Божественный гимн
local yellTranquility				= mod:NewShortYell(740, nil, nil, nil, "YELL") --Спокойствие
local yellRallyingCry				= mod:NewShortYell(97462, nil, nil, nil, "YELL") --Ободряющий клич
local yellPowerWordBarrier			= mod:NewShortYell(62618, nil, nil, nil, "YELL") --Слово силы: Барьер
local yellAncestralProtectionTotem	= mod:NewShortYell(207399, nil, nil, nil, "YELL") --Тотем защиты Предков
local yellSpiritLinkTotem			= mod:NewShortYell(98008, nil, nil, nil, "YELL") --Тотем духовной связи
local yellSymbolHope				= mod:NewShortYell(64901, nil, nil, nil, "YELL") --Символ надежды
local yellTricksTheTrade			= mod:NewYell(57934, L.SpellNameYell2, nil, nil, "YELL") --Маленькие хитрости
local yellMisdirection				= mod:NewYell(34477, L.SpellNameYell2, nil, nil, "YELL") --Перенаправление
local yellYusasHeartyStew			= mod:NewShortYell(382423, nil, nil, nil, "YELL") --Сытная похлебка Юсы
local yellGrandBanquet				= mod:NewShortYell(382427, nil, nil, nil, "YELL") --Большой калуакский банкет
local yellDraconicDelicacies		= mod:NewShortYell(383063, nil, nil, nil, "YELL") --Гора драконьих деликатесов
local yellPotionCauldronofPower		= mod:NewShortYell(371515, nil, nil, nil, "YELL") --Котел с зельями мощи
local yellPotionCauldronofPower2	= mod:NewShortYell(406963, nil, nil, nil, "YELL") --Котел с зельями великой мощи

--mod:AddBoolOption("YellOnRaidCooldown", true) --рейд кд
--mod:AddBoolOption("YellOnResurrect", true) --бр
mod:AddBoolOption("YellOnMassRes", true) --масс рес
--mod:AddBoolOption("YellOnHeroism", true) --героизм
--mod:AddBoolOption("YellOnPortal", true) --порталы
--mod:AddBoolOption("YellOnSoulwell", true)
--mod:AddBoolOption("YellOnSoulstone", true)
--mod:AddBoolOption("YellOnRitualofSummoning", true)
mod:AddBoolOption("YellOnSummoning", true)
--mod:AddBoolOption("YellOnLavish", true) --еда
--mod:AddBoolOption("YellOnBank", true) --банк
--mod:AddBoolOption("YellOnRepair", true) --починка
mod:AddBoolOption("YellOnToys", true) --игрушки
mod:AddBoolOption("AutoSpirit", false)

local Rebirth = DBM:GetSpellName(20484) 
local typeInstance = nil
local DbmRV = "[DBM RV] "

--local murchalOchkenProshlyapation = DBM:GetModByName("MPlusAffixes")

local function UnitInYourParty(sourceName)
	if GetNumGroupMembers() > 0 and (UnitInParty(sourceName) or UnitPlayerOrPetInParty(sourceName) or UnitInRaid(sourceName) or UnitInBattleground(sourceName)) then
		return true
	end
	return false
end

-- Синхронизация анонсов ↓
local premsg_values = {
	-- ["premsg_Spells_test"] = {0, L.HeroismYell}, -- test (Needs to be commented out before release) 8690
	-- ["premsg_Spells_test2"] = {0, L.HeroismYell}, -- test2 (Needs to be commented out before release) 222695
	["premsg_Spells_massres1_rw"] = {0, L.HeroismYell, nil, "rw"},
	["premsg_Spells_massres2_rw"] = {0, L.HeroismYell, nil, "rw"},
	["premsg_Spells_massres3_rw"] = {0, L.HeroismYell, nil, "rw"},
	["premsg_Spells_massres4_rw"] = {0, L.HeroismYell, nil, "rw"},
	["premsg_Spells_massres5_rw"] = {0, L.HeroismYell, nil, "rw"},
	["premsg_Spells_massres6_rw"] = {0, L.HeroismYell, nil, "rw"},
	["premsg_Spells_feralHideDrums"] = {0, L.HeroismYell},
	["premsg_Spells_primalRage"] = {0, L.HeroismYell},
	["premsg_Spells_primalRage2"] = {0, L.HeroismYell},
	["premsg_Spells_sated"] = {0, L.HeroismYell},
	["premsg_Spells_timeWarp"] = {0, L.HeroismYell},
	["premsg_Spells_furyAspects"] = {0, L.HeroismYell},
	["premsg_Spells_heroism"] = {0, L.HeroismYell},
	["premsg_Spells_bloodlust"] = {0, L.HeroismYell},
	["premsg_Spells_hysteria"] = {0, L.HeroismYell},
	["premsg_Spells_winds"] = {0, L.HeroismYell},
	["premsg_Spells_soulwell"] = {0, L.HeroismYell},
	["premsg_Spells_soulstone"] = {0, L.SoulstoneYell, true},
	["premsg_Spells_summoning"] = {0, L.SummoningYell},
	["premsg_Spells_CauldronofPower_rw"] = {0, L.SoulwellYell, nil, "rw"}, --Котел с зельями мощи
	["premsg_Spells_CauldronofPower2_rw"] = {0, L.HeroismYell, nil, "rw"}, --Котел с зельями великой мощи
	["premsg_Spells_YusasHeartyStew"] = {0, L.SoulwellYell}, --Сытная похлебка Юсы
	["premsg_Spells_DraconicDelicacies"] = {0, L.HeroismYell}, --Гора драконьих деликатесов
--	["premsg_Spells_lavishSuramar_rw"] = {0, L.SoulwellYell},
--	["premsg_Spells_hearty"] = {0, L.SoulwellYell},
--	["premsg_Spells_sugar"] = {0, L.SoulwellYell},
	["premsg_Spells_jeeves_rw"] = {0, L.SoulwellYell},
	["premsg_Spells_autoHammer_rw"] = {0, L.SoulwellYell},
	["premsg_Spells_pylon_rw"] = {0, L.SoulwellYell},
	["premsg_Spells_swap"] = {0, L.SoulstoneYell, true},
	["premsg_Spells_bank"] = {0, L.SoulwellYell},
	["premsg_Spells_toyTrain"] = {0, L.SoulwellYell},
	["premsg_Spells_moonfeather"] = {0, L.HeroismYell},
	["premsg_Spells_direbrews"] = {0, L.SummoningYell},
	["premsg_Spells_rallyingcry"] = {0, L.HeroismYell}, --Ободряющий клич
	["premsg_Spells_powerwordbarrier"] = {0, L.HeroismYell}, --Слово силы: Барьер
	["premsg_Spells_painsuppression"] = {0, L.SoulstoneYell, true}, --Подавление боли
	["premsg_Spells_spirittotem"] = {0, L.HeroismYell}, --Тотем духовной связи
	["premsg_Spells_lifecocoon"] = {0, L.SoulstoneYell, true}, --Исцеляющий кокон
	["premsg_Spells_blesofprot"] = {0, L.SoulstoneYell, true}, --Благословение защиты
	["premsg_Spells_ironbark"] = {0, L.SoulstoneYell, true}, --Железная кора
	["premsg_Spells_ancprotectotem"] = {0, L.HeroismYell}, --Тотем защиты Предков
	["premsg_Spells_hope"] = {0, L.HeroismYell}, --Символ надежды
	["premsg_Spells_divineHymn"] = {0, L.HeroismYell}, --Божественный гимн
	["premsg_Spells_tranquility"] = {0, L.HeroismYell}, --Спокойствие
	["premsg_Spells_rewind"] = {0, L.HeroismYell}, --Перемотка
--	["premsg_Spells_innervate"] = {0, L.SoulstoneYell, true}, --Озарение
	["premsg_Spells_rebirth1"] = {0, L.SoulstoneYell, true}, --Возрождение
	["premsg_Spells_rebirth2"] = {0, L.SoulstoneYell, true}, --Воскрешение союзника
	["premsg_Spells_rebirth3"] = {0, L.SoulstoneYell, true}, --Воскрешение камнем души
	["premsg_Spells_rebirth4"] = {0, L.SoulstoneYell, true}, --Заступничество
	["premsg_Spells_rebirth5"] = {0, L.SoulstoneYell, true} --Тангенциальный корректор жизненной силы
}
local playerOnlyName = UnitName("player")

local function sendAnnounce(self, spellId, sourceName, destName)
	for k, v in pairs(premsg_values) do
		if type(v) == "table" and v[1] == 1 then
			v[1] = 0
			if (not spellId) or (not sourceName) or (v[3] and not destName) then
				DBM:Debug('[sendAnnounce] spellId: ' .. tostring(spellId) .. ', sourceName: ' .. tostring(sourceName) .. ', destName: ' .. tostring(destName))
				return
			end
			smartAss(v[2]:format(DbmRV, sourceName, SpellLinks(spellId), destName), v[4])
		end
	end
end

local function announceList(premsg_announce, value)
	for k, v in pairs(premsg_values) do
		if type(v) == "table" and k == premsg_announce then
			v[1] = value
		end
	end
end

local function prepareMessage(self, premsg_announce, spellId, sourceName, destName)
	if self:AntiSpam(1, "prepareMessage") then
		for k, v in pairs(premsg_values) do
			if type(v) == "table" and k == premsg_announce then
				if (not spellId) or (not sourceName) or (v[3] and not destName) then
					DBM:Debug('[prepareMessage] spellId: ' .. tostring(spellId) .. ', sourceName: ' .. tostring(sourceName) .. ', destName: ' .. tostring(destName))
					return
				end
			end
		end

		announceList(premsg_announce, 1)
		self:SendSync(premsg_announce, playerOnlyName)
		self:Schedule(1, sendAnnounce, self, spellId, sourceName, destName)
	end
end
-- Синхронизация анонсов ↑

function mod:SPELL_CAST_START(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	local sourceName = args.sourceName
	local destName = args.destName
	spellName = DBM:GetSpellInfo(spellId)
	if not UnitInYourParty(sourceName) then return end
	--[[if spellId == 8690 then -- test (Needs to be commented out before release)
		prepareMessage(self, "premsg_Spells_test", spellId, sourceName)
	elseif spellId == 222695 then -- test2 (Needs to be commented out before release)
		prepareMessage(self, "premsg_Spells_test2", spellId, sourceName)
	else]]
	typeInstance = select(2, IsInInstance())
	if typeInstance ~= "party" and typeInstance ~= "raid" then return end
	if DBM:GetNumRealGroupMembers() < 2 then return end
	if spellId == 212040 and self:AntiSpam(15, "massres") then --Возвращение к жизни (друид)
		if self.Options.YellOnMassRes then
			warnMassres:Show(sourceName, spellName)
		end
	--[[	if self.Options.YellOnMassRes then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnMassRes then
			prepareMessage(self, "premsg_Spells_massres1_rw", spellId, sourceName)
		end]]
	elseif spellId == 212056 and self:AntiSpam(15, "massres") then --Отпущение (пал)
		if self.Options.YellOnMassRes then
			warnMassres:Show(sourceName, spellName)
		end
	--[[	if self.Options.YellOnMassRes then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnMassRes then
			prepareMessage(self, "premsg_Spells_massres2_rw", spellId, sourceName)
		end]]
	elseif spellId == 212036 and self:AntiSpam(15, "massres") then --Массовое воскрешение (прист)
		if self.Options.YellOnMassRes then
			warnMassres:Show(sourceName, spellName)
		end
	--[[	if self.Options.YellOnMassRes then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnMassRes then
			prepareMessage(self, "premsg_Spells_massres3_rw", spellId, sourceName)
		end]]
	elseif spellId == 212048 and self:AntiSpam(15, "massres") then --Древнее видение (шаман)
		if self.Options.YellOnMassRes then
			warnMassres:Show(sourceName, spellName)
		end
	--[[	if self.Options.YellOnMassRes then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnMassRes then
			prepareMessage(self, "premsg_Spells_massres4_rw", spellId, sourceName)
		end]]
	elseif spellId == 212051 and self:AntiSpam(15, "massres") then --Повторное пробуждение (монк)
		if self.Options.YellOnMassRes then
			warnMassres:Show(sourceName, spellName)
		end
	--[[	if self.Options.YellOnMassRes then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnMassRes then
			prepareMessage(self, "premsg_Spells_massres5_rw", spellId, sourceName)
		end]]
	elseif spellId == 361178 and self:AntiSpam(15, "massres") then --Массовое возвращение (драктир)
		if self.Options.YellOnMassRes then
			warnMassres:Show(sourceName, spellName)
		end
	--[[	if self.Options.YellOnMassRes then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnMassRes then
			prepareMessage(self, "premsg_Spells_massres6_rw", spellId, sourceName)
		end]]
--[[	elseif spellId == 7720 then --Ритуал призыва
		if self.Options.YellOnSummoning then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnSummoning then
			if args:IsPlayerSource() then
				smartAss(L.SoulstoneYell:format(DbmRV, sourceName, SpellLinks(spellId), UnitName("target")))
			end
		end]]
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	local sourceName = args.sourceName
	local destName = args.destName
	spellName = DBM:GetSpellInfo(spellId)
	if not UnitInYourParty(sourceName) then return end
	typeInstance = select(2, IsInInstance())
	if spellId == 381301 then --Барабаны из дикой шкуры
		if args:IsPlayerSource() then
			yellFeralHideDrums:Yell(SpellLinks(spellId))
		elseif self:AntiSpam(5, "bloodlust") then
			warnFeralHideDrums:Show(sourceName, spellName)
		end
	--[[	if self:AntiSpam(5, "bloodlust") then
			warnFeralHideDrums:Show(sourceName, spellName)
		end
		if self.Options.YellOnHeroism then
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnHeroism then
			prepareMessage(self, "premsg_Spells_feralHideDrums", spellId, sourceName)
		end]]
	--	DBM:AddMsg(L.SpellFound:format(sourceName, spellName))
	elseif spellId == 80353 then --Искажение времени
		if args:IsPlayerSource() then
			yellTimeWarp:Yell(SpellLinks(spellId))
		elseif self:AntiSpam(5, "bloodlust") then
			warnTimeWarp:Show(sourceName, spellName)
		end
	--[[	if self:AntiSpam(5, "bloodlust") then
			warnTimeWarp:Show(sourceName, spellName)
		end
		if self.Options.YellOnHeroism then
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnHeroism then
			prepareMessage(self, "premsg_Spells_timeWarp", spellId, sourceName)
		end]]
	--	DBM:AddMsg(L.SpellFound:format(sourceName, spellName))
	elseif spellId == 2825 then --Кровожадность
		if args:IsPlayerSource() then
			yellBloodlust:Yell(SpellLinks(spellId))
		elseif self:AntiSpam(5, "bloodlust") then
			warnBloodlust:Show(sourceName, spellName)
		end
	--[[	if self:AntiSpam(5, "bloodlust") then
			warnBloodlust:Show(sourceName, spellName)
		end
		if self.Options.YellOnHeroism then
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnHeroism then
			prepareMessage(self, "premsg_Spells_bloodlust", spellId, sourceName)
		end]]
		DBM:Debug('Checking proshlyap of Murchal spell id: ' .. tostring(spellId) .. ', spell name: ' .. tostring(DBM:GetSpellInfo(spellId)) .. ', name: ' .. tostring(sourceName) .. ' ', 2)
	--	DBM:AddMsg(L.SpellFound:format(sourceName, spellName))
	elseif spellId == 390386 then --Ярость Аспектов
		if args:IsPlayerSource() then
			yellFuryoftheAspects:Yell(SpellLinks(spellId))
		elseif self:AntiSpam(5, "bloodlust") then
			warnFuryoftheAspects:Show(sourceName, spellName)
		end
	--[[	if self:AntiSpam(5, "bloodlust") then
			warnFuryoftheAspects:Show(sourceName, spellName)
		end
		if self.Options.YellOnHeroism then
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnHeroism then
			prepareMessage(self, "premsg_Spells_furyAspects", spellId, sourceName)
		end]]
		DBM:Debug('Checking proshlyap of Murchal spell id: ' .. tostring(spellId) .. ', spell name: ' .. tostring(DBM:GetSpellInfo(spellId)) .. ', name: ' .. tostring(sourceName) .. ' ', 2)
	--	DBM:AddMsg(L.SpellFound:format(sourceName, spellName))
	elseif spellId == 32182 then --Героизм
		if args:IsPlayerSource() then
			yellHeroism:Yell(SpellLinks(spellId))
		elseif self:AntiSpam(5, "bloodlust") then
			warnHeroism:Show(sourceName, spellName)
		end
	--[[	if self:AntiSpam(5, "bloodlust") then
			warnHeroism:Show(sourceName, spellName)
		end
		if self.Options.YellOnHeroism then
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnHeroism then
			prepareMessage(self, "premsg_Spells_heroism", spellId, sourceName)
		end]]
		DBM:Debug('Checking proshlyap of Murchal spell id: ' .. tostring(spellId) .. ', spell name: ' .. tostring(DBM:GetSpellInfo(spellId)) .. ', name: ' .. tostring(sourceName) .. ' ', 2)
	--	DBM:AddMsg(L.SpellFound:format(sourceName, spellId))
	elseif spellId == 264667 then --Исступление
--[[		local petGUID = UnitGUID("pet")
		if petGUID then
			local petOwner = nil
			local petOwnerName = nil
			for i = 1, GetNumBattlefieldScores() do
				petOwner = GetBattlefieldScore(i)
            
				if petOwner and petOwner.guid == petGUID then
					petOwnerName = petOwner.name
					break
				end
			end
		end
		if self:AntiSpam(5, "bloodlust") then
			warnPrimalRage:Show(sourceName)
			specWarnPrimalRage:Show()
		end
		if self.Options.YellOnHeroism then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnHeroism then
		--	prepareMessage(self, "premsg_Spells_primalRage", spellId, sourceName)
			prepareMessage(self, "premsg_Spells_primalRage", spellId, petOwnerName)
		end]]
	--	specWarnPrimalRage:Show()
		if args:IsPetSource() then
			local playerClass = select(2, UnitClass("player"))
			if playerClass == "HUNTER" then
				local player = GetUnitName("player")
			end
		--[[	if self.Options.YellOnHeroism then
				prepareMessage(self, "premsg_Spells_primalRage", spellId, player)
			end]]
			DBM:Debug('Checking proshlyap of Murchal1 spell id: ' .. tostring(spellId) .. ', spell name: ' .. tostring(DBM:GetSpellInfo(spellId)) .. ', name: ' .. tostring(sourceName) .. ' ', 2)
--[[		else
			if self.Options.YellOnHeroism then
				prepareMessage(self, "premsg_Spells_primalRage", spellId, sourceName)
			end
			DBM:Debug("Checking proshlyapation of Murchal2 (PrimalRage1)", 2)]]
		else
		--[[	if self.Options.YellOnHeroism then
				prepareMessage(self, "premsg_Spells_primalRage", spellId, sourceName)
			end]]
			DBM:Debug('Checking proshlyap of Murchal2 spell id: ' .. tostring(spellId) .. ', spell name: ' .. tostring(DBM:GetSpellInfo(spellId)) .. ', name: ' .. tostring(sourceName) .. ' ', 2)
		end
		DBM:AddMsg(L.SpellFound:format(sourceName, spellName))
	elseif spellId == 272678 then --Исступление
	--	specWarnPrimalRage:Show()
		if args:IsPetSource() then
			local playerClass = select(2, UnitClass("player"))
			if playerClass == "HUNTER" then
				local player = GetUnitName("player")
			end
		--[[	if self.Options.YellOnHeroism then
				prepareMessage(self, "premsg_Spells_primalRage2", spellId, player)
			end]]
			DBM:Debug('Checking proshlyap of Murchal spell id: ' .. tostring(spellId) .. ', spell name: ' .. tostring(DBM:GetSpellInfo(spellId)) .. ', name: ' .. tostring(sourceName) .. ' ', 2)
--[[		else
			if self.Options.YellOnHeroism then
				prepareMessage(self, "premsg_Spells_primalRage2", spellId, sourceName)
			end
			DBM:Debug("Checking proshlyapation of Murchal2 (PrimalRage2)", 2)]]
		end
		DBM:AddMsg(L.SpellFound:format(sourceName, spellName))
	elseif spellId == 57724 then --Пресыщение
--[[		if self:AntiSpam(5, "bloodlust") then
			warnSated:Show(sourceName)
		end
		if self.Options.YellOnHeroism then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnHeroism then
			prepareMessage(self, "premsg_Spells_sated", spellId, sourceName)
		end]]
	--	specWarnPrimalRage:Show()
		if args:IsPetSource() then
			local playerClass = select(2, UnitClass("player"))
			if playerClass == "HUNTER" then
				local player = GetUnitName("player")
			end
		--[[	if self.Options.YellOnHeroism then
				prepareMessage(self, "premsg_Spells_sated", spellId, player)
			end]]
			DBM:Debug('Checking proshlyap of Murchal1 spell id: ' .. tostring(spellId) .. ', spell name: ' .. tostring(DBM:GetSpellInfo(spellId)) .. ', name: ' .. tostring(sourceName) .. ' ', 2)
		else
		--[[	if self.Options.YellOnHeroism then
		--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnHeroism then
				prepareMessage(self, "premsg_Spells_sated", spellId, sourceName)
			end]]
			DBM:Debug('Checking proshlyap of Murchal2 spell id: ' .. tostring(spellId) .. ', spell name: ' .. tostring(DBM:GetSpellInfo(spellId)) .. ', name: ' .. tostring(sourceName) .. ' ', 2)
		end
		DBM:AddMsg(L.SpellFound:format(sourceName, spellName))
	elseif spellId == 90355 then --Древняя истерия (пет ханта)
--[[		if self:AntiSpam(5, "bloodlust") then
			warnHysteria:Show(sourceName)
		end
		if self.Options.YellOnHeroism then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnHeroism then
			prepareMessage(self, "premsg_Spells_hysteria", spellId, sourceName)
		end]]
	--	specWarnPrimalRage:Show()
		if args:IsPetSource() then
			local playerClass = select(2, UnitClass("player"))
			if playerClass == "HUNTER" then
				local player = GetUnitName("player")
			end
		--[[	if self.Options.YellOnHeroism then
				prepareMessage(self, "premsg_Spells_hysteria", spellId, player)
			end]]
			DBM:Debug('Checking proshlyap of Murchal1 spell id: ' .. tostring(spellId) .. ', spell name: ' .. tostring(DBM:GetSpellInfo(spellId)) .. ', name: ' .. tostring(sourceName) .. ' ', 2)
		else
		--[[	if self.Options.YellOnHeroism then
		--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnHeroism then
				prepareMessage(self, "premsg_Spells_hysteria", spellId, sourceName)
			end]]
			DBM:Debug('Checking proshlyap of Murchal2 spell id: ' .. tostring(spellId) .. ', spell name: ' .. tostring(DBM:GetSpellInfo(spellId)) .. ', name: ' .. tostring(sourceName) .. ' ', 2)
		end
		DBM:AddMsg(L.SpellFound:format(sourceName, spellName))
	elseif spellId == 160452 then --Ветер пустоты (пет ханта)
--[[		if self:AntiSpam(5, "bloodlust") then
			warnNetherwinds:Show(sourceName)
		end
		if self.Options.YellOnHeroism then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnHeroism then
			prepareMessage(self, "premsg_Spells_winds", spellId, sourceName)
		end]]
	--	specWarnPrimalRage:Show()
		if args:IsPetSource() then
			local playerClass = select(2, UnitClass("player"))
			if playerClass == "HUNTER" then
				local player = GetUnitName("player")
			end
		--[[	if self.Options.YellOnHeroism then
				prepareMessage(self, "premsg_Spells_winds", spellId, player)
			end]]
			DBM:Debug('Checking proshlyap of Murchal1 spell id: ' .. tostring(spellId) .. ', spell name: ' .. tostring(DBM:GetSpellInfo(spellId)) .. ', name: ' .. tostring(sourceName) .. ' ', 2)
		else
		--[[	if self.Options.YellOnHeroism then
		--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnHeroism then
				prepareMessage(self, "premsg_Spells_winds", spellId, sourceName)
			end]]
			DBM:Debug('Checking proshlyap of Murchal2 spell id: ' .. tostring(spellId) .. ', spell name: ' .. tostring(DBM:GetSpellInfo(spellId)) .. ', name: ' .. tostring(sourceName) .. ' ', 2)
		end
		DBM:AddMsg(L.SpellFound:format(sourceName, spellName))
--[[	elseif spellId == 10059 then --Штормград
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnPortal then
			prepareMessage(self, "premsg_Spells_stormwind", spellId, sourceName)
		end
	elseif spellId == 11416 then --Стальгорн
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnPortal then
			prepareMessage(self, "premsg_Spells_ironforge", spellId, sourceName)
		end
	elseif spellId == 11419 then --Дарнас
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnPortal then
			prepareMessage(self, "premsg_Spells_darnassus", spellId, sourceName)
		end
	elseif spellId == 32266 then --Экзодар
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnPortal then
			prepareMessage(self, "premsg_Spells_exodar", spellId, sourceName)
		end
	elseif spellId == 49360 then --Терамор
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnPortal then
			prepareMessage(self, "premsg_Spells_theramore", spellId, sourceName)
		end
	elseif spellId == 11417 then --Оргриммар
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnPortal then
			prepareMessage(self, "premsg_Spells_orgrimmar", spellId, sourceName)
		end
	elseif spellId == 11418 then --Подгород
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnPortal then
			prepareMessage(self, "premsg_Spells_undercity", spellId, sourceName)
		end
	elseif spellId == 11420 then --Громовой утес
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnPortal then
			prepareMessage(self, "premsg_Spells_thunderBluff", spellId, sourceName)
		end
	elseif spellId == 32267 then --Луносвет
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnPortal then
			prepareMessage(self, "premsg_Spells_silvermoon", spellId, sourceName)
		end
	elseif spellId == 49361 then --Каменор
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnPortal then
			prepareMessage(self, "premsg_Spells_stonard", spellId, sourceName)
		end
	elseif spellId == 33691 then --Шаттрат
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnPortal then
			prepareMessage(self, "premsg_Spells_shattrath", spellId, sourceName)
		end
	elseif spellId == 53142 then --Даларан1
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnPortal then
			prepareMessage(self, "premsg_Spells_dalaran1", spellId, sourceName)
		end
	elseif spellId == 88345 then --Тол Барад (альянс)
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnPortal then
			prepareMessage(self, "premsg_Spells_tolBarad1", spellId, sourceName)
		end
	elseif spellId == 88346 then --Тол Барад (орда)
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnPortal then
			prepareMessage(self, "premsg_Spells_tolBarad2", spellId, sourceName)
		end
	elseif spellId == 132620 then --Вечноцветущий дол (альянс)
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnPortal then
			prepareMessage(self, "premsg_Spells_valeEternal1", spellId, sourceName)
		end
	elseif spellId == 132626 then --Вечноцветущий дол (орда)
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnPortal then
			prepareMessage(self, "premsg_Spells_valeEternal2", spellId, sourceName)
		end
	elseif spellId == 176246 then --Преграда Ветров (альянс)
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnPortal then
			prepareMessage(self, "premsg_Spells_stormshield", spellId, sourceName)
		end
	elseif spellId == 176244 then --Копье Войны (орда)
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnPortal then
			prepareMessage(self, "premsg_Spells_warspear", spellId, sourceName)
		end
	elseif spellId == 224871 then --Даларан2
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnPortal then
			prepareMessage(self, "premsg_Spells_dalaran2", spellId, sourceName)
		end]]
	elseif spellId == 29893 and self:AntiSpam(10, "soulwell") then --Источник душ
	--[[	if self.Options.YellOnSoulwell then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnSoulwell then
			prepareMessage(self, "premsg_Spells_soulwell", spellId, sourceName)
		end]]
		DBM:AddMsg(L.SpellFound:format(sourceName, spellName))
	elseif spellId == 83958 and self:AntiSpam(5, "bank") then --Мобильный банк
		if args:IsPlayerSource() then
			yellMobileBanking:Yell(SpellLinks(spellId))
		else
			warnMobileBanking:Show(sourceName, spellName)
		end
	elseif spellId == 161399 then --Поменяться местами
		if typeInstance ~= "party" and typeInstance ~= "raid" then return end
	--[[	if self.Options.YellOnToys then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnToys then
			prepareMessage(self, "premsg_Spells_swap", spellId, sourceName, destName)
		end]]
		DBM:AddMsg(L.SpellFound:format(sourceName, spellName))
	elseif spellId == 64901 then --Символ надежды
		if typeInstance ~= "party" and typeInstance ~= "raid" then return end
		if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayerSource() then
			yellSymbolHope:Yell(SpellLinks(spellId))
		end
	--[[	if self.Options.YellOnRaidCooldown then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnRaidCooldown then
			prepareMessage(self, "premsg_Spells_hope", spellId, sourceName)
		end]]
		DBM:AddMsg(L.SpellFound:format(sourceName, spellName))
	elseif spellId == 97462 then --Ободряющий клич
		if typeInstance ~= "party" and typeInstance ~= "raid" then return end
		if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayerSource() then
			yellRallyingCry:Yell(SpellLinks(spellId))
		else
			warnRallyingCry:Show(sourceName, spellName)
		end
	elseif spellId == 62618 then --Слово силы: Барьер
		if typeInstance ~= "party" and typeInstance ~= "raid" then return end
		if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayerSource() then
			yellPowerWordBarrier:Yell(SpellLinks(spellId))
		else
			warnPowerWordBarrier:Show(sourceName, spellName)
		end
	elseif spellId == 740 then --Спокойствие
		if typeInstance ~= "party" and typeInstance ~= "raid" then return end
		if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayerSource() then
			yellTranquility:Yell(SpellLinks(spellId))
		else
			warnTranquility:Show(sourceName, spellName)
		end
	elseif spellId == 64843 then --Божественный гимн
		if typeInstance ~= "party" and typeInstance ~= "raid" then return end
		if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayerSource() then
			yellDivineHymn:Yell(SpellLinks(spellId))
		else
			warnDivineHymn:Show(sourceName, spellName)
		end
	elseif spellId == 363534 then --Перемотка
		if typeInstance ~= "party" and typeInstance ~= "raid" then return end
		if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayerSource() then
			yellRewind:Yell(SpellLinks(spellId))
		else
			warnRewind:Show(sourceName, spellName)
		end
	elseif spellId == 20484 then --Возрождение
		if typeInstance ~= "party" and typeInstance ~= "raid" then return end
		if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayer() then
			specWarnRebirth:Show()
			specWarnRebirth:Play("targetyou")
		else
			warnRebirth:Show(sourceName, Rebirth, destName)
		end
	elseif spellId == 61999 then --Воскрешение союзника
		if typeInstance ~= "party" and typeInstance ~= "raid" then return end
		if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayer() then
			specWarnRebirth:Show()
			specWarnRebirth:Play("targetyou")
		else
			warnRebirth:Show(sourceName, Rebirth, destName)
		end
	elseif spellId == 95750 then --Воскрешение камнем души
		if typeInstance ~= "party" and typeInstance ~= "raid" then return end
		if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayer() then
			specWarnRebirth:Show()
			specWarnRebirth:Play("targetyou")
		else
			warnRebirth:Show(sourceName, Rebirth, destName)
		end
	elseif spellId == 385403 then --Тангенциальный корректор жизненной силы
		if typeInstance ~= "party" and typeInstance ~= "raid" then return end
		if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayer() then
			specWarnRebirth:Show()
			specWarnRebirth:Play("targetyou")
		else
			warnRebirth:Show(sourceName, Rebirth, destName)
		end
	elseif spellId == 391054 then --Заступничество
		if typeInstance ~= "party" and typeInstance ~= "raid" then return end
		if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayer() then
			specWarnRebirth:Show()
			specWarnRebirth:Play("targetyou")
		else
			warnRebirth:Show(sourceName, Rebirth, destName)
		end
	elseif spellId == 61994 then --Ритуал призыва
		if self.Options.YellOnSummoning then
			if args:IsPlayerSource() and self:AntiSpam(2, "RitualSummoning") then
				smartAss(L.SoulstoneYell:format(DbmRV, sourceName, SpellLinks(7720), UnitName("target")))
			end
		end
	elseif spellId == 31821 then --Владение аурами
		if args:IsPlayerSource() then
			yellAuraMastery:Yell(SpellLinks(spellId))
		end
	elseif spellId == 391776 then --Шкафчик с множеством плащей
		if typeInstance ~= "party" and typeInstance ~= "raid" then return end
		if self.Options.YellOnToys then
			if args:IsPlayerSource() then
				yellEndlessCloaks:Yell(SpellLinks(spellId))
			else
				warnEndlessCloaks:Show(sourceName, spellName)
			end
		end
		timerEndlessCloaks:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	local sourceName = args.sourceName
	local destName = args.destName
	spellName = DBM:GetSpellInfo(spellId)
	if not UnitInYourParty(sourceName) then return end
	typeInstance = select(2, IsInInstance())
	if typeInstance ~= "party" and typeInstance ~= "raid" then return end
	if DBM:GetNumRealGroupMembers() < 2 then return end
	if spellId == 20707 then --Камень души
	--	if typeInstance ~= "party" and typeInstance ~= "raid" then return end
	--	if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayer() then
			specWarnSoulstone:Show()
			specWarnSoulstone:Play("targetyou")
		else
			warnSoulstone:Show(destName)
		end
	--[[	if self.Options.YellOnSoulstone then
			prepareMessage(self, "premsg_Spells_soulstone", spellId, sourceName, destName)
		end]]
	elseif spellId == 29166 then --Озарение
	--	if typeInstance ~= "party" and typeInstance ~= "raid" then return end
	--	if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayer() and self:IsHealer() then
			specWarnInnervate:Show()
			specWarnInnervate:Play("targetyou")
		end
	elseif spellId == 64901 then --Символ надежды
	--	if typeInstance ~= "party" and typeInstance ~= "raid" then return end
	--	if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayer() and self:IsHealer() then
			specWarnSymbolHope:Show()
			specWarnSymbolHope:Play("targetyou")
		end
	elseif spellId == 33206 then --Подавление боли
	--	if typeInstance ~= "party" and typeInstance ~= "raid" then return end
	--	if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayer() then
			specWarnPainSuppression:Show()
			specWarnPainSuppression:Play("targetyou")
		end
	elseif spellId == 357170 then --Растяжение времени
	--	if typeInstance ~= "party" and typeInstance ~= "raid" then return end
	--	if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayer() then
			specWarnTimeDilation:Show()
			specWarnTimeDilation:Play("targetyou")
		end
	elseif spellId == 116849 then --Исцеляющий кокон
	--	if typeInstance ~= "party" and typeInstance ~= "raid" then return end
	--	if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayer() then
			specWarnLifeCocoon:Show()
			specWarnLifeCocoon:Play("targetyou")
		end
	elseif spellId == 1022 then --Благословение защиты
	--	if typeInstance ~= "party" and typeInstance ~= "raid" then return end
	--	if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayer() then
			specWarnBlessingofProtection:Show()
			specWarnBlessingofProtection:Play("targetyou")
		end
	elseif spellId == 47788 then --Оберегающий дух
	--	if typeInstance ~= "party" and typeInstance ~= "raid" then return end
	--	if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayer() then
			specWarnGuardianSpirit:Show()
			specWarnGuardianSpirit:Play("targetyou")
		end
	elseif spellId == 10060 then --Придание сил
	--	if typeInstance ~= "party" and typeInstance ~= "raid" then return end
	--	if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayer() then
			specWarnPowerInfusion:Show()
			specWarnPowerInfusion:Play("targetyou")
		end
	elseif spellId == 369459 and self:AntiSpam(5, "SourceofMagic") then --Магический источник
		if args:IsPlayer() then
			specWarnSourceofMagic:Show()
			specWarnSourceofMagic:Play("targetyou")
		end
	elseif spellId == 204018 then --Благословение защиты от заклинаний
	--	if typeInstance ~= "party" and typeInstance ~= "raid" then return end
	--	if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayer() then
			specWarnBlessingSpellwarding:Show()
			specWarnBlessingSpellwarding:Play("targetyou")
		end
	elseif spellId == 6940 then --Жертвенное благословение
	--	if typeInstance ~= "party" and typeInstance ~= "raid" then return end
	--	if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayer() then
			specWarnBlessingSacrifice:Show()
			specWarnBlessingSacrifice:Play("targetyou")
		end
	elseif spellId == 102342 then --Железная кора
	--	if typeInstance ~= "party" and typeInstance ~= "raid" then return end
	--	if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayer() then
			specWarnIronbark:Show()
			specWarnIronbark:Play("targetyou")
		--[[	if not args:IsPlayerSource() and not DBM.Options.IgnoreRaidAnnounce3 then
				smartAss(L.WhisperThanks:format(DbmRV, SpellLinks(spellId)), "whisper", sourceName)
			end]]
		end
	--[[	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnRaidCooldown then
			prepareMessage(self, "premsg_Spells_ironbark", spellId, sourceName, destName)
		end]]
	elseif spellId == 57934 and self:AntiSpam(5, "TrickTheTrade") then --Маленькие хитрости
	--	if typeInstance ~= "party" and typeInstance ~= "raid" then return end
	--	if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayerSource() then
			yellTricksTheTrade:Yell(SpellLinks(spellId), destName)
		elseif args:IsPlayer() then
			warnTricksTheTrade:Show()
		end
	elseif spellId == 34477 and self:AntiSpam(5, "Misdirection") then --Перенаправление
	--	if typeInstance ~= "party" and typeInstance ~= "raid" then return end
	--	if DBM:GetNumRealGroupMembers() < 2 then return end
		if args:IsPlayerSource() then
			yellMisdirection:Yell(SpellLinks(spellId), destName)
		elseif args:IsPlayer() then
			warnMisdirection:Show()
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	local sourceName = args.sourceName
	local destName = args.destName
	if not UnitInYourParty(sourceName) then return end
	if spellId == 29166 then --Озарение
		if args:IsPlayer() and self:IsHealer() then
			specWarnInnervate2:Show()
			specWarnInnervate2:Play("end")
		end
--[[	elseif spellId == 64901 then --Символ надежды
		if args:IsPlayer() and self:IsHealer() then
			specWarnSymbolHope2:Show()
			specWarnSymbolHope2:Play("end")
		end]]
	elseif spellId == 197908 then --Маначай
		if args:IsPlayer() and self:IsHealer() then
			specWarnManaTea2:Show()
			specWarnManaTea2:Play("end")
		end
	end
end

function mod:SPELL_CREATE(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	local sourceName = args.sourceName
	local destName = args.destName
	spellName = DBM:GetSpellInfo(spellId)
	if not UnitInYourParty(sourceName) then return end
	typeInstance = select(2, IsInInstance())
	if typeInstance ~= "party" and typeInstance ~= "raid" then return end
	if DBM:GetNumRealGroupMembers() < 2 then return end
	if spellId == 698 then --Ритуал призыва
		if args:IsPlayerSource() and self:AntiSpam(10, "summoning") then
			yellRitualSummoning:Yell(SpellLinks(spellId))
		else
			warnRitualofSummoning:Show(sourceName, spellName)
		end
	--[[	if self.Options.YellOnRitualofSummoning then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnRitualofSummoning then
			prepareMessage(self, "premsg_Spells_summoning", spellId, sourceName)
		end]]
		DBM:AddMsg(L.SpellFound:format(sourceName, spellName))
--[[	elseif spellId == 188036 and self:AntiSpam(10, "cauldron") then --Котел духов
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnSpiritCauldron then
			prepareMessage(self, "premsg_Spells_cauldron_rw", spellId, sourceName)
		end
	elseif spellId == 201352 and self:AntiSpam(10, "lavishSuramar") then --Щедрое сурамарское угощение
		warnLavishSuramar:Show(sourceName)
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnLavish then
			prepareMessage(self, "premsg_Spells_lavishSuramar_rw", spellId, sourceName)
		end
	elseif spellId == 201351 and self:AntiSpam(10, "hearty") then --Обильное угощение
		warnHearty:Show(sourceName)
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnLavish then
			prepareMessage(self, "premsg_Spells_hearty", spellId, sourceName)
		end
	elseif spellId == 185709 and self:AntiSpam(10, "sugar") then --Угощение из засахаренной рыбы
		warnSugar:Show(sourceName)
		if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnLavish then
			prepareMessage(self, "premsg_Spells_sugar", spellId, sourceName)
		end]]
	elseif spellId == 61031 and self:AntiSpam(10, "toyTrain") then --Игрушечная железная дорога
	--[[	if self.Options.YellOnToys then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnToys then
			prepareMessage(self, "premsg_Spells_toyTrain", spellId, sourceName)
		end]]
		DBM:AddMsg(L.SpellFound:format(sourceName, spellName))
	elseif spellId == 49844 and self:AntiSpam(10, "direbrews") then --пульт управления Худовара
	--[[	if self.Options.YellOnToys then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnToys then
			prepareMessage(self, "premsg_Spells_direbrews", spellId, sourceName)
		end]]
		DBM:AddMsg(L.SpellFound:format(sourceName, spellName))
	elseif spellId == 371515 or spellId == 371519 or spellId == 371521 then --Котел с зельями мощи
--	elseif args:IsSpellID(371515, 371519, 371521) then --Котел с зельями мощи
		if args:IsPlayerSource() and self:AntiSpam(5, "PotionCauldronofPower") then
			yellPotionCauldronofPower:Yell(SpellLinks(371515))
		else
			warnPotionCauldronofPower:Show(sourceName, spellName)
		end
	elseif spellId == 406963 or spellId == 406964 or spellId == 406965 then --Котел с зельями великой мощи
--	elseif args:IsSpellID(406963, 406964, 406965) then --Котел с зельями великой мощи
		if args:IsPlayerSource() and self:AntiSpam(5, "PotionCauldronofPower2") then
			yellPotionCauldronofPower2:Yell(SpellLinks(406963))
		else
			warnPotionCauldronofPower2:Show(sourceName, spellName)
		end
	elseif spellId == 382423 then --Сытная похлебка Юсы
		if args:IsPlayerSource() and self:AntiSpam(5, "YusasHeartyStew") then
			yellYusasHeartyStew:Yell(SpellLinks(spellId))
		else
			warnYusasHeartyStew:Show(sourceName, spellName)
		end
	elseif spellId == 383063 then --Гора драконьих деликатесов
		if args:IsPlayerSource() and self:AntiSpam(5, "DraconicDelicacies") then
			yellDraconicDelicacies:Yell(SpellLinks(381420))
		else
			warnDraconicDelicacies:Show(sourceName, spellName)
		end
	elseif spellId == 382427 then --Большой калуакский банкет
		if args:IsPlayerSource() and self:AntiSpam(5, "GrandBanquet") then
			yellGrandBanquet:Yell(SpellLinks(spellId))
		else
			warnGrandBanquet:Show(sourceName, spellName)
		end
	end
end

function mod:SPELL_SUMMON(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	local sourceName = args.sourceName
	local destName = args.destName
	spellName = DBM:GetSpellInfo(spellId)
	if not UnitInYourParty(sourceName) then return end
	typeInstance = select(2, IsInInstance())
	if typeInstance ~= "party" and typeInstance ~= "raid" then return end
	if DBM:GetNumRealGroupMembers() < 2 then return end
	if spellId == 67826 and self:AntiSpam(10, "jeeves") then --Дживс
		warnJeeves:Show(sourceName, spellName)
	elseif spellId == 199109 and self:AntiSpam(10, "hammer") then --Автоматический молот
		warnAutoHammer:Show(sourceName, spellName)
	elseif spellId == 195782 and self:AntiSpam(5, "moonfeather") then --Призыв статуи лунного совуха
	--[[	if self.Options.YellOnToys then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnToys then
			prepareMessage(self, "premsg_Spells_moonfeather", spellId, sourceName)
		end]]
		DBM:AddMsg(L.SpellFound:format(sourceName, spellName))
	elseif spellId == 98008 then --Тотем духовной связи
		if args:IsPlayerSource() then
			yellSpiritLinkTotem:Yell(SpellLinks(spellId))
		end
	elseif spellId == 207399 then --Тотем защиты Предков
		if args:IsPlayerSource() then
			yellAncestralProtectionTotem:Yell(SpellLinks(spellId))
		else
			warnAncestralProtectionTotem:Show(sourceName, spellName)
		end
	elseif spellId == 256153 then --Портативный трансмогрификатор
		if self.Options.YellOnToys then
			if args:IsPlayerSource() then
				yellRearranger:Yell(SpellLinks(spellId))
			else
				warnRearranger:Show(sourceName, spellName)
			end
		end
		timerRearranger:Start()
	end
end

--[[
function mod:SPELL_RESURRECT(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	local sourceName = args.sourceName
	local destName = args.destName
	if not UnitInYourParty(sourceName) then return end
	if spellId == 95750 then --Воскрешение камнем души
		if self.Options.YellOnResurrect then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnResurrect then
			prepareMessage(self, "premsg_Spells_rebirth3", spellId, sourceName, destName)
		end
		if args:IsPlayer() then
			specWarnRebirth:Show()
			specWarnRebirth:Play("targetyou")
		--	if not DBM.Options.IgnoreRaidAnnounce3 then
				smartAss(L.WhisperThanks:format(DbmRV, SpellLinks(spellId)), "whisper", sourceName)
			end
		end
	elseif spellId == 20484 then --Возрождение
		if self.Options.YellOnResurrect then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnResurrect then
			prepareMessage(self, "premsg_Spells_rebirth1", spellId, sourceName, destName)
		end
		if args:IsPlayer() then
			specWarnRebirth:Show()
			specWarnRebirth:Play("targetyou")
		--	if not DBM.Options.IgnoreRaidAnnounce3 then
				smartAss(L.WhisperThanks:format(DbmRV, SpellLinks(spellId)), "whisper", sourceName)
			end
		end
	elseif spellId == 61999 and self:AntiSpam(2.5, "rebirth") then --Воскрешение союзника
		if self.Options.YellOnResurrect then
	--	if not DBM.Options.IgnoreRaidAnnounce and self.Options.YellOnResurrect then
			prepareMessage(self, "premsg_Spells_rebirth2", spellId, sourceName, destName)
		end
		if args:IsPlayer() then
			specWarnRebirth:Show()
			specWarnRebirth:Play("targetyou")
		--	if not DBM.Options.IgnoreRaidAnnounce3 then
				smartAss(L.WhisperThanks:format(DbmRV, SpellLinks(spellId)), "whisper", sourceName)
			end
		end
	end
end]]

function mod:GOSSIP_SHOW()
	local gossipOptionID = self:GetGossipID()
	if gossipOptionID then
		if gossipOptionID == 55248 or gossipOptionID == 55249 or gossipOptionID == 55250 or gossipOptionID == 55251 or gossipOptionID == 55252 or gossipOptionID == 55253 or gossipOptionID == 106805 or gossipOptionID == 106806 or gossipOptionID == 106807 or gossipOptionID == 106808 or gossipOptionID == 106809 or gossipOptionID == 106810 then
			self:SelectGossip(gossipOptionID)
		end
	end
end

--[[
function mod:LOADING_SCREEN_DISABLED()
	typeInstance = select(2, IsInInstance())
	if typeInstance == "party" or typeInstance == "raid" then return end
--	if not murchalOchkenProshlyapation then murchalOchkenProshlyapation = DBM:GetModByName("MPlusAffixes") end
--	murchalOchkenProshlyapation:ProshlyapOfMurchal()
	DBM:Debug("Murchal proshlyap 3", 2)
end]]

function mod:PLAYER_DEAD()
	if not self.Options.Enabled then return end
	if not IsInInstance() and self.Options.AutoSpirit then
--	if not IsInInstance() and not HasSoulstone() and self.Options.AutoSpirit then
		RepopMe()
	end
end

function mod:OnSync(premsg_announce, sender)
	if not self.Options.Enabled then return end
	if sender < playerOnlyName then
		announceList(premsg_announce, 0)
	end
end
