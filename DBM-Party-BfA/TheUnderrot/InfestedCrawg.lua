local mod	= DBM:NewMod(2131, "DBM-Party-BfA", 8, 1022)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240417180519")
mod:SetCreatureID(131817)
mod:SetEncounterID(2118)
mod.sendMainBossGUID = true
mod:SetHotfixNoticeRev(20230528000000)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 260416 260333",
	"SPELL_AURA_REMOVED 260416",
	"SPELL_CAST_START 260793 260292",
	"SPELL_CAST_SUCCESS 260333"
)

--TODO, a really long normal pull to get timer interactions correct when there are no tantrums
--These don't exist on WCL, or at least not in a way they can be found easily :\
--M+ Off Log
--https://www.warcraftlogs.com/reports/cjPnRCWhkrvwd7zD#fight=last&pins=2%24Off%24%23244F4B%24expression%24ability.id%20%3D%20260333%20and%20type%20%3D%20%22cast%22%20%20or%20(ability.id%20%3D%20260793%20or%20ability.id%20%3D%20260292)%20and%20type%20%3D%20%22begincast%22%20%20or%20type%20%3D%20%22dungeonencounterstart%22%20or%20type%20%3D%20%22dungeonencounterend%22&view=events&translate=true
--M+ Frequent Log
--https://www.warcraftlogs.com/reports/GQa23ntY8pxJNhHB#fight=last&pins=2%24Off%24%23244F4B%24expression%24ability.id%20%3D%20260333%20and%20type%20%3D%20%22cast%22%20%20or%20(ability.id%20%3D%20260793%20or%20ability.id%20%3D%20260292)%20and%20type%20%3D%20%22begincast%22%20%20or%20type%20%3D%20%22dungeonencounterstart%22%20or%20type%20%3D%20%22dungeonencounterend%22&view=events
--[[
ability.id = 260333 and type = "cast"
 or (ability.id = 260793 or ability.id = 260292) and type = "begincast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
local specWarnIndigestion			= mod:NewSpecialWarningDefensive(260793, "Tank", nil, nil, 3, 4) --Несварение
local specWarnCharge				= mod:NewSpecialWarningDodge(260292, nil, nil, nil, 3, 2) --Рывок
local specWarnTantrum				= mod:NewSpecialWarningCount(260333, nil, nil, nil, 2, 2) --Припадок

local timerIndigestionCD			= mod:NewCDCountTimer(60, 260793, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON) --Несварение
local timerChargeCD					= mod:NewCDCountTimer(60, 260292, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Рывок
local timerTantrumCD				= mod:NewCDCountTimer(48.1, 260333, nil, nil, nil, 7) --Припадок

mod:AddNamePlateOption("NPAuraMetamorphosis", 260416)

mod.vb.murchalOchkenProshlyapCount = 1
mod.vb.indigestionCount = 0
mod.vb.chargeCount = 0
mod.vb.tantrumCount = 0

local allProshlyapationsOfMurchal = {
	[1] = {
		--Рывок
		[260292] = {7.9, 23},
		--Несварение
		[260793] = {17.9},
	},
	[2] = {
		--Рывок
		[260292] = {29.9},
		--Несварение
		[260793] = {17.9},
	},
	[3] = {
		--Рывок
		[260292] = {17.9, 23.1},
		--Несварение
		[260793] = {29},
	},
	[4] = {
		--Рывок
		[260292] = {30.1},
		--Несварение
		[260793] = {18.1},
	},
	[5] = {
		--Рывок
		[260292] = {30},
		--Несварение
		[260793] = {17.9},
	},
	--Припадок
	[260333] = {46.4, 46.5, 57.7, 46.9, 48},
}

function mod:OnCombatStart(delay)
	self.vb.murchalOchkenProshlyapCount = 1
	self.vb.indigestionCount = 0
	self.vb.chargeCount = 0
	self.vb.tantrumCount = 0
	if self.Options.NPAuraMetamorphosis then
		DBM:FireEvent("BossMod_EnableHostileNameplates")
	end
	--he casts random ability first, it's charge like 95% of time though
	timerChargeCD:Start(7.9-delay, 1) --
	timerIndigestionCD:Start(18.9-delay, 1) --
	timerTantrumCD:Start(46.4, 1) --
end

function mod:OnCombatEnd()
	if self.Options.NPAuraMetamorphosis then
		DBM.Nameplate:Hide(true, nil, nil, nil, true, true)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 260416 then
		if self.Options.NPAuraMetamorphosis then
			DBM.Nameplate:Show(true, args.destGUID, spellId, nil, 8)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 260416 then
		if self.Options.NPAuraMetamorphosis then
			DBM.Nameplate:Hide(true, args.destGUID, spellId)
		end
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 260793 then --Несварение
		self.vb.indigestionCount = self.vb.indigestionCount + 1
		specWarnIndigestion:Show()
		specWarnIndigestion:Play("breathsoon")
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, self.vb.murchalOchkenProshlyapCount, spellId, self.vb.indigestionCount+1)
		if timer then
			timerIndigestionCD:Start(timer, self.vb.indigestionCount+1)
		end
	elseif spellId == 260292 then --Рывок
		self.vb.chargeCount = self.vb.chargeCount + 1
		specWarnCharge:Show()
		specWarnCharge:Play("chargemove")
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, self.vb.murchalOchkenProshlyapCount, spellId, self.vb.chargeCount+1)
		if timer then
			timerChargeCD:Start(timer, self.vb.chargeCount+1)
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 260333 then --Припадок
		self.vb.murchalOchkenProshlyapCount = self.vb.murchalOchkenProshlyapCount + 1
		self.vb.indigestionCount = 0
		self.vb.chargeCount = 0
		self.vb.tantrumCount = self.vb.tantrumCount + 1
		specWarnTantrum:Show(self.vb.tantrumCount)
		specWarnTantrum:Play("aesoon")
		if self.vb.murchalOchkenProshlyapCount == 2 then
			timerChargeCD:Start(29.9, 1)
			timerIndigestionCD:Start(17.9, 1)
		elseif self.vb.murchalOchkenProshlyapCount == 3 then
			timerChargeCD:Start(17.9, 1)
			timerIndigestionCD:Start(29, 1)
		elseif self.vb.murchalOchkenProshlyapCount == 4 then
			timerChargeCD:Start(30.1, 1)
			timerIndigestionCD:Start(18.1, 1)
		elseif self.vb.murchalOchkenProshlyapCount == 5 then
			timerChargeCD:Start(30, 1)
			timerIndigestionCD:Start(17.9, 1)
		end
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.tantrumCount+1)
		if timer then
			timerTantrumCD:Start(timer, self.vb.tantrumCount+1)
		end
	end
end
