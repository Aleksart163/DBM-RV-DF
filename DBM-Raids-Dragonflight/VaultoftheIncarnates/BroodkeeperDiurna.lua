local mod	= DBM:NewMod(2493, "DBM-Raids-Dragonflight", 3, 1200)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240426070000")
mod:SetCreatureID(190245)
mod:SetEncounterID(2614)
mod:SetUsedIcons(8, 7, 6, 5, 4)
mod:SetHotfixNoticeRev(20240426070000)
mod:SetMinSyncRevision(20240426070000)
mod.respawnTime = 30

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 376073 375871 388716 375870 375716 376272 376257 375485 375575 375457 375653 375630 388918 396269 396779 375475",
	"SPELL_CAST_SUCCESS 380175 375870 396269 181113",
	"SPELL_AURA_APPLIED 375889 375829 376073 378782 390561 376272 375475 375620 375879 376330 396264 380483",
	"SPELL_AURA_APPLIED_DOSE 375829 378782 376272 375475 375879",
	"SPELL_AURA_REMOVED 376073 375809 376330 396264",
	"SPELL_AURA_REMOVED_DOSE 375809",
	"SPELL_PERIODIC_DAMAGE 390747",
	"SPELL_PERIODIC_MISSED 390747",
	"UNIT_DIED"
)

--TODO, add https://www.wowhead.com/beta/spell=388644/vicious-thrust ? it's instant cast but maybe a timer? depends how many adds there are. omitting for now to avoid clutter
--TODO, improve auto marking of the priority adds (like mages that need interrupt rotations)?
--TODO, what is range of tremors? does the mob turn while casting it? These answers affect warning defaults/filters, for now it's everyone
--[[
(ability.id = 376073 or ability.id = 375871 or ability.id = 388716 or ability.id = 388918 or ability.id = 375870 or ability.id = 396269 or ability.id = 396779) and type = "begincast"
 or ability.id = 380175 and type = "cast"
 or ability.id = 375879
 or ability.id = 181113
 or (ability.id = 375716 or ability.id = 375653 or ability.id = 375457 or ability.id = 375630 or ability.id = 376257 or ability.id = 375575 or ability.id = 375475 or ability.id = 376272 or ability.id = 375485) and type = "begincast"
--]]
--Stage One: The Primalist Clutch
mod:AddTimerLine(DBM:EJ_GetSectionInfo(25119))
--Broodkeeper Diurna
mod:AddTimerLine(DBM:EJ_GetSectionInfo(25120))

local warnPhase									= mod:NewPhaseChangeAnnounce(2, 2, nil, nil, nil, nil, nil, 2)
local warnGreatstaffsWrath						= mod:NewTargetNoFilterAnnounce(375889, 2) --Гнев великого посоха
local warnClutchwatchersRage					= mod:NewStackAnnounce(375829, 2) --Ярость хранительницы кладки
local warnRapidIncubation						= mod:NewSpellAnnounce(376073, 3) --Ускоренная инкубация
local warnMortalWounds							= mod:NewStackAnnounce(378782, 2, nil, "Tank|Healer") --Смертельное ранение
local warnDiurnasGaze							= mod:NewYouAnnounce(390561, 3) --Пристальный взор Денны
local warnPrimalistReinforcements				= mod:NewSpellAnnounce(-25129, 2) --Подкрепления воинов стихий

local specWarnGreatstaffoftheBroodkeeper		= mod:NewSpecialWarningCount(380175, nil, nil, nil, 2, 2) --Великий посох хранительницы стаи
local specWarnGreatstaffsWrath					= mod:NewSpecialWarningYou(375889, nil, nil, nil, 1, 2) --Гнев великого посоха
local specWarnWildfire							= mod:NewSpecialWarningDodge(375871, nil, nil, nil, 2, 2) --Дикий огонь
local specWarnIcyShroud							= mod:NewSpecialWarningCount(388716, nil, nil, nil, 2, 2) --Ледяной покров
local specWarnStormFissure						= mod:NewSpecialWarningDodge(396779, nil, nil, nil, 2, 2, 4) --Штормовая трещина
local specWarnMortalStoneclaws					= mod:NewSpecialWarningDefensive(375870, nil, nil, nil, 3, 4) --Смертельные каменные когти
local specWarnMortalWounds						= mod:NewSpecialWarningTaunt(378782, nil, nil, nil, 1, 2) --Смертельное ранение
local specWarnGTFO								= mod:NewSpecialWarningGTFO(390747, nil, nil, nil, 1, 8) --Статическое поле

local timerPhaseCD								= mod:NewStageTimer(300)
local timerGreatstaffoftheBroodkeeperCD			= mod:NewCDCountTimer(24.4, 380175, L.staff, nil, nil, 5) --Великий посох хранительницы стаи Shared CD ability?
local timerRapidIncubationCD					= mod:NewCDCountTimer(24.4, 376073, nil, nil, nil, 1) --Ускоренная инкубация Shared CD ability?
local timerWildfireCD							= mod:NewCDCountTimer(21.4, 375871, nil, nil, nil, 3) --Дикий огонь 21.4-28
local timerIcyShroudCD							= mod:NewCDCountTimer(39.1, 388716, nil, nil, nil, 2, nil, DBM_COMMON_L.HEALER_ICON..DBM_COMMON_L.MAGIC_ICON) --Ледяной покров Static CD
local timerMortalStoneclawsCD					= mod:NewCDCountTimer(20.2, 375870, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON) --Смертельные каменные когти Shared CD in P1, 7.3-15 P2
local timerStormFissureCD						= mod:NewCDTimer(24, 396779, nil, nil, nil, 3, nil, DBM_COMMON_L.MYTHIC_ICON) --Штормовая трещина
--local berserkTimer							= mod:NewBerserkTimer(600)

