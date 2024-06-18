local mod	= DBM:NewMod(1665, "DBM-Party-Legion", 5, 767)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240106080507")
mod:SetCreatureID(91004)
mod:SetEncounterID(1791)
mod:SetHotfixNoticeRev(20240617070000)
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 198496 198428 193375",
--	"SPELL_CAST_SUCCESS 216290",
	"UNIT_DIED",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

--[[
(ability.id = 198496 or ability.id = 198428 or ability.id = 193375) and type = "begincast"
 or ability.id = 216290 and type = "cast"
  or (source.type = "NPC" and source.firstSeen = timestamp) and source.id = 100818 or (target.type = "NPC" and target.firstSeen = timestamp) and target.id = 100818
 or target.id = 100818 and type = "death"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
--local warnStrikeofMountain			= mod:NewTargetNoFilterAnnounce(216290, 2) --Удар горы
local warnBellowofDeeps				= mod:NewSpellAnnounce(193375, 2) --Рев глубин Change to special warning if they become important enough to switch to
local warnStanceofMountain			= mod:NewFadesAnnounce(198509, 1) --Горная стойка

local specWarnStanceofMountain		= mod:NewSpecialWarningCount(198509, nil, nil, nil, 1, 2) --Горная стойка
local specWarnSunder				= mod:NewSpecialWarningDefensive(198496, nil, nil, 2, 3, 2) --Раскол
local specWarnStrikeofMountain		= mod:NewSpecialWarningDodge(216290, nil, nil, nil, 2, 2) --Удар горы

local timerStanceOfMountainCD		= mod:NewCDCountTimer(52, 198509, nil, nil, nil, 7, nil, nil, nil, 3, 5) --Горная стойка
local timerStanceOfMountain			= mod:NewRPTimer(19.2, nil, nil, nil, nil, 6, nil, nil, nil, 3, 5) --Горная стойка
local timerSunderCD					= mod:NewCDCountTimer(30, 198496, nil, "Tank", nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON) --Раскол
local timerStrikeCD					= mod:NewCDCountTimer(30, 216290, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Удар горы
local timerBelowofDeepsCD			= mod:NewCDCountTimer(30, 193375, nil, nil, nil, 1, nil, DBM_COMMON_L.DAMAGE_ICON) --Рев глубин

mod.vb.stanceCount = 0
mod.vb.totemsAlive = 0
mod.vb.sunderCount = 0
mod.vb.strikeCount = 0
mod.vb.phase = 1

local allProshlyapationsOfMurchal = {
	[1] = {
		--Раскол
		[198496] = {8, 10, 10, 10, 11.1},
		--удар горы
		[198428] = {16, 16, 16},
	},
	[2] = {
		--Раскол
		[198496] = {8, 10, 10, 10},
		--удар горы
		[198428] = {16, 16},
	},
}

function mod:OnCombatStart(delay)
	self.vb.phase = 1
	self.vb.strikeCount = 0
	self.vb.sunderCount = 0
	self.vb.stanceCount = 0
	timerSunderCD:Start(8-delay, 1)
	timerStrikeCD:Start(16-delay, 1)
	timerBelowofDeepsCD:Start(20-delay, 1)
	timerStanceOfMountainCD:Start(60-delay, 1)
	if self:IsHard() then
		self.vb.totemsAlive = 5
	else
		self.vb.totemsAlive = 3
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 198496 then --Раскол
		self.vb.sunderCount = self.vb.sunderCount + 1
		if self:IsTanking("player", "boss1", nil, true) then
			specWarnSunder:Show()
			specWarnSunder:Play("defensive")
		end
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, self.vb.phase, spellId, self.vb.sunderCount+1)
		if timer then
			timerSunderCD:Start(timer, self.vb.sunderCount+1)
		end
	elseif spellId == 198428 then --Удар горы
		self.vb.strikeCount = self.vb.strikeCount + 1
		specWarnStrikeofMountain:Show()
		specWarnStrikeofMountain:Play("watchstep")
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, self.vb.phase, spellId, self.vb.strikeCount+1)
		if timer then
			timerStrikeCD:Start(timer, self.vb.strikeCount+1)
		end
	elseif spellId == 193375 then --Рев глубин
		warnBellowofDeeps:Show()
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 100818 then
		self.vb.totemsAlive = self.vb.totemsAlive - 1
		if self.vb.totemsAlive == 0 then
			warnStanceofMountain:Show()
			timerStanceOfMountainCD:Start(nil, self.vb.stanceCount+1)
			timerSunderCD:Start(8, 1)
			timerStrikeCD:Start(16, 1)
			timerBelowofDeepsCD:Start(20, 1)
		end
	end
end
		
--[[
function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 216290 then
		if args:IsPlayer() then
			specWarnStrikeofMountain:Show()
			specWarnStrikeofMountain:Play("targetyou")
			yellStrikeofMountain:Yell()
		else
			warnStrikeofMountain:Show(args.destName)
		end
	end
end
--]]

--"<430.63 21:52:24> [ENCOUNTER_START] 1791#Ularogg Cragshaper#8#5", -- [3535]
--"<490.86 21:53:24> [UNIT_SPELLCAST_SUCCEEDED] Ularogg Cragshaper(53.1%-0.0%){Target:Gimlly} -Stance of the Mountain- [[boss1:Cast-3-4249-1458-17779-198509-0011F25FB4:198509]]", -- [3764]
--"<490.86 21:53:24> [DBM_Announce] Stance of the Mountain#136182#spell#216249#1665#false", -- [3765]
--"<519.03 21:53:52> [UNIT_SPELLCAST_SUCCEEDED] Ularogg Cragshaper(50.7%-0.0%){Target:??} -Stance of the Mountain- [[boss1:Cast-3-4249-1458-17779-198631-0016F25FD0:198631]]", -- [3843]
--"<569.86 21:54:43> [UNIT_SPELLCAST_SUCCEEDED] Ularogg Cragshaper(12.1%-0.0%){Target:Gimlly} -Stance of the Mountain- [[boss1:Cast-3-4249-1458-17779-198509-0009F26003:198509]]", -- [4028]
function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, spellId)
	if spellId == 198509 then --Горная стойка
		self.vb.phase = 2
		self.vb.totemsAlive = 5
		self.vb.strikeCount = 0
		self.vb.sunderCount = 0
		self.vb.stanceCount = self.vb.stanceCount + 1
		specWarnStanceofMountain:Show(self.vb.stanceCount)
		specWarnStanceofMountain:Play("specialsoon")
		timerStanceOfMountain:Start()
		timerSunderCD:Stop()
		timerStrikeCD:Stop()
		timerBelowofDeepsCD:Stop()
	end
end
