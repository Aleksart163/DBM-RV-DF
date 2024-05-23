local mod	= DBM:NewMod(2497, "DBM-Party-Dragonflight", 3, 1198)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20231029212301")
mod:SetCreatureID(186615)
mod:SetEncounterID(2636)
mod:SetHotfixNoticeRev(20221029000000)
--mod:SetMinSyncRevision(20211203000000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 384316 384620 384686",
	"SPELL_AURA_APPLIED 384686 394875 384185",
	"SPELL_AURA_APPLIED_DOSE 394875",
	"SPELL_PERIODIC_DAMAGE 386916",
	"SPELL_PERIODIC_MISSED 386916"
)

--TODO, do anything with Electrical Overload? I don't see much to do with it at mod level
--TODO, log with transcriptoir and figure out how to alert new balls incoming to be soaked
--[[
(ability.id = 384316 or ability.id = 384620 or ability.id = 384686) and type = "begincast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
local warnEnergySurge							= mod:NewSpellAnnounce(384686, 3, nil, "Tank|MagicDispeller") --Волна энергии
local warnSurgeBoss								= mod:NewStackAnnounce(394875, 4)

local specWarnElectricalStorm					= mod:NewSpecialWarningCount(384620, nil, nil, nil, 2, 2) --Электрическая буря
local specWarnLightingStrike					= mod:NewSpecialWarningMoveAway(384316, nil, nil, nil, 2, 2) --Удар молнии
local specWarnEnergySurge						= mod:NewSpecialWarningDispel(384686, "MagicDispeller", nil, nil, 3, 2) --Волна энергии
local specWarnGTFO								= mod:NewSpecialWarningGTFO(386916, nil, nil, nil, 1, 8)

local timerLightingStrikeCD						= mod:NewCDTimer(20.2, 384316, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Удар молнии
local timerElectricStormCD						= mod:NewCDTimer(77.9, 384620, nil, nil, nil, 2, nil, DBM_COMMON_L.HEALER_ICON..DBM_COMMON_L.DEADLY_ICON) --Электрическая буря 60-61+3sec cast
local timerElectricStorm						= mod:NewCastTimer(18, 384620, nil, nil, nil, 2, nil, DBM_COMMON_L.HEALER_ICON..DBM_COMMON_L.DEADLY_ICON, nil, 3, 5) --Электрическая буря
local timerEnergySurgeCD						= mod:NewCDTimer(16.5, 384686, nil, "Tank|MagicDispeller", nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.MAGIC_ICON) --Волна энергии

local yellLightningStrike						= mod:NewShortFadesYell(384185, nil, nil, nil, "YELL") --Удар молнии

mod:AddInfoFrameOption(382628, false)

mod.vb.lightingStrikeCount = 0
mod.vb.energySurgeCount = 0
mod.vb.stormCount = 0

local Proshlyap = nil
local allProshlyapationsOfMurchal = {
	--Удар молнии
	[384316] = {18.2, 22.1, 22},
	--Волна энергии
	[384686] = {20.4, 17.1, 17, 17},
}

function mod:OnCombatStart(delay)
	Proshlyap = false
	self.vb.lightingStrikeCount = 0
	self.vb.energySurgeCount = 0
	self.vb.stormCount = 0
	timerEnergySurgeCD:Start(7-delay) --
	timerLightingStrikeCD:Start(11-delay) --
	timerElectricStormCD:Start(30.7-delay) --
	if self.Options.InfoFrame then
		DBM.InfoFrame:SetHeader(DBM:GetSpellName(382628))
		DBM.InfoFrame:Show(5, "playerdebuffremaining", 382628)
	end
end

function mod:OnCombatEnd()
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 384316 then --Удар молнии
		self.vb.lightingStrikeCount = self.vb.lightingStrikeCount + 1
		specWarnLightingStrike:Show()
		specWarnLightingStrike:Play("scatter")
		if not Proshlyap and self.vb.lightingStrikeCount < 1 then
			timerLightingStrikeCD:Start(nil, self.vb.lightingStrikeCount+1)
		elseif Proshlyap then
			local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.lightingStrikeCount+1)
			if timer then
				timerLightingStrikeCD:Start(timer, self.vb.lightingStrikeCount+1)
			end
		end
	elseif spellId == 384620 then --Электрическая буря
		self.vb.stormCount = self.vb.stormCount + 1
		specWarnElectricalStorm:Show(self.vb.stormCount)
		specWarnElectricalStorm:Play("aesoon")
		timerElectricStormCD:Start()
		timerElectricStorm:Start()
		timerLightingStrikeCD:Restart(18.2)
		timerEnergySurgeCD:Restart(20.4)
		if not Proshlyap then
			Proshlyap = true
		end
		self.vb.lightingStrikeCount = 0
		self.vb.energySurgeCount = 0
	elseif spellId == 384686 then --Волна энергии
		self.vb.energySurgeCount = self.vb.energySurgeCount + 1
		warnEnergySurge:Show()
		if not Proshlyap and self.vb.energySurgeCount < 2 then
			timerEnergySurgeCD:Start(nil, self.vb.energySurgeCount+1)
		elseif Proshlyap then
			local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.energySurgeCount+1)
			if timer then
				timerEnergySurgeCD:Start(timer, self.vb.energySurgeCount+1)
			end
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 384686 and args:IsDestTypeHostile() then
		specWarnEnergySurge:Show(args.destName)
		specWarnEnergySurge:Play("dispelboss")
	elseif spellId == 394875 then
		warnSurgeBoss:Show(args.destName, args.amount or 1)
	elseif spellId == 384185 then
		if args:IsPlayer() then
			yellLightningStrike:Countdown(spellId)
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 386916 and destGUID == UnitGUID("player") and self:AntiSpam(2, "TheRagingTempest") then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