mod:GroupSpells(380175, 375889)--Greatstaff spawn ith greatstaff wrath debuff
mod:GroupSpells(375870, 378782)--Mortal Claws with Mortal Wounds
----Primalist Reinforcements
mod:AddTimerLine(DBM:EJ_GetSectionInfo(25129))
local warnBurrowingStrike						= mod:NewStackAnnounce(376272, 2, nil, "Tank|Healer") --Удар из-под земли
local warnCauterizingFlashflames				= mod:NewCastAnnounce(375485, 4) --Быстрое прижигающее пламя
local warnFlameSentry							= mod:NewCastAnnounce(375575, 3) --Огненный часовой
local warnRendingBite							= mod:NewStackAnnounce(375475, 2, nil, "Tank|Healer") --Разрывающий укус
local warnChillingTantrum						= mod:NewCastAnnounce(375457, 3) --Леденящий гнев
local warnIonizingCharge						= mod:NewTargetAnnounce(375630, 3) --Ионизирующий заряд

local specWarnPrimalistReinforcements			= mod:NewSpecialWarningAddsCount(257554, "-Healer", 245546, nil, 1, 2)
local specWarnIceBarrage						= mod:NewSpecialWarningInterruptCount(375716, "HasInterrupt", nil, nil, 1, 2) --Ледяной обстрел
local specWarnBurrowingStrike					= mod:NewSpecialWarningDefensive(376272, false, nil, 2, 1, 2, 3) --Удар из-под земли Spammy as all hell, should never be on by default
local specWarnTremors							= mod:NewSpecialWarningDodge(376257, nil, nil, nil, 2, 2) --Подземные толчки
local specWarnRendingBite						= mod:NewSpecialWarningDefensive(375475, nil, nil, nil, 1, 2, 3) --Разрывающий укус
local specWarnStaticJolt						= mod:NewSpecialWarningInterruptCount(375653, "HasInterrupt", nil, nil, 1, 2)
local specWarnIonizingCharge					= mod:NewSpecialWarningMoveAway(375630, nil, nil, nil, 1, 2) --Ионизирующий заряд

local timerPrimalistReinforcementsCD			= mod:NewTimer(60, "timerMurchalProshlyapator", 257554, nil, nil, 1, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DAMAGE_ICON) --Прошляп Мурчаля
--local timerPrimalistReinforcementsCD			= mod:NewCDTimer(60, 257554, 245546, nil, nil, 1, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DAMAGE_ICON)
local timerBurrowingStrikeCD					= mod:NewCDNPTimer(8.1, 376272, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.HEROIC_ICON) --Удар из-под земли
local timerTremorsCD							= mod:NewCDNPTimer(11, 376257, nil, nil, nil, 3) --Подземные толчки
local timerCauterizingFlashflamesCD				= mod:NewCDNPTimer(11.7, 375485, nil, "MagicDispeller", nil, 5) --Быстрое прижигающее пламя
local timerFlameSentryCD						= mod:NewCDNPTimer(10.4, 375575, nil, nil, nil, 3) --Огненный часовой
local timerRendingBiteCD						= mod:NewCDNPTimer(11, 375475, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.HEROIC_ICON) --Разрывающий укус
local timerChillingTantrumCD					= mod:NewCDNPTimer(11.1, 375457, nil, nil, nil, 3) --Леденящий гнев
local timerIonizingChargeCD						= mod:NewCDNPTimer(10, 375630, nil, nil, nil, 3) --Ионизирующий заряд

--mod:AddInfoFrameOption(361651, true)
mod:AddNamePlateOption("NPFixate", 376330, true)
mod:AddSetIconOption("SetIconOnMages", "ej25144", true, 0, {6, 5, 4})
mod:AddSetIconOption("SetIconOnStormbringers", "ej25139", true, 0, {8, 7})

mod:GroupSpells(385618, "ej25144", "ej25139")--Icon Marking with general adds announce
--Stage Two: A Broodkeeper Scorned
mod:AddTimerLine(DBM:EJ_GetSectionInfo(25146))
local warnBroodkeepersFury						= mod:NewStackAnnounce(375879, 2) --Неистовство хранительницы стаи
local warnEGreatstaffsWrath						= mod:NewTargetNoFilterAnnounce(380483, 2) --Усиленный гнев великого посоха

