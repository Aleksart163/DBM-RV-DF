local mod	= DBM:NewMod(114, "DBM-Party-Cataclysm", 8, 68)
local L		= mod:GetLocalizedStrings()

mod.statTypes = "normal,heroic,challenge,timewalker"
mod.upgradedMPlus = true

mod:SetRevision("20230621232728")
mod:SetCreatureID(43878)
mod:SetEncounterID(1043)
mod:SetHotfixNoticeRev(20230427000000)
--mod:SetMinSyncRevision(20230226000000)
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 86340 86331 413151",
	"SPELL_AURA_APPLIED 86292"
)

--[[
(ability.id = 86340 or ability.id = 413151) and type = "begincast"
 or (ability.id = 86295 or ability.id = 86310) and (type = "applybuff" or type = "removebuff")
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
 or ability.id = 413562 and type = "begincast"
--]]
--TODO, Cyclone Shield Fragments do something with it? maybe upgrade shield to watch your step alert?
local warnShield			= mod:NewCountAnnounce(86267, 2) --Охранный смерч
local warnShieldEnd			= mod:NewEndAnnounce(86267, 1) --Охранный смерч
local warnSummonTempest		= mod:NewCountAnnounce(86340, 2) --Вызов вихря
local warnLethalCurrent		= mod:NewCastAnnounce(413151, 4) --Вызов вихря

local specWarnLightningBolt	= mod:NewSpecialWarningInterrupt(86331, "HasInterrupt", nil, nil, 1, 2) --Молния
local specWarnGTFO			= mod:NewSpecialWarningGTFO(86292, nil, nil, nil, 1, 8) --Охранный смерч

local timerSummonTempest	= mod:NewCDCountTimer(16.8, 86340, nil, nil, nil, 1) --Вызов вихря 16.8 old
local timerShield			= mod:NewNextCountTimer(30.5, 86292, nil, nil, nil, 6) --Охранный смерч

mod.vb.shieldCount = 0
mod.vb.tempestCount = 0

function mod:OnCombatStart(delay)
	self.vb.shieldCount = 0
	self.vb.tempestCount = 0
	if not self:IsMythicPlus() then--Summoned instantly on M+
		timerSummonTempest:Start(16.8-delay)
		timerShield:Start(23.3-delay, 1)
		DBM:AddMsg("the non M+ version of these may be incorrect until confirmed/redone to match M+")
		self:RegisterShortTermEvents(
			"RAID_BOSS_EMOTE"
		)
	else
		timerShield:Start(4.4-delay, 1) --
		self:RegisterShortTermEvents(
			"SPELL_AURA_REMOVED 86295 86310"
		)
	end
end

function mod:OnCombatEnd()
	self:UnregisterShortTermEvents()
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 86340 or spellId == 413151 and self:AntiSpam(3, 3) then
		self.vb.tempestCount = self.vb.tempestCount + 1
		warnSummonTempest:Show(self.vb.tempestCount)
		timerSummonTempest:Start(self:IsMythicPlus() and 39.6 or 16.8, self.vb.tempestCount+1)--39.6-41
	elseif spellId == 413151 and self:AntiSpam(3, 1) then
		warnLethalCurrent:Show()
	elseif spellId == 86331 then --Молния
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnLightningBolt:Show(args.sourceName)
			specWarnLightningBolt:Play("kickcast")
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 86292 and args:IsPlayer() and self:AntiSpam(3, 2) then
		specWarnGTFO:Show(args.spellName)
		specWarnGTFO:Play("watchfeet")
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 86295 then
		self.vb.shieldCount = self.vb.shieldCount + 1
		warnShield:Show(self.vb.shieldCount)
		timerShield:Start(40, self.vb.shieldCount+1)--Restart used purely to avoid a bug where when boss is killed it fires debug
	elseif spellId == 86310 then
		warnShieldEnd:Show()
	end
end

--Probably still needed for classic cataclysm, and maybe even non M+
function mod:RAID_BOSS_EMOTE(msg)
	if msg == L.Retract or msg:find(L.Retract) then
		self.vb.shieldCount = self.vb.shieldCount + 1
		warnShield:Show(self.vb.shieldCount)
		timerShield:Start(30.5, self.vb.shieldCount+1)
	end
end
