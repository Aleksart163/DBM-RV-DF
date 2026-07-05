local mod	= DBM:NewMod(2125, "DBM-Party-BfA", 10, 1021)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260630000000")
mod:SetCreatureID(135358, 135359, 135360, 131823, 131824, 131825)--All versions so we can pull boss
mod:SetEncounterID(2113)
mod:DisableESCombatDetection()--ES fires For entryway trash pull sometimes, for some reason.
mod:SetUsedIcons(8)
mod:SetBossHPInfoToHighest()
mod:SetHotfixNoticeRev(20260630000000)
mod:SetMinSyncRevision(20260630000000)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 260773 260741 260699 260700 260701",
	"SPELL_CAST_SUCCESS 260741 260907 260703 268088",
	"SPELL_AURA_APPLIED 260805 260703 260741 260900",
	"SPELL_AURA_REMOVED 260805 268088",
	"UNIT_POWER_UPDATE"
)

--[[
(ability.id = 260741 or ability.id = 260907 or ability.id = 260703) and (type = "begincast" or type = "cast")
 or ability.id = 260805 and (type = "applybuff" or type = "removebuff")
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
--TODO, outlier timer for killing solena last and actually seeing a second soul manipulation before iris ends
--Сестра Брайар
mod:AddTimerLine(DBM:EJ_GetSectionInfo(17738))
local specWarnBrambleBolt			= mod:NewSpecialWarningInterruptCount(260701, "HasInterrupt", nil, nil, 1, 2) --Колючая стрела
local specWarnJaggedNettles			= mod:NewSpecialWarningTarget(260741, "Healer", nil, 2, 1, 2) --Зазубренные стебли
local specWarnJaggedNettles2		= mod:NewSpecialWarningYou(260741, nil, nil, nil, 3, 4) --Зазубренные стебли

local timerJaggedNettlesCD			= mod:NewCDTimer(12.5, 260741, nil, nil, nil, 5, nil, DBM_COMMON_L.HEALER_ICON) --Зазубренные стебли
--Сестра Маладия
mod:AddTimerLine(DBM:EJ_GetSectionInfo(17739))
local warnUnstableMark				= mod:NewTargetAnnounce(260703, 2, nil, nil, 167180) --Нестабильная руническая метка (Бомбы)
local warnAuraofDreadOver			= mod:NewEndAnnounce(268086, 1) --Аура ужаса

local specWarnRuinousBolt			= mod:NewSpecialWarningInterruptCount(260700, "HasInterrupt", nil, nil, 1, 2) --Губительная стрела
local specWarnUnstableMark			= mod:NewSpecialWarningMoveAway(260703, nil, 174716, nil, 1, 2) --Нестабильная руническая метка (Бомба)
local specWarnAuraofDread			= mod:NewSpecialWarningKeepMove(268086, nil, nil, nil, 1, 2) --Аура ужаса

local timerUnstableRunicMarkCD		= mod:NewCDTimer(12.5, 260703, 167180, nil, nil, 3, nil, DBM_COMMON_L.CURSE_ICON) --Нестабильная руническая метка (Бомбы)

mod:AddRangeFrameOption(6, 260703)
--Сестра Солена
mod:AddTimerLine(DBM:EJ_GetSectionInfo(17740))
local specWarnSoulBolt				= mod:NewSpecialWarningInterruptCount(260699, "HasInterrupt", nil, nil, 1, 2) --Стрела души
local specWarnSoulManipulation		= mod:NewSpecialWarningSwitch(260907, nil, nil, nil, 1, 2) --Управление душой

local timerSoulManipulationCD		= mod:NewCDTimer(12.5, 260907, nil, nil, nil, 3, nil, DBM_COMMON_L.TANK_ICON) --Управление душой Always tank? if not, remove tank icon
--Радужный кристалл
mod:AddTimerLine(DBM:GetSpellName(260805))
local warnActiveTriad				= mod:NewTargetNoFilterAnnounce(260805, 2, nil, nil, 178776) --Радужный кристалл (Руна мощи)

local specWarnRitual				= mod:NewSpecialWarningDefensive(260773, nil, nil, nil, 3, 4) --Ужасный ритуал
local specWarnRitual2				= mod:NewSpecialWarningSoon(260773, nil, nil, nil, 2, 4) --Ужасный ритуал

local timerRitualCD					= mod:NewCDTimer(75, 260773, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Ужасный ритуал
local timerRitualCast				= mod:NewCastTimer(5, 260773, nil, nil, nil, 7, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Ужасный ритуал

local yellJaggedNettles				= mod:NewShortYell(260741, nil, nil, nil, "YELL") --Зазубренные стебли
local yellUnstableMark				= mod:NewShortYell(260703, 174716, nil, nil, "YELL") --Нестабильная руническая метка (Бомба)
local yellUnstableMarkFades			= mod:NewShortFadesYell(260703, 174716, nil, nil, "YELL") --Нестабильная руническая метка (Бомба)

mod:AddSetIconOption("SetIconOnTriad", 260805, true, 5, {8}) --Радужный кристалл
mod:AddInfoFrameOption(260773, true)

mod.vb.interruptCount = 0
mod.vb.queueCount = 0
local IrisBuff = DBM:GetSpellName(260805) --Радужный кристалл

function mod:NettlesTargetQuestionMark(targetname)
	if not targetname then return end
	if self:AntiSpam(5, targetname) then
		specWarnJaggedNettles:Show(targetname)
		specWarnJaggedNettles:Play("healfull")
	end
end

function mod:OnCombatStart()
	self.vb.interruptCount = 0
	self.vb.queueCount = 0
	if self.Options.InfoFrame then
		DBM.InfoFrame:SetHeader(DBM_CORE_L.INFOFRAME_POWER)
		DBM.InfoFrame:Show(3, "enemypower", 2)
	end
	--Hack so win detection and bosses remaining work with 6 CIDs
	self.vb.bossLeft = 3
	self.numBoss = 3
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 260773 then
		specWarnRitual:Show()
		specWarnRitual:Play("aesoon")
		timerRitualCast:Start()
	elseif spellId == 260741 then
		--People say LW warns this faster, but is target scanning actually accurate?
		--My logs showed this spell was not a good candidate for target scanning, but maybe it merits more testing.
		--Below shows that sparty was target at start of cast, Omega was target at the end of cast, but the spell didn't go on EITHER ONE of them
		--"<48.98 23:48:04> [UNIT_SPELLCAST_START] Sister Briar(Sparty) - Jagged Nettles - 2s [[boss3:Cast-3-3882-1862-7607-260741-000A7796F4:260741]]", -- [651]
		--"<51.01 23:48:06> [UNIT_SPELLCAST_SUCCEEDED] Sister Briar(Omegall) -Jagged Nettles- [[boss3:Cast-3-3882-1862-7607-260741-000A7796F4]]", -- [678]
		--"<51.01 23:48:06> [CLEU] SPELL_CAST_SUCCESS#Creature-0-3882-1862-7607-131825-00007795D8#Sister Briar#Player-60-0BA0A53F#Lethorr#260741#Jagged Nettles#nil#nil", -- [681]
		--"<51.02 23:48:06> [CLEU] SPELL_DAMAGE#Creature-0-3882-1862-7607-131825-00007795D8#Sister Briar#Player-60-0BA0A53F#Lethorr#260741#Jagged Nettles", -- [682]
		--I guess if it starts spitting out random wrong targets, i'll hear about it, so here is to a drycode find out! Maybe the boss looks at a 3rd target mid cast that transcritor missed?
		self:ScheduleMethod(0.1, "BossTargetScanner", args.sourceGUID, "NettlesTargetQuestionMark", 0.1, 7, true)
	elseif spellId == 260699 and self.vb.queueCount == 1 then --Стрела души
		if self.vb.interruptCount == 3 then self.vb.interruptCount = 0 end
		self.vb.interruptCount = self.vb.interruptCount + 1
		local kickCount = self.vb.interruptCount
		specWarnSoulBolt:Show(args.sourceName, kickCount)
		if kickCount == 1 then
			specWarnSoulBolt:Play("kick1r")
		elseif kickCount == 2 then
			specWarnSoulBolt:Play("kick2r")
		elseif kickCount == 3 then
			specWarnSoulBolt:Play("kick3r")
		end
	--	if self:CheckInterruptFilter(args.sourceGUID, false, true) then
	--		specWarnSoulBolt:Show(args.sourceName)
	--		specWarnSoulBolt:Play("kickcast")
	--	end
		DBM:Debug("Murchal proshlyap (Каст Стрелы души)", 2)
	elseif spellId == 260700 and self.vb.queueCount == 2 then --Губительная стрела
		if self.vb.interruptCount == 3 then self.vb.interruptCount = 0 end
		self.vb.interruptCount = self.vb.interruptCount + 1
		local kickCount = self.vb.interruptCount
		specWarnRuinousBolt:Show(args.sourceName, kickCount)
		if kickCount == 1 then
			specWarnRuinousBolt:Play("kick1r")
		elseif kickCount == 2 then
			specWarnRuinousBolt:Play("kick2r")
		elseif kickCount == 3 then
			specWarnRuinousBolt:Play("kick3r")
		end
	--	if self:CheckInterruptFilter(args.sourceGUID, false, true) then
	--		specWarnRuinousBolt:Show(args.sourceName)
	--		specWarnRuinousBolt:Play("kickcast")
	--	end
		DBM:Debug("Murchal proshlyap (Каст Губительной стрелы)", 2)
	elseif spellId == 260701 and self.vb.queueCount == 3 then --Колючая стрела
		if self.vb.interruptCount == 3 then self.vb.interruptCount = 0 end
		self.vb.interruptCount = self.vb.interruptCount + 1
		local kickCount = self.vb.interruptCount
		specWarnBrambleBolt:Show(args.sourceName, kickCount)
		if kickCount == 1 then
			specWarnBrambleBolt:Play("kick1r")
		elseif kickCount == 2 then
			specWarnBrambleBolt:Play("kick2r")
		elseif kickCount == 3 then
			specWarnBrambleBolt:Play("kick3r")
		end
	--	if self:CheckInterruptFilter(args.sourceGUID, false, true) then
	--		specWarnBrambleBolt:Show(args.sourceName)
	--		specWarnBrambleBolt:Play("kickcast")
	--	end
		DBM:Debug("Murchal proshlyap (Каст Колючей стрелы)", 2)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 260741 then
		--Prevent timer from starting if Cast start started before transfer of power, but Iris sister changed by time fast finished
		local bossUnitID = self:GetUnitIdFromGUID(args.sourceGUID)
		if bossUnitID and not DBM:UnitBuff(bossUnitID, IrisBuff) and not DBM:UnitDebuff(bossUnitID, IrisBuff) then
			timerJaggedNettlesCD:Start(nil, args.sourceGUID)--12.5, Time until cast START
		end
	--[[elseif spellId == 260907 then
		--Prevent timer from starting if Cast start started before transfer of power, but Iris sister changed by time fast finished
		local bossUnitID = self:GetUnitIdFromGUID(args.sourceGUID)
		if bossUnitID and not DBM:UnitBuff(bossUnitID, IrisBuff) and not DBM:UnitDebuff(bossUnitID, IrisBuff) then
			timerSoulManipulationCD:Start(nil, args.sourceGUID)--Time until cast SUCCESS
		end--]]
	elseif spellId == 260703 then
		--Prevent timer from starting if Cast start started before transfer of power, but Iris sister changed by time fast finished
		local bossUnitID = self:GetUnitIdFromGUID(args.sourceGUID)
		if bossUnitID and not DBM:UnitBuff(bossUnitID, IrisBuff) and not DBM:UnitDebuff(bossUnitID, IrisBuff) then
			timerUnstableRunicMarkCD:Start(nil, args.sourceGUID)--Time until cast SUCCESS
		end
	elseif spellId == 268088 then
		specWarnAuraofDread:Show()
		specWarnAuraofDread:Play("keepmove")
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 260805 then --Радужный кристалл
		warnActiveTriad:Show(args.destName)
		local cid = self:GetCIDFromGUID(args.destGUID)
		if cid == 135360 or cid == 131825 then --Сестра Брайар
			self.vb.queueCount = 3
			self.vb.interruptCount = 0
			timerJaggedNettlesCD:Start(6.2, args.destGUID)--CAST START (6-9)
		elseif cid == 135358 or cid == 131823 then --Сестра Маладия
			self.vb.queueCount = 2
			self.vb.interruptCount = 0
			timerUnstableRunicMarkCD:Start(8.6, args.destGUID)--CAST SUCCESS (8-10)
			if self.Options.RangeFrame then
				DBM.RangeCheck:Show(6)
			end
		elseif cid == 135359 or cid == 131824 then --Сестра Солена
			self.vb.queueCount = 1
			self.vb.interruptCount = 0
			timerSoulManipulationCD:Start(8, args.destGUID)--CAST START (8-11)
		end
		if self.Options.SetIconOnTriad then
			self:ScanForMobs(args.destGUID, 2, 8, 1, nil, 6, "SetIconOnTriad", nil, nil, nil, true)
		end
	elseif spellId == 260703 then
		warnUnstableMark:CombinedShow(0.3, args.destName)
		if args:IsPlayer() then
			specWarnUnstableMark:Show()
			specWarnUnstableMark:Play("scatter")
			yellUnstableMark:Yell()
			yellUnstableMarkFades:Countdown(spellId)
		end
	elseif spellId == 260741 and self:AntiSpam(3, 3) then
		if args:IsPlayer() then
			specWarnJaggedNettles2:Show()
			specWarnJaggedNettles2:Play("defensive")
			yellJaggedNettles:Yell()
	--	else
	--		specWarnJaggedNettles:Show(args.destName)
	--		specWarnJaggedNettles:Play("healfull")
		end
	elseif spellId == 260900 then --Управление душой
		if not args:IsPlayer() then
			specWarnSoulManipulation:Show()
			specWarnSoulManipulation:Play("findmc")
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 260805 then --Радужный кристалл
		local cid = self:GetCIDFromGUID(args.destGUID)
		if cid == 135360 or cid == 131825 then --Сестра Брайар
			timerRitualCD:Stop(args.destGUID)
			timerJaggedNettlesCD:Stop(args.destGUID)
		elseif cid == 135358 or cid == 131823 then --Сестра Маладия
			timerRitualCD:Stop(args.destGUID)
			timerUnstableRunicMarkCD:Stop(args.destGUID)
			if self.Options.RangeFrame then
				DBM.RangeCheck:Hide()
			end
		elseif cid == 135359 or cid == 131824 then --Сестра Солена
			timerRitualCD:Stop(args.destGUID)
			timerSoulManipulationCD:Stop(args.destGUID)
		end
	elseif spellId == 268088 then --Аура ужаса
		warnAuraofDreadOver:Show()
	end
end

function mod:UNIT_POWER_UPDATE()
	local bossPower1 = UnitPower("boss1") --Сестра Брайар
	local bossPower2 = UnitPower("boss2") --Сестра Солена
	local bossPower3 = UnitPower("boss3") --Сестра Маладия
	if bossPower1 == 90 and self:AntiSpam(2, 1) then
		specWarnRitual2:Show()
		specWarnRitual2:Play("aesoon")
		timerRitualCD:Start(7.5)
	elseif bossPower2 == 90 and self:AntiSpam(2, 2) then
		specWarnRitual2:Show()
		specWarnRitual2:Play("aesoon")
		timerRitualCD:Start(7.5)
	elseif bossPower3 == 90 and self:AntiSpam(2, 3) then
		specWarnRitual2:Show()
		specWarnRitual2:Play("aesoon")
		timerRitualCD:Start(7.5)
	end
end