local specWarnEGreatstaffoftheBroodkeeper		= mod:NewSpecialWarningCount(380176, nil, nil, nil, 2, 2) --Усиленный посох хранительницы стаи
local specWarnEGreatstaffsWrath					= mod:NewSpecialWarningYou(380483, nil, nil, nil, 1, 2) --Усиленный гнев великого посоха
local specWarnFrozenShroud						= mod:NewSpecialWarningCount(388918, nil, nil, nil, 2, 2) --Морозный покров
local specWarnMortalStoneSlam					= mod:NewSpecialWarningDefensive(396269, nil, nil, nil, 1, 2, 4) --Смертельный каменный удар
local specWarnDetonatingStoneslam				= mod:NewSpecialWarningYou(396264, false, nil, nil, 1, 2, 4)--Bit redundant, so off by default
local specWarnDetonatingStoneslamTaunt			= mod:NewSpecialWarningTaunt(396264, nil, nil, nil, 1, 2, 4)

local timerBroodkeepersFuryCD					= mod:NewNextCountTimer(30, 375879, nil, nil, nil, 5) --Неистовство хранительницы стаи Static CD
--local timerEGreatstaffoftheBroodkeeperCD		= mod:NewCDCountTimer(17, 380176, L.staff, nil, nil, 5)--Shared CD ability
local timerFrozenShroudCD						= mod:NewCDCountTimer(40.5, 388918, nil, nil, nil, 2, nil, DBM_COMMON_L.DAMAGE_ICON..DBM_COMMON_L.HEALER_ICON..DBM_COMMON_L.MAGIC_ICON) --Морозный покров Static CD
local timerMortalStoneSlamCD					= mod:NewCDCountTimer(20.7, 396269, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.MYTHIC_ICON) --Смертельный каменный удар

local yellMortalStoneclaws						= mod:NewShortYell(375870, nil, nil, nil, "YELL") --Смертельные каменные когти
local yellMortalStoneSlam						= mod:NewShortYell(396269, nil, nil, nil, "YELL") --Смертельный каменный удар
local yellGreatstaffsWrath						= mod:NewShortYell(375889, nil, nil, nil, "YELL") --Гнев великого посоха
local yellIonizingCharge						= mod:NewShortYell(375630, nil, nil, nil, "YELL") --Ионизирующий заряд
local yellIonizingCharge2						= mod:NewShortFadesYell(375630, nil, nil, nil, "YELL") --Ионизирующий заряд
local yellEGreatstaffsWrath						= mod:NewShortYell(380483, nil, nil, nil, "YELL") --Усиленный гнев великого посоха
local yellDetonatingStoneslam					= mod:NewShortYell(396264, nil, nil, nil, "YELL")
local yellDetonatingStoneslamFades				= mod:NewShortFadesYell(396264, nil, nil, nil, "YELL")

mod:AddInfoFrameOption("ej25129", true)

mod.vb.staffCount = 0
mod.vb.icyCount = 0
mod.vb.addsCount = 0
mod.vb.tankComboStarted = false
mod.vb.tankCombocount = 0
mod.vb.wildFireCount = 0
mod.vb.incubationCount = 0
mod.vb.murchalProshlyapEggsCount = 0
mod.vb.eggsGone = false

local castsPerGUID = {}
local addUsedMarks = {}
local mythicAddsTimers = {33, 14.7, 48.9, 14.4, 41.1, 18.9, 44.7, 15.3, 41.4, 18.2}
local heroicAddsTimers = {33, 18.2, 40.7, 17.9, 44.9, 14.9, 44.9, 14.9, 39.9, 19.9}
local normalAddsTimers = {33, 18.2, 40.7, 17.9, 44.9, 14.9, 44.9, 14.9, 39.9, 19.9}
local murchalProshlyapationAddCountMythic = {
	["Proshlyapation"] = {L.Right, L.Right, L.Middle, L.Left, L.Right, L.Left, L.Left, L.Left, L.Right, L.Middle}
}
local murchalProshlyapationAddCountHeroic = {
	["Proshlyapation"] = {L.Middle, L.Left, L.Right, L.Right, L.Left, L.Left, L.Right, L.Right, L.Left, L.Left}
}
local murchalProshlyapationAddCountNormal = {
	["Proshlyapation"] = {L.Middle, L.Left, L.Right, L.Right, L.Left, L.Left, L.Right, L.Right, L.Left, L.Left}
}

--[[
15 33 20 170 пулл босса
15 33 47 119 1 треш +6.3 сек = 53419
15 34 05 187 2 треш +6.3 сек

16 17 44 077 3 треш
16 18 02 124 4 треш
16 18 47 156 5 треш
16 19 02 238 6 треш
16 19 47 326 7 треш
16 20 02 380 8 треш
16 20 42 408 9 треш
16 21 02 472 10 треш

]]

function mod:MortalStoneclawsTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnMortalStoneclaws:Show()
		specWarnMortalStoneclaws:Play("defensive")
		yellMortalStoneclaws:Yell()
	end
end

function mod:MortalStoneSlamTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnMortalStoneSlam:Show()
		specWarnMortalStoneSlam:Play("defensive")
		yellMortalStoneSlam:Yell()
	end
end

