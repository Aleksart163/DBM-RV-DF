local mod	= DBM:NewMod(2127, "DBM-Party-BfA", 10, 1021)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260630000000")
mod:SetCreatureID(131863)
mod:SetEncounterID(2115)
mod:SetHotfixNoticeRev(20260715000000)
mod:SetMinSyncRevision(20260715000000)
mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 264931 264923 264694 264734",
--	"SPELL_AURA_APPLIED",
	"SPELL_PERIODIC_DAMAGE 264712",
	"SPELL_PERIODIC_MISSED 264712"
)

--[[
(ability.id = 264931 or ability.id = 264923 or ability.id = 264694 or ability.id = 264734) and type = "begincast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
--TODO, longer pulls to detect more variations in Rotten casts
local warnTenderize					= mod:NewCountAnnounce(264923, 2) --Отбивка
local warnConsumeAll				= mod:NewCastAnnounce(264734, 4) --Поглощение

local specWarnServant				= mod:NewSpecialWarningSwitch(264931, "Dps", nil, DBM_COMMON_L.ADDS, 1, 2) --Призыв слуг
local specWarnTenderize				= mod:NewSpecialWarningDodge(264923, nil, nil, DBM_COMMON_L.FRONTAL, 2, 2) --Отбивка (Фронталка)
local specWarnRottenExpulsion		= mod:NewSpecialWarningDodge(264694, nil, nil, nil, 1, 2) --Волна гнили
local specWarnGTFO					= mod:NewSpecialWarningGTFO(264712, nil, nil, nil, 1, 8) --Волна гнили

local timerServantCD				= mod:NewCDCountTimer(42.5, 264931, DBM_COMMON_L.ADDS.." (%s)", nil, nil, 1, nil, DBM_COMMON_L.DAMAGE_ICON) --Призыв слуг
local timerTenderizeCD				= mod:NewCDCountTimer(43.7, 264923, DBM_COMMON_L.FRONTAL.." (%s)", nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Отбивка (Фронталка) Timer for first in each set of 3
local timerRottenExpulsionCD		= mod:NewCDCountTimer(20.2, 264694, nil, nil, nil, 3) --Волна гнили 14.6--26 (health based?)

mod.vb.tenderizeCount = 0
mod.vb.rottenCount = 0
mod.vb.servantCount = 0

function mod:OnCombatStart(delay)
	self.vb.tenderizeCount = 0
	self.vb.rottenCount = 0
	self.vb.servantCount = 0
	timerRottenExpulsionCD:Start(5-delay, 1)
	timerTenderizeCD:Start(20.8-delay, 1)
	timerServantCD:Start(32.9-delay, 1)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 264931 then
		self.vb.servantCount = self.vb.servantCount + 1
--		local bossHealth = self:GetBossHP(args.sourceGUID)
--		if bossHealth and bossHealth >= 10 then--Only warn to switch to add if boss above 10%, else ignore them
			specWarnServant:Show()
			specWarnServant:Play("killmob")
--		end
		timerServantCD:Start(nil, self.vb.servantCount+1)
	elseif spellId == 264923 then
		self.vb.tenderizeCount = self.vb.tenderizeCount + 1
		warnTenderize:Show(self.vb.tenderizeCount)
		if self.vb.tenderizeCount == 1 then
			specWarnTenderize:Show()
			specWarnTenderize:Play("shockwave")
			timerTenderizeCD:Start(nil, self.vb.tenderizeCount+1)
		end
		if self.vb.tenderizeCount == 3 then
			self.vb.tenderizeCount = 0
		end
	elseif spellId == 264694 then
		self.vb.rottenCount = self.vb.rottenCount + 1
		specWarnRottenExpulsion:Show()
		specWarnRottenExpulsion:Play("watchstep")
		--5, 29.2, 20.2, 23.1, 20.2
		if self.vb.rottenCount == 1 then--2, 4, probably 6
			timerRottenExpulsionCD:Start(29.2, self.vb.rottenCount+1)
		elseif self.vb.rottenCount == 3 then
			timerRottenExpulsionCD:Start(21.7, self.vb.rottenCount+1)
		else--2, 4, etc
			timerRottenExpulsionCD:Start(20.2, self.vb.rottenCount+1)
		end
	elseif spellId == 264734 then
		warnConsumeAll:Show()
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 264712 and destGUID == UnitGUID("player") and self:AntiSpam(2, 4) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
