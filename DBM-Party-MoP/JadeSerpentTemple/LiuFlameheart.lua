local mod	= DBM:NewMod(658, "DBM-Party-MoP", 1, 313)
local L		= mod:GetLocalizedStrings()

mod.statTypes = "normal,heroic,challenge,timewalker"

mod:SetRevision("20230504231118")
mod:SetCreatureID(56732)
mod:SetEncounterID(1416)
mod:SetHotfixNoticeRev(20221127000000)
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 106797 106823 106841 106856 106864 396907",
	"SPELL_AURA_REMOVED 106797",
	"SPELL_DAMAGE 107110",
	"SPELL_MISSED 107110",
	"SPELL_PERIODIC_DAMAGE 118540",
	"SPELL_PERIODIC_MISSED 118540",
	"UNIT_SPELLCAST_SUCCEEDED boss1 boss2"
--	"UNIT_DIED"
)

--[[
(ability.id = 106797 or ability.id = 107045 or ability.id = 106823 or ability.id = 106841 or ability.id = 396907) and type = "begincast"
 or ability.id = 106797
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
local warnPhase					= mod:NewPhaseChangeAnnounce(2, 2, nil, nil, nil, nil, nil, 2)
local warnDragonStrike			= mod:NewSpellAnnounce(106823, 2) --Разящий удар змеи
local warnJadeDragonStrike		= mod:NewSpellAnnounce(106841, 4) --Разящий удар Нефритовой Змеи

local specWarnDragonStrike		= mod:NewSpecialWarningDefensive(106823, nil, nil, nil, 1, 4) --Разящий удар змеи
local specWarnDragonKick		= mod:NewSpecialWarningDodge(106856, nil, nil, nil, 2, 2) --Удар змеи
local specWarnJadeDragonStrike	= mod:NewSpecialWarningDefensive(106841, nil, nil, nil, 3, 4) --Разящий удар Нефритовой Змеи
local specWarnJadeDragonKick	= mod:NewSpecialWarningDodge(106864, nil, nil, nil, 2, 2) --Повергающий удар Нефритовой Змеи
local specWarnJadeBreath		= mod:NewSpecialWarningDodge(396907, nil, nil, nil, 2, 2) --Огненное нефритовое дыхание
local specWarnJadeFire			= mod:NewSpecialWarningDodge(107045, nil, nil, nil, 2, 2) --Нефритовый огонь
local specWarnGTFO				= mod:NewSpecialWarningGTFO(118540, nil, nil, nil, 1, 8) --Волна Нефритовой Змеи

local timerJadeFireCD			= mod:NewCDTimer(12, 107045, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Нефритовый огонь
local timerJadeBreathCD			= mod:NewCDTimer(10, 396907, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Огненное нефритовое дыхание
local timerDragonStrikeCD		= mod:NewNextTimer(15.7, 106823, nil, nil, 2, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.HEALER_ICON) --Разящий удар змеи Kicks affect entire group as well (which are part of tank combo)
local timerJadeDragonStrikeCD	= mod:NewNextTimer(15.7, 106841, nil, nil, 2, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.HEALER_ICON) --Разящий удар Нефритовой Змеи Kicks affect entire group as well (which are part of tank combo)

function mod:OnCombatStart(delay)
	self:SetStage(1)
	timerDragonStrikeCD:Start(8-delay)
end

function mod:OnCombatEnd()
	self:UnregisterShortTermEvents()
end

function mod:DragonStrikeTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnDragonStrike:Show()
		specWarnDragonStrike:Play("defensive")
	else
		warnDragonStrike:Show()
	end
end

function mod:JadeDragonStrikeTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnJadeDragonStrike:Show()
		specWarnJadeDragonStrike:Play("defensive")
	else
		warnJadeDragonStrike:Show()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 106797 then--Jade Essence (Phase 2 trigger)
		self:SetStage(2)
		warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(2))
		warnPhase:Play("ptwo")
		timerDragonStrikeCD:Cancel()
		timerJadeDragonStrikeCD:Start(1.7)
		self:RegisterShortTermEvents(
			"INSTANCE_ENCOUNTER_ENGAGE_UNIT"
		)
	elseif args.spellId == 106823 then--Phase 1 dragonstrike
		self:BossTargetScanner(args.sourceGUID, "DragonStrikeTarget", 0.1, 2)
		timerDragonStrikeCD:Start()
	elseif spellId == 106841 then--phase 2 dragonstrike
		self:BossTargetScanner(args.sourceGUID, "JadeDragonStrikeTarget", 0.1, 2)
		timerJadeDragonStrikeCD:Start()
	elseif spellId == 106856 then
		specWarnDragonKick:Show()
		if self:IsMelee() then
			specWarnDragonKick:Play("runout")
		end
		specWarnDragonKick:ScheduleVoice(1, "watchwave")
	elseif spellId == 106864 then
		specWarnJadeDragonKick:Show()
		if self:IsMelee() then
			specWarnJadeDragonKick:Play("runout")
		end
		specWarnJadeDragonKick:ScheduleVoice(1, "watchwave")
	elseif spellId == 396907 then --Огненное нефритовое дыхание
		specWarnJadeBreath:Show()
		specWarnJadeBreath:Play("breathsoon")
		timerJadeBreathCD:Start()
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 106797 then--Jade Essence removed, (Phase 3 trigger)
		timerJadeDragonStrikeCD:Cancel()
	end
end

function mod:INSTANCE_ENCOUNTER_ENGAGE_UNIT()
	for i = 1, 5 do
		local unitID = "boss"..i
		local GUID = UnitGUID(unitID)
		local cid = self:GetCIDFromGUID(GUID)
		if cid == 56762 then -- Юй-лун
			self:SetStage(3)
			warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(3))
			warnPhase:Play("pthree")
			DBM:AddMsg("Murchal proshlyap")
			timerJadeDragonStrikeCD:Stop()
			timerJadeBreathCD:Start(6)
			timerJadeFireCD:Start(10)
		end
	end
end

function mod:SPELL_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 107110 and destGUID == UnitGUID("player") and self:AntiSpam() then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_MISSED = mod.SPELL_DAMAGE

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 118540 and destGUID == UnitGUID("player") and self:AntiSpam() then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE

function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, spellId)
	if spellId == 107098 then --Нефритовый огонь
		specWarnJadeFire:Show()
		specWarnJadeFire:Play("watchstep")
		timerJadeFireCD:Start()
	end
end