local function startProshlyapationOfMurchal(self) -- Proshlyapation of Murchal
	self.vb.addsCount = self.vb.addsCount + 1
	local proshlyap = self:IsMythic() and mythicAddsTimers[self.vb.addsCount+1] or self:IsHeroic() and heroicAddsTimers[self.vb.addsCount+1] or self:IsEasy() and normalAddsTimers[self.vb.addsCount+1]
	if proshlyap then
		local text = self:IsMythic() and murchalProshlyapationAddCountMythic["Proshlyapation"][self.vb.addsCount+1] or self:IsHeroic() and murchalProshlyapationAddCountHeroic["Proshlyapation"][self.vb.addsCount+1] or self:IsEasy() and murchalProshlyapationAddCountNormal["Proshlyapation"][self.vb.addsCount+1]
		timerPrimalistReinforcementsCD:Start(proshlyap, text)
		self:Schedule(proshlyap, startProshlyapationOfMurchal, self)
	end
	warnPrimalistReinforcements:Show()
	DBM:AddMsg(L.Tip)
end

local function updateAllTimers(self, ICD, exclusion)
	if not self.Options.ExperimentalTimerCorrection then return end
	DBM:Debug("updateAllTimers running", 3)
	--Abilities that use same timer in P1 and P2
	if timerWildfireCD:GetRemaining(self.vb.wildFireCount+1) < ICD then
		local elapsed, total = timerWildfireCD:GetTime(self.vb.wildFireCount+1)
		local extend = ICD - (total-elapsed)
		DBM:Debug("timerWildfireCD extended by: "..extend, 2)
		timerWildfireCD:Update(elapsed, total+extend, self.vb.wildFireCount+1)
	end
	if self:IsMythic() and timerStormFissureCD:GetRemaining() < ICD then
		local elapsed, total = timerStormFissureCD:GetTime()
		local extend = ICD - (total-elapsed)
		DBM:Debug("timerStormFissureCD extended by: "..extend, 2)
		timerStormFissureCD:Update(elapsed, total+extend)
	end
	--Specific Phase ability timers
	if self:GetStage(1) then
		if not exclusion and timerMortalStoneclawsCD:GetRemaining(self.vb.tankCombocount+1) < ICD then--All difficulties have P1 stoneclaws
			local elapsed, total = timerMortalStoneclawsCD:GetTime(self.vb.tankCombocount+1)
			local extend = ICD - (total-elapsed)
			DBM:Debug("timerMortalStoneclawsCD extended by: "..extend, 2)
			timerMortalStoneclawsCD:Update(elapsed, total+extend, self.vb.tankCombocount+1)
		end
		if timerGreatstaffoftheBroodkeeperCD:GetRemaining(self.vb.staffCount+1) < ICD then
			local elapsed, total = timerGreatstaffoftheBroodkeeperCD:GetTime(self.vb.staffCount+1)
			local extend = ICD - (total-elapsed)
			DBM:Debug("timerGreatstaffoftheBroodkeeperCD extended by: "..extend, 2)
			timerGreatstaffoftheBroodkeeperCD:Update(elapsed, total+extend, self.vb.staffCount+1)
		end
		if timerIcyShroudCD:GetRemaining(self.vb.icyCount+1) < ICD then
			local elapsed, total = timerIcyShroudCD:GetTime(self.vb.icyCount+1)
			local extend = ICD - (total-elapsed)
			DBM:Debug("timerIcyShroudCD extended by: "..extend, 2)
			timerIcyShroudCD:Update(elapsed, total+extend, self.vb.icyCount+1)
		end
	else--Phase 2
		if self:IsMythic() then--Mythic P2 has stoneslam versus stoneclaws
			if not exclusion and timerMortalStoneSlamCD:GetRemaining(self.vb.tankCombocount+1) < ICD then--All difficulties have P1 stoneclaws
				local elapsed, total = timerMortalStoneSlamCD:GetTime(self.vb.tankCombocount+1)
				local extend = ICD - (total-elapsed)
				DBM:Debug("timerMortalStoneSlamCD extended by: "..extend, 2)
				timerMortalStoneSlamCD:Update(elapsed, total+extend, self.vb.tankCombocount+1)
			end
		else
			if not exclusion and timerMortalStoneclawsCD:GetRemaining(self.vb.tankCombocount+1) < ICD then--All difficulties have P1 stoneclaws
				local elapsed, total = timerMortalStoneclawsCD:GetTime(self.vb.tankCombocount+1)
				local extend = ICD - (total-elapsed)
				DBM:Debug("timerMortalStoneclawsCD extended by: "..extend, 2)
				timerMortalStoneclawsCD:Update(elapsed, total+extend, self.vb.tankCombocount+1)
			end
		end
		if timerGreatstaffoftheBroodkeeperCD:GetRemaining(self.vb.staffCount+1) < ICD then
			local elapsed, total = timerGreatstaffoftheBroodkeeperCD:GetTime(self.vb.staffCount+1)
			local extend = ICD - (total-elapsed)
			DBM:Debug("timerGreatstaffoftheBroodkeeperCD extended by: "..extend, 2)
			timerGreatstaffoftheBroodkeeperCD:Update(elapsed, total+extend, self.vb.staffCount+1)
		end
		if timerFrozenShroudCD:GetRemaining(self.vb.icyCount+1) < ICD then
			local elapsed, total = timerFrozenShroudCD:GetTime(self.vb.icyCount+1)
			local extend = ICD - (total-elapsed)
			DBM:Debug("timerFrozenShroudCD extended by: "..extend, 2)
			timerFrozenShroudCD:Update(elapsed, total+extend, self.vb.icyCount+1)
		end
	end
end

local function resetTankComboState(self)
	self.vb.tankComboStarted = false
end

