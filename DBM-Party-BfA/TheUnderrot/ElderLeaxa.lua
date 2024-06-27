local mod	= DBM:NewMod(2157, "DBM-Party-BfA", 8, 1022)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240426175442")
mod:SetCreatureID(131318)
mod:SetEncounterID(2111)
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 260879 260894 264757 264603",
	"SPELL_CAST_SUCCESS 264603"
)

--TODO, Blood mirror timer
local specWarnBloodBolt				= mod:NewSpecialWarningInterrupt(260879, "HasInterrupt", nil, nil, 1, 2) --Кровавая стрела
local specWarnCreepingRot			= mod:NewSpecialWarningDodge(260894, nil, nil, nil, 2, 2) --Ползущая гниль
local specWarnSanguineFeast			= mod:NewSpecialWarningDodge(264757, nil, nil, nil, 2, 2) --Кровавый пир
local specWarnBloodMirror			= mod:NewSpecialWarningSwitch(264603, nil, -17950, nil, 1, 2) --Кровавое зеркало
--local specWarnGTFO				= mod:NewSpecialWarningGTFO(238028, nil, nil, nil, 1, 8)

--TODO: Use NewNextSourceTimer to split adds from boss
local timerCreepingRotCD			= mod:NewCDTimer(15.8, 260894, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Ползущая гниль
local timerSanguineFeastCD			= mod:NewCDTimer(30, 264757, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Кровавый пир
local timerBloodMirrorCD			= mod:NewCDCountTimer(47.4, 264603, nil, nil, nil, 1, nil, DBM_COMMON_L.DAMAGE_ICON, nil, nil, nil, 3, 5) --Кровавое зеркало 47.4-49.8

mod:AddInfoFrameOption(260685, "Healer")

mod.vb.bloodMirrorCount = 0
mod.vb.creepingRotCount = 0
mod.vb.sanguineFeastCount = 0

local allProshlyapationsOfMurchal = {
	--Кровавое зеркало
	[264603] = {15.3, 48.9, 52.1, 51.7, 48.1},
	--Ползущая гниль
	[260894] = {12.3, 15.8, 15.9, 18, 15.8, 18, 15.8, 15.8, 15.8, 15.8, 15.8, 15.8, 15.9},
	--Кровавый пир
	[264757] = {12.3, 29.8, 32.6, 32.1, 30.7, 33.8, 32},
}

function mod:OnCombatStart(delay)
	self.vb.bloodMirrorCount = 0
	self.vb.creepingRotCount = 0
	self.vb.sanguineFeastCount = 0
	timerCreepingRotCD:Start(12.3-delay) --
	timerBloodMirrorCD:Start(15.3-delay, 1) --
	if not self:IsNormal() then--Exclude normal, but allow heroic/mythic/mythic+
		timerSanguineFeastCD:Start(7.1-delay) --
	end
	if self.Options.InfoFrame then
		DBM.InfoFrame:SetHeader(DBM:GetSpellName(260685))
		DBM.InfoFrame:Show(5, "playerdebuffstacks", 260685, 1)
	end
end

function mod:OnCombatEnd()
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 260879 and self:CheckInterruptFilter(args.sourceGUID, false, true) then --Кровавая стрела
		specWarnBloodBolt:Show(args.sourceName)
		specWarnBloodBolt:Play("kickcast")
	elseif spellId == 260894 then --Ползущая гниль
		local cid = self:GetCIDFromGUID(args.sourceGUID)
		if cid == 131318 then--Main boss
			self.vb.creepingRotCount = self.vb.creepingRotCount + 1
			specWarnCreepingRot:Show()
			specWarnCreepingRot:Play("watchwave")
			local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.creepingRotCount+1)
			if timer then
				timerCreepingRotCD:Start(timer, self.vb.creepingRotCount+1)
			end
		end
	elseif spellId == 264757 then --Кровавый пир
		local cid = self:GetCIDFromGUID(args.sourceGUID)
		if cid == 131318 then--Main boss
			self.vb.sanguineFeastCount = self.vb.sanguineFeastCount + 1
			specWarnSanguineFeast:Show()
			specWarnSanguineFeast:Play("watchstep")
			local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.sanguineFeastCount+1)
			if timer then
				timerSanguineFeastCD:Start(timer, self.vb.sanguineFeastCount+1)
			end
		end
	elseif spellId == 264603 then --Кровавое зеркало
		self.vb.bloodMirrorCount = self.vb.bloodMirrorCount + 1
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.bloodMirrorCount+1)
		if timer then
			timerBloodMirrorCD:Start(timer, self.vb.bloodMirrorCount+1)
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 264603 then --Кровавое зеркало
		specWarnBloodMirror:Schedule(3)
		specWarnBloodMirror:ScheduleVoice(3, "mobkill")
	end
end
