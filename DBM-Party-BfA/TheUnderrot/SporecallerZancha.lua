local mod	= DBM:NewMod(2130, "DBM-Party-BfA", 8, 1022)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240622070000")
mod:SetCreatureID(131383)
mod:SetEncounterID(2112)
mod:SetHotfixNoticeRev(20240623070000)
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 259732 272457",
	"SPELL_CAST_SUCCESS 259718 259732",--273285
	"SPELL_AURA_APPLIED 259718",
	"SPELL_AURA_REMOVED 259718",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

--TODO, re-evalulate all timers from DF M+ logs
--[[
(ability.id = 259732 or ability.id = 272457) and type = "begincast"
 or (ability.id = 259830 or ability.id = 259718 or ability.id = 259732 or ability.id = 273285) and type = "cast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
--local warnBoundlessrot				= mod:NewSpellAnnounce(259830, 3)--Use if too spammy as special warning
local warnUpheaval					= mod:NewTargetNoFilterAnnounce(259718, 3) --Дрожь земли
local warnFungistorm				= mod:NewSpellAnnounce(330422, 3) --Грибошторм

local specWarnFungistorm			= mod:NewSpecialWarningDodge(330422, nil, nil, nil, 2, 2) --Грибошторм
local specWarnFesteringHarvest		= mod:NewSpecialWarningCount(259732, nil, nil, nil, 2, 2) --Гниющий урожай
local specWarnShockwave				= mod:NewSpecialWarningDefensive(272457, "Tank", nil, nil, 3, 4) --Ударная волна
local specWarnUpheaval				= mod:NewSpecialWarningMoveTo(259718, nil, nil, nil, 4, 2) --Дрожь земли

local timerFesteringHarvestCD		= mod:NewCDCountTimer(55.5, 259732, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Гниющий урожай
local timerFungistormCD				= mod:NewCDTimer(21.5, 330422, nil, nil, nil, 7, nil, nil, nil, 2, 3) --Грибошторм
local timerShockwaveCD				= mod:NewCDTimer(60, 272457, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON) --Ударная волна
local timerUpheavalCD				= mod:NewCDTimer(60, 259718, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Дрожь земли

local yellUpheaval					= mod:NewShortYell(259718, nil, nil, nil, "YELL") --Дрожь земли
local yellUpheavalFades				= mod:NewShortFadesYell(259718, nil, nil, nil, "YELL") --Дрожь земли

mod.vb.festeringCount = 0
mod.vb.shockwaveCount = 0
mod.vb.upheavalCount = 0
mod.vb.murchalOchkenProshlyapationCount = 0

local Spores = DBM:GetSpellName(80564)
local MurchalOchkenProshlyapationTimers = {21.5, 30, 30, 32, 30, 30, 30, 30, 31.5, 30}

local function startProshlyapationOfMurchal(self) -- Proshlyapation of Murchal
	self.vb.murchalOchkenProshlyapationCount = self.vb.murchalOchkenProshlyapationCount + 1
	local proshlyap1 = MurchalOchkenProshlyapationTimers[self.vb.murchalOchkenProshlyapationCount+1]
	if proshlyap1 then
		timerFungistormCD:Start(proshlyap1, self.vb.murchalOchkenProshlyapationCount+1)
		self:Schedule(proshlyap1, startProshlyapationOfMurchal, self)
	end
	warnFungistorm:Show()
	specWarnFungistorm:Schedule(2)
	specWarnFungistorm:ScheduleVoice(2, "watchstep")
end

local allProshlyapationsOfMurchal = {
	--Гниющий урожай
	[259732] = {51.7, 55.2, 54.7, 54, 55.4},
	--Ударная волна
	[272457] = {9.9, 14.7, 14.6, 17.7, 14.6, 14.6, 14.6, 14.6, 14.6, 14.6, 14.6, 14.7, 14.6, 14.6, 14.6, 14.6, 14.6, 14.6, 14.6, 14.5},
	--Дрожь земли
	[259718] = {16.9, 20, 21.3, 20, 20, 20, 20, 20, 20, 20, 20.9, 20, 20, 20, 20},
}

function mod:OnCombatStart(delay)
	self.vb.festeringCount = 0
	self.vb.shockwaveCount = 0
	self.vb.upheavalCount = 0
	self.vb.murchalOchkenProshlyapationCount = 0
	timerShockwaveCD:Start(9.9-delay)
	timerUpheavalCD:Start(16.9-delay)
	if not self:IsNormal() then
		timerFungistormCD:Start(21.5-delay, 1)
		self:Schedule(21.5, startProshlyapationOfMurchal, self)
	end
	timerFesteringHarvestCD:Start(51.7-delay, 1)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 259732 then --Гниющий урожай
		self.vb.festeringCount = self.vb.festeringCount + 1
		specWarnFesteringHarvest:Show(self.vb.festeringCount)
		specWarnFesteringHarvest:Play("defensive")
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.festeringCount+1)
		if timer then
			timerFesteringHarvestCD:Start(timer, self.vb.festeringCount+1)
		end
	elseif spellId == 272457 then --Ударная волна
		self.vb.shockwaveCount = self.vb.shockwaveCount + 1
		specWarnShockwave:Show()
		specWarnShockwave:Play("shockwave")
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.shockwaveCount+1)
		if timer then
			timerShockwaveCD:Start(timer, self.vb.shockwaveCount+1)
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 259718 and self:AntiSpam(3, 1) then --Дрожь земли
		self.vb.upheavalCount = self.vb.upheavalCount + 1
		if self:IsMythic() then
			local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.upheavalCount+1)
			if timer then
				timerUpheavalCD:Start(timer, self.vb.upheavalCount+1)
			end
		else
			timerUpheavalCD:Start(15.7)
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 259718 then
		if args:IsPlayer() then
			specWarnUpheaval:Show(Spores)
			specWarnUpheaval:Play("runout")
			yellUpheaval:Yell()
			yellUpheavalFades:Countdown(6)
		else
			warnUpheaval:CombinedShow(0.3, args.destName)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 259718 and args:IsPlayer() then
		yellUpheavalFades:Cancel()
	end
end