local updateInfoFrame
do
	local lines = {}
	local sortedLines = {}
	local function addLine(key, value)
		lines[key] = value
		sortedLines[#sortedLines + 1] = key
	end
	updateInfoFrame = function()
		table.wipe(lines)
		table.wipe(sortedLines)
		addLine(L.Adds, mod.vb.addsCount.."/10")
		if mod:IsMythic() then
			local nextLocation = murchalProshlyapationAddCountMythic["Proshlyapation"][mod.vb.addsCount+1]
			if nextLocation then
				addLine(L.Next, nextLocation)
			end
		else
			local nextLocation = murchalProshlyapationAddCountHeroic["Proshlyapation"][mod.vb.addsCount+1]
			if nextLocation then
				addLine(L.Next, nextLocation)
			end
		end
		if mod.vb.murchalProshlyapEggsCount > 0 then
			addLine(L.EggsLeft, mod.vb.murchalProshlyapEggsCount)
		end
		return lines, sortedLines
	end
end

function mod:OnCombatStart(delay)
	table.wipe(castsPerGUID)
	table.wipe(addUsedMarks)
	self:SetStage(1)
	self.vb.tankComboStarted = false
	self.vb.tankCombocount = 0
	self.vb.staffCount = 0
	self.vb.icyCount = 0
	self.vb.addsCount = 0
	self.vb.wildFireCount = 0
	self.vb.incubationCount = 0
	self.vb.eggsGone = false
	timerMortalStoneclawsCD:Start(3.2-delay, 1)
	timerWildfireCD:Start(8.2-delay, 1)
	if not self:IsEasy() then
		timerRapidIncubationCD:Start(14.3-delay, 1) --Ускоренная инкубация+
	end
	timerGreatstaffoftheBroodkeeperCD:Start(17.5-delay, 1) --Великий посох (точно под гер)+
	timerIcyShroudCD:Start(27.5-delay, 1) --Ледяной покров+
	if self.Options.NPFixate then
		DBM:FireEvent("BossMod_EnableHostileNameplates")
	end
	if self:IsMythic() then
		timerPhaseCD:Start(-delay)
		self.vb.murchalProshlyapEggsCount = 32
		timerStormFissureCD:Start(28-delay)
		self:Schedule(33, startProshlyapationOfMurchal, self)
		timerPrimalistReinforcementsCD:Start(33, L.Right)
	elseif self:IsHeroic() then
		timerPhaseCD:Start(-delay)
		self.vb.murchalProshlyapEggsCount = 28
		self:Schedule(33, startProshlyapationOfMurchal, self)
		timerPrimalistReinforcementsCD:Start(33, L.Middle)
	else
		timerPhaseCD:Start(301.5-delay)
		self.vb.murchalProshlyapEggsCount = 24
		self:Schedule(33, startProshlyapationOfMurchal, self)
		timerPrimalistReinforcementsCD:Start(33, L.Middle)
	end
	if self.Options.InfoFrame then
		DBM.InfoFrame:SetHeader(DBM:GetSpellInfo(245546))
		DBM.InfoFrame:Show(4, "function", updateInfoFrame, false, false)
	end
end

function mod:OnCombatEnd()
	self:Unschedule(startProshlyapationOfMurchal)
	if self.Options.NPFixate then
		DBM.Nameplate:Hide(true, nil, nil, nil, true, true)
	end
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 376073 then
		self.vb.incubationCount = self.vb.incubationCount + 1
		warnRapidIncubation:Show(self.vb.incubationCount)
		if not self.vb.eggsGone then
			timerRapidIncubationCD:Start(24, self.vb.incubationCount+1)
		end
		updateAllTimers(self, 3)
	elseif spellId == 375871 and self:AntiSpam(10, 1) then
		self.vb.wildFireCount = self.vb.wildFireCount + 1
		specWarnWildfire:Show()
		specWarnWildfire:Play("scatter")
		specWarnWildfire:ScheduleVoice(2, "watchstep")
		timerWildfireCD:Start(self:IsMythic() and 23 or self:IsHeroic() and 21.4 or 22, self.vb.wildFireCount+1)
		if self:IsHard() and self:GetStage(2) then
			updateAllTimers(self, 5)
		else
			updateAllTimers(self, 2.5)
		end
	elseif spellId == 388716 then
		self.vb.icyCount = self.vb.icyCount + 1
		specWarnIcyShroud:Show(self.vb.icyCount)
		specWarnIcyShroud:Play("aesoon")
		timerIcyShroudCD:Start(self:IsMythic() and 41 or self:IsHeroic() and 39.1 or 41.5, self.vb.icyCount+1)
		updateAllTimers(self, 2.5)
	elseif spellId == 388918 then
		self.vb.icyCount = self.vb.icyCount + 1
		specWarnFrozenShroud:Show(self.vb.icyCount)
		specWarnFrozenShroud:Play("aesoon")
		timerFrozenShroudCD:Start(self:IsMythic() and 40.5 or self:IsHeroic() and 39.3 or 40.5, self.vb.icyCount+1)
		updateAllTimers(self, 2.5)
	elseif spellId == 375870 then --Смертельные каменные когти
		self:BossTargetScanner(args.sourceGUID, "MortalStoneclawsTarget", 0.1, 2)
		--Sometimes boss interrupts cast to cast another ability then starts cast over, so we do all this
		if not self.vb.tankComboStarted then
			self.vb.tankComboStarted = true
			self.vb.tankCombocount = self.vb.tankCombocount + 1
			self:Unschedule(resetTankComboState)
			self:Schedule(8, resetTankComboState, self)
		else
			timerMortalStoneclawsCD:Stop()--Don't print cast refreshed before expired for a recast
		end
		local timer = ((self:IsEasy() or self:GetStage(1)) and 22.4 or 7.3)
		timerMortalStoneclawsCD:Start(timer, self.vb.tankCombocount+1)
		updateAllTimers(self, 2, true)
	elseif spellId == 396269 then --Смертельный каменный удар
		self:BossTargetScanner(args.sourceGUID, "MortalStoneSlamTarget", 0.1, 2)
		--Sometimes boss interrupts cast to cast another ability then starts cast over, so we do all this
		if not self.vb.tankComboStarted then
			self.vb.tankComboStarted = true
			self.vb.tankCombocount = self.vb.tankCombocount + 1
			self:Unschedule(resetTankComboState)
			self:Schedule(8, resetTankComboState, self)
		else
			timerMortalStoneSlamCD:Stop()
		end

		timerMortalStoneSlamCD:Start(14, self.vb.tankCombocount+1)
		updateAllTimers(self, 2, true)
	elseif spellId == 376272 then
		if self:IsTanking("player", nil, nil, true, args.sourceGUID) then
			specWarnBurrowingStrike:Show()
			specWarnBurrowingStrike:Play("defensive")
		end
		timerBurrowingStrikeCD:Start(nil, args.sourceGUID)
	elseif spellId == 375475 then
		if self:IsTanking("player", nil, nil, true, args.sourceGUID) then
			specWarnRendingBite:Show()
			specWarnRendingBite:Play("defensive")
		end
		timerRendingBiteCD:Start(nil, args.sourceGUID)
	elseif spellId == 376257 then
		if self:AntiSpam(3, spellId) then
			if self:CheckBossDistance(args.sourceGUID, false, 6450, 18) then
				specWarnTremors:Show()
				specWarnTremors:Play("shockwave")
			end
			timerTremorsCD:Start(nil, args.sourceGUID)
		end
	elseif spellId == 375485 then
		if self:AntiSpam(3, spellId) then
			if self:CheckBossDistance(args.sourceGUID, false, 13289, 28) then
				warnCauterizingFlashflames:Show()
			end
		end
		timerCauterizingFlashflamesCD:Start(self:IsMythic() and 8.6 or 11.7, args.sourceGUID)--TODO, recheck heroic
	elseif spellId == 375575 then
		if self:AntiSpam(3, spellId) then
			if self:CheckBossDistance(args.sourceGUID, false, 13289, 28) then
				warnFlameSentry:Show()
			end
		end
		timerFlameSentryCD:Start(nil, args.sourceGUID)
	elseif spellId == 375457 then
		if self:AntiSpam(3, spellId) then
			warnChillingTantrum:Show()
		end
		timerChillingTantrumCD:Start(nil, args.sourceGUID)
	elseif spellId == 375630 then
		timerIonizingChargeCD:Start(nil, args.sourceGUID)
	elseif spellId == 375716 then
		if not castsPerGUID[args.sourceGUID] then
			castsPerGUID[args.sourceGUID] = 0
			if self.Options.SetIconOnMages then
				for i = 6, 4, -1 do -- 6, 5, 4
					if not addUsedMarks[i] then
						addUsedMarks[i] = args.sourceGUID
						self:ScanForMobs(args.sourceGUID, 2, i, 1, nil, 12, "SetIconOnMages")
						break
					end
				end
			end
		end
		castsPerGUID[args.sourceGUID] = castsPerGUID[args.sourceGUID] + 1
		local count = castsPerGUID[args.sourceGUID]
		if self:CheckInterruptFilter(args.sourceGUID, false, false) then--Count interrupt, so cooldown is not checked
			specWarnIceBarrage:Show(args.sourceName, count)
			if count < 6 then
				specWarnIceBarrage:Play("kick"..count.."r")
			else
				specWarnIceBarrage:Play("kickcast")
			end
		end
	elseif spellId == 375653 then
		if not castsPerGUID[args.sourceGUID] then
			castsPerGUID[args.sourceGUID] = 0
			if self.Options.SetIconOnStormbringers then
				for i = 8, 7, -1 do -- 8, 7
					if not addUsedMarks[i] then
						addUsedMarks[i] = args.sourceGUID
						self:ScanForMobs(args.sourceGUID, 2, i, 1, nil, 12, "SetIconOnStormbringers")
						break
					end
				end
			end
		end
		castsPerGUID[args.sourceGUID] = castsPerGUID[args.sourceGUID] + 1
		local count = castsPerGUID[args.sourceGUID]
		if self:CheckInterruptFilter(args.sourceGUID, false, false) then--Count interrupt, so cooldown is not checked
			specWarnStaticJolt:Show(args.sourceName, count)
			if count < 6 then
				specWarnStaticJolt:Play("kick"..count.."r")
			else
				specWarnStaticJolt:Play("kickcast")
			end
		end
	elseif spellId == 396779 then
		specWarnStormFissure:Show()
		specWarnStormFissure:Play("watchstep")
		timerStormFissureCD:Start()
		updateAllTimers(self, 3)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 380175 then
		self.vb.staffCount = self.vb.staffCount + 1
		local staffTimer
		if self:IsHard() then
			staffTimer = (self.vb.staffCount >= 14) and 17 or 24.3
		else
			staffTimer = (self.vb.staffCount >= 13) and 20 or 24.3
		end
		if self:GetStage(1) then
			specWarnGreatstaffoftheBroodkeeper:Show(self.vb.staffCount)
			specWarnGreatstaffoftheBroodkeeper:Play("specialsoon")
			timerGreatstaffoftheBroodkeeperCD:Start(staffTimer, self.vb.staffCount+1)--24-29 in all difficulties
		else
			specWarnEGreatstaffoftheBroodkeeper:Show(self.vb.staffCount)
			specWarnEGreatstaffoftheBroodkeeper:Play("specialsoon")
			timerGreatstaffoftheBroodkeeperCD:Start(staffTimer, self.vb.staffCount+1)--17-33
		end
		--updateAllTimers(self, 1)
	elseif spellId == 375870 then
		self.vb.tankComboStarted = false
	elseif spellId == 396269 then
		self.vb.tankComboStarted = false
	elseif spellId == 181113 then
		DBM:Debug("Murchal proshlyap", 2)
		local cid = self:GetCIDFromGUID(args.sourceGUID)
		if cid == 191206 then--Mages
			DBM:Debug("Murchal proshlyap 1", 2)
			if not castsPerGUID[args.sourceGUID] then
				castsPerGUID[args.sourceGUID] = 0
				if self.Options.SetIconOnMages then
					for i = 6, 4, -1 do -- 6, 5, 4
						if not addUsedMarks[i] then
							addUsedMarks[i] = args.sourceGUID
							self:ScanForMobs(args.sourceGUID, 2, i, 1, nil, 12, "SetIconOnMages")
							break
						end
					end
				end
			end
		elseif cid == 191232 then--StormBringers
			DBM:Debug("Murchal proshlyap 2", 2)
			if not castsPerGUID[args.sourceGUID] then
				castsPerGUID[args.sourceGUID] = 0
				if self.Options.SetIconOnStormbringers then
					for i = 8, 7, -1 do -- 8, 7
						if not addUsedMarks[i] then
							addUsedMarks[i] = args.sourceGUID
							self:ScanForMobs(args.sourceGUID, 2, i, 1, nil, 12, "SetIconOnStormbringers")
							break
						end
					end
				end
			end
		end
	--[[	if self:AntiSpam(10, 2) then
			self.vb.addsCount = self.vb.addsCount + 1
			specWarnPrimalistReinforcements:Show(self.vb.addsCount)
			specWarnPrimalistReinforcements:Play("killmob")
			local timer = self:IsMythic() and mythicAddsTimers[self.vb.addsCount+1] or self:IsHeroic() and heroicAddsTimers[self.vb.addsCount+1] or self:IsEasy() and normalAddsTimers[self.vb.addsCount+1]
			if timer then
				timerPrimalistReinforcementsCD:Start(timer, self.vb.addsCount+1)
			end
		end]]
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 375889 then
		warnGreatstaffsWrath:CombinedShow(2, args.destName)--Aggregated for now in case strat is to just pop multiple eggs and CD like fuck for Clutchwatcher's Rage
		if args:IsPlayer() then
			specWarnGreatstaffsWrath:Show()
			specWarnGreatstaffsWrath:Play("targetyou")
			yellGreatstaffsWrath:Yell()
		end
	elseif spellId == 380483 then
		warnEGreatstaffsWrath:CombinedShow(2, args.destName)--Aggregated for now in case strat is to just pop multiple eggs and CD like fuck for Clutchwatcher's Rage
		if args:IsPlayer() then
			specWarnEGreatstaffsWrath:Show()
			specWarnEGreatstaffsWrath:Play("targetyou")
			yellEGreatstaffsWrath:Yell()
		end
	elseif spellId == 375620 then
		warnIonizingCharge:CombinedShow(0.3, args.destName)
		if args:IsPlayer() then
			specWarnIonizingCharge:Show()
			specWarnIonizingCharge:Play("range5")
			yellIonizingCharge:Yell()
			yellIonizingCharge2:Countdown(spellId)
		end
	elseif spellId == 396264 then
		if args:IsPlayer() then
			specWarnDetonatingStoneslam:Show()
			specWarnDetonatingStoneslam:Play("gathershare")
			yellDetonatingStoneslam:Yell()
			yellDetonatingStoneslamFades:Countdown(spellId)
		else
			specWarnDetonatingStoneslamTaunt:Show(args.destName)
			specWarnDetonatingStoneslamTaunt:Play("tauntboss")
		end
	elseif spellId == 375829 then
		warnClutchwatchersRage:Cancel()
		warnClutchwatchersRage:Schedule(3, args.destName, args.amount or 1)
	elseif spellId == 376330 then
		if args:IsPlayer() then
			if self.Options.NPFixate then
				DBM.Nameplate:Show(true, args.sourceGUID, spellId)
			end
		end
	elseif spellId == 378782 and not args:IsPlayer() then
		local amount = args.amount or 1
		local _, _, _, _, _, expireTime = DBM:UnitDebuff("player", spellId)
		local remaining
		if expireTime then
			remaining = expireTime-GetTime()
		end
		if self:GetStage(2) and (not remaining or remaining and remaining < 6.1) and not UnitIsDeadOrGhost("player") and not self:IsHealer() then
			specWarnMortalWounds:Show(args.destName)
			specWarnMortalWounds:Play("tauntboss")
		else
			warnMortalWounds:Show(args.destName, amount)
		end
	elseif spellId == 390561 and args:IsPlayer() then
		warnDiurnasGaze:Show()
	elseif spellId == 376272 and not args:IsPlayer() then
		local amount = args.amount or 1
		if amount % 2 == 0 then
			warnBurrowingStrike:Show(args.destName, amount)
		end
	elseif spellId == 375475 and not args:IsPlayer() then
		local amount = args.amount or 1
		warnRendingBite:Show(args.destName, amount)
	elseif spellId == 375879 then --Неистовство хранительницы стаи (фаза 2)
		--Проверить таймер с Морозным покровом, в героике 1-ый каст случился через 6.8 сек--
		local amount = args.amount or 1
		--2 фаза через 5 мин после начала боя?-- 300 сек героик, 301.5 обычка
		if amount == 1 then
			warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(2))
			warnPhase:Play("ptwo")
			self:Unschedule(startProshlyapationOfMurchal)
		else
			warnBroodkeepersFury:Show(args.destName, amount)
		end
		timerBroodkeepersFuryCD:Start(30, amount+1)
		if self:GetStage(2, 1) then
			self:SetStage(2)
			self.vb.wildFireCount = 0
			--Just stop outright
