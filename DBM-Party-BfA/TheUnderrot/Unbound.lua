local mod	= DBM:NewMod(2158, "DBM-Party-BfA", 8, 1022)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260531000000")
mod:SetCreatureID(133007)
mod:SetEncounterID(2123)
mod.sendMainBossGUID = true
mod:SetHotfixNoticeRev(20260530000000)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 269843 269310",
	"SPELL_AURA_APPLIED 269301",
	"SPELL_AURA_APPLIED_DOSE 269301",
	"SPELL_PERIODIC_DAMAGE 269838",
	"SPELL_PERIODIC_MISSED 269838",
	"UNIT_DIED",
	"UNIT_POWER_UPDATE",
	"UNIT_SPELLCAST_SUCCEEDED boss1 boss2 boss3"
)

--TODO, target scanning cleansing light?
--TODO, verify GTFO
--[[
(ability.id = 269843 or ability.id = 269310) and type = "begincast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
local warnVisage					= mod:NewAddsLeftAnnounce(-18312, 1, 269692)

local specWarnPutridBlood			= mod:NewSpecialWarningStack(269301, nil, 4, nil, nil, 3, 4) --Порченая кровь
local specWarnBloodVisage			= mod:NewSpecialWarningSwitch(-18312, "-Healer", nil, nil, 1, 2)
local specWarnVileExpulsion			= mod:NewSpecialWarningDodge(269843, nil, nil, DBM_COMMON_L.FRONTAL, 2, 2) --Гнусный выброс (Фронталка)
local specWarnCleansingLight		= mod:NewSpecialWarningMoveTo(269310, nil, nil, nil, 1, 2) --Очищающий свет
local specWarnGTFO					= mod:NewSpecialWarningGTFO(269838, nil, nil, nil, 1, 8) --Гнусный выброс

local timerBloodVisageCD			= mod:NewCDTimer(15.7, -18312, nil, nil, nil, 1, 269692) --Кровавый образ
local timerVileExpulsionCD			= mod:NewCDTimer(15.7, 269843, DBM_COMMON_L.FRONTAL, nil, nil, 3) --Гнусный выброс (Фронталка)
local timerCleansingLightCD			= mod:NewCDCountTimer(15.7, 269310, nil, nil, nil, 7) --Очищающий свет

mod:AddInfoFrameOption(269301, "Healer")

mod.vb.remainingAdds = 6
mod.vb.lightCount = 0

local ProshlyapationsOfMurchalTimers = {18, 23.7, 23.7, 25.5, 23.7, 23.7, 23.7, 26, 23.7, 26} --Очищающий свет

function mod:OnCombatStart(delay)
	self.vb.lightCount = 0
	self.vb.remainingAdds = 6
	timerVileExpulsionCD:Start(8.2-delay)
	timerCleansingLightCD:Start(18-delay, 1)
	if self.Options.InfoFrame then
		DBM.InfoFrame:SetHeader(DBM:GetSpellName(269301))
		DBM.InfoFrame:Show(5, "playerdebuffstacks", 269301, 1)
	end
end

function mod:OnCombatEnd()
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 269843 then
		specWarnVileExpulsion:Show()
		specWarnVileExpulsion:Play("watchwave")
		timerVileExpulsionCD:Start()
	elseif spellId == 269310 then --Очищающий свет
		self.vb.lightCount = self.vb.lightCount + 1
		specWarnCleansingLight:Show(DBM_COMMON_L.ALLY)
		specWarnCleansingLight:Play("gathershare")
		local timer = ProshlyapationsOfMurchalTimers[self.vb.lightCount+1]
		if timer then
			timerCleansingLightCD:Start(timer, self.vb.lightCount+1)
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 269301 then --Порченая кровь
		local amount = args.amount or 1
		if args:IsPlayer() and amount >= 4 then
			specWarnPutridBlood:Show(amount)
			specWarnPutridBlood:Play("stackhigh")
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 269838 and destGUID == UnitGUID("player") and self:AntiSpam(2, 2) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 137103 then--Visage
		self.vb.remainingAdds = self.vb.remainingAdds - 1
		warnVisage:Show(self.vb.remainingAdds)
	end
end

--[[function mod:UNIT_SPELLCAST_SUCCEEDED(_, _, spellId) --Не работает
	if spellId == 272663 and self:AntiSpam(2, 1) then--Blood Clone Cosmetic
		specWarnBloodVisage:Show()
		specWarnBloodVisage:Play("killmob")
		timerBloodVisageCD:Start(31.5)
	end
end]]

function mod:UNIT_POWER_UPDATE()
	local bossPower = UnitPower("boss1")
	if bossPower == 100 and self:AntiSpam(3, "FullPower") then
		specWarnBloodVisage:Schedule(3)
		specWarnBloodVisage:ScheduleVoice(3, "killmob")
	end
end