--			timerRapidIncubationCD:Stop()
			timerPrimalistReinforcementsCD:Stop()
			--Timers that do not reset.
			--Mortal Stone Claws, since we don't swap timers, no action needed
			--On mythic mortal claws swaps to mortal slam, doesn't change on heroic and below
			if self:IsMythic() then
				local remainingCombo = timerMortalStoneclawsCD:GetRemaining(self.vb.tankCombocount+1)
				if remainingCombo then
					timerMortalStoneclawsCD:Stop()
					timerMortalStoneclawsCD:Start(remainingCombo, self.vb.tankCombocount+1)--Does NOT restart anymore, even though on mythic it inherits a cast sequence, it still finishes out previous CD
				end
			end
			--Tank timer doesn't reset, just keeps going, staff timer doesn't restart, just swaps to new object
			--local remainingStaff = timerGreatstaffoftheBroodkeeperCD:GetRemaining(self.vb.staffCount+1)
			--if remainingStaff then
			--	timerGreatstaffoftheBroodkeeperCD:Stop()
			--	timerEGreatstaffoftheBroodkeeperCD:Start(remainingStaff, self.vb.staffCount+1)--Does NOT restart anymore, even though on mythic it inherits a cast sequence, it still finishes out previous CD
			--end
			local remainingIcy = timerGreatstaffoftheBroodkeeperCD:GetRemaining(self.vb.icyCount+1)
			if remainingIcy then
				timerIcyShroudCD:Stop()
				timerFrozenShroudCD:Start(remainingIcy, 1)
			end
			self.vb.icyCount = 0--Reused for frozen shroud
		end
		if self.Options.InfoFrame then
			DBM.InfoFrame:Hide()
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 375809 then
		self.vb.murchalProshlyapEggsCount = self.vb.murchalProshlyapEggsCount - 1
		if self.vb.murchalProshlyapEggsCount == 0 then
			self.vb.eggsGone = true
		end
	elseif spellId == 376330 then
		if args:IsPlayer() then
			if self.Options.NPFixate then
				DBM.Nameplate:Hide(true, args.sourceGUID, spellId)
			end
		end
	elseif spellId == 396264 then
		if args:IsPlayer() then
			yellDetonatingStoneslamFades:Cancel()
		end
	end
end
mod.SPELL_AURA_REMOVED_DOSE = mod.SPELL_AURA_REMOVED

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 191225 then--Tarasek Earthreaver
		timerBurrowingStrikeCD:Stop(args.destGUID)
		timerTremorsCD:Stop(args.destGUID)
	elseif cid == 192771 or cid == 191230 then--Dragonspawn Flamebender
		timerCauterizingFlashflamesCD:Stop(args.destGUID)
		timerFlameSentryCD:Stop(args.destGUID)
	elseif cid == 191222 then--Juvenile Frost Proto-Dragon
		timerRendingBiteCD:Stop(args.destGUID)
		timerChillingTantrumCD:Stop(args.destGUID)
	elseif cid == 191206 then--Primalist Mage
		for i = 6, 4, -1 do -- 6, 5, 4
			if addUsedMarks[i] == args.destGUID then
				addUsedMarks[i] = nil
				return
			end
		end
	elseif cid == 191232 then--Drakonid Stormbringer
		timerIonizingChargeCD:Stop(args.destGUID)
		for i = 8, 7, -1 do -- 8, 7
			if addUsedMarks[i] == args.destGUID then
				addUsedMarks[i] = nil
				break
			end
		end
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 390747 and destGUID == UnitGUID("player") and self:AntiSpam(2, 4) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
