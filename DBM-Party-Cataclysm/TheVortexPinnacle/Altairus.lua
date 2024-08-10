local mod	= DBM:NewMod(115, "DBM-Party-Cataclysm", 8, 68)
local L		= mod:GetLocalizedStrings()

mod.statTypes = "normal,heroic,challenge,timewalker"
mod.upgradedMPlus = true

mod:SetRevision("20240810070000")
mod:SetCreatureID(43873)
mod:SetEncounterID(1041)
mod:SetHotfixNoticeRev(20240811070000)
--mod:SetMinSyncRevision(20230226000000)
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 88308",
	"SPELL_CAST_SUCCESS 413295 181089",
	"SPELL_AURA_APPLIED 88282 88286 413275",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

--TODO, verify changes on non mythic+ in 10.1
--NOTE, breath target no longer available in 10.1, this code may still be used in classic cataclysm
--NOTE, Biting Cold doesn't seem worth adding anything for. it's a passive healing requirement
--[[
ability.id = 88308 and type = "begincast"
 or (ability.id = 413295 or ability.id = 181089) and type = "cast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]

local warnCalltheWind		= mod:NewSpellAnnounce(88276, 2) --Призыв ветра
local warnUpwind			= mod:NewSpellAnnounce(88282, 1) --Наветренная сторона

--local specWarnBreath		= mod:NewSpecialWarningYou(88308, "-Tank", nil, 2, 1, 2)
local specWarnBreath		= mod:NewSpecialWarningDodge(88308, nil, 18357, nil, 2, 2) --Студеное дыхание (Дыхание)
local specWarnDownburst		= mod:NewSpecialWarningMoveTo(413295, nil, nil, nil, 2, 14, 4) --Нисходящий порыв
local specWarnDownwind		= mod:NewSpecialWarningSpell(88286, nil, nil, nil, 1, 14) --Подветренная сторона Альтаирия
local specWarnGTFO			= mod:NewSpecialWarningGTFO(413275, nil, nil, nil, 1, 8) --Холодный фронт

local timerCalltheWindCD	= mod:NewCDTimer(20.6, 88276, nil, nil, nil, 6) --Призыв ветра
local timerBreathCD			= mod:NewCDTimer(13.4, 88308, 18357, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Студеное дыхание (Дыхание) May be 10.5 pre nerf for cata classic
local timerDownburstCD		= mod:NewCDTimer(35.1, 413295, nil, nil, nil, 7, nil, nil, nil, 1, 5) --Нисходящий порыв 35.1-44

mod.vb.activeWind = "none"
mod.vb.windCount = 0
mod.vb.burstCount = 0
mod.vb.breathCount = 0

local tornado = DBM:GetSpellName(86133)

local function updateAllTimers(self, ICD)
	DBM:Debug("updateAllTimers running", 3)
	if timerBreathCD:GetRemaining(self.vb.breathCount+1) < ICD then
		local elapsed, total = timerBreathCD:GetTime(self.vb.breathCount+1)
		local extend = ICD - (total-elapsed)
		DBM:Debug("timerBreathCD extended by: "..extend, 2)
		timerBreathCD:Update(elapsed, total+extend, self.vb.breathCount+1)
	end
	if timerCalltheWindCD:GetRemaining(self.vb.windCount+1) < ICD then
		local elapsed, total = timerCalltheWindCD:GetTime(self.vb.windCount+1)
		local extend = ICD - (total-elapsed)
		DBM:Debug("timerCalltheWindCD extended by: "..extend, 2)
		timerCalltheWindCD:Update(elapsed, total+extend, self.vb.windCount+1)
	end
	if timerDownburstCD:GetRemaining(self.vb.burstCount+1) < ICD then
		local elapsed, total = timerDownburstCD:GetTime(self.vb.burstCount+1)
		local extend = ICD - (total-elapsed)
		DBM:Debug("timerDownburstCD extended by: "..extend, 2)
		timerDownburstCD:Update(elapsed, total+extend, self.vb.burstCount+1)
	end
end

local allProshlyapationsOfMurchal = {
	--Дыхание
	[88308] = {12.5, 21, 20.9, 21.1, 21, 21, 20, 21.1, 21, 21, 21, 21, 21, 21, 22},
	--Нисходящий порыв
	[413295] = {20.4, 36.5, 42.1, 35, 40, 35, 40, 35, 40},
}

function mod:OnCombatStart(delay)
	self.vb.activeWind = "none"
	self.vb.windCount = 0
	self.vb.burstCount = 0
	self.vb.breathCount = 0
	if self:IsMythic() then
		timerCalltheWindCD:Start(4.9-delay) --
		timerBreathCD:Start(12.5-delay) --
		timerDownburstCD:Start(20.4-delay) --
	else
		--TODO, recheck on non mythic plus
		timerCalltheWindCD:Start(5-delay)
		timerBreathCD:Start(10.7-delay)
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 88308 then --Студеное дыхание
		self.vb.breathCount = self.vb.breathCount + 1
		specWarnBreath:Show()
		specWarnBreath:Play("breathsoon")
		if self:IsMythic() then
			local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.breathCount+1)
			if timer then
				timerBreathCD:Start(timer, self.vb.breathCount+1)
			end
		else
			timerBreathCD:Start(13.4, self.vb.breathCount+1)
			updateAllTimers(self, 6)
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 413295 then --Нисходящий порыв
		self.vb.burstCount = self.vb.burstCount + 1
		specWarnDownburst:Show(tornado)
		specWarnDownburst:Play("getknockedup")
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.burstCount+1)
		if timer then
			timerDownburstCD:Start(timer, self.vb.burstCount+1)
		end
	elseif spellId == 181089 then--Encounter Event
		DBM:Debug("Check Murchal proshlyap", 2)
		if not self:IsMythic() then
			self.vb.windCount = self.vb.windCount + 1
			warnCalltheWind:Show(self.vb.windCount)
			timerCalltheWindCD:Start(self:IsMythic() and 15.4 or 20.6, self.vb.windCount+1)
		end
		--updateAllTimers(self, 1.2)--accurate, but not really worth triggering
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 88282 and args:IsPlayer() and self.vb.activeWind ~= "up" then
		warnUpwind:Show()
		self.vb.activeWind = "up"
	elseif spellId == 88286 and args:IsPlayer() and self.vb.activeWind ~= "down" then
		specWarnDownwind:Show()
		specWarnDownwind:Play("getupwind")
		self.vb.activeWind = "down"
	elseif spellId == 413275 and args:IsPlayer() and self:AntiSpam(2.5, 1) then
		specWarnGTFO:Show(args.spellName)
		specWarnGTFO:Play("watchfeet")
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(_, _, spellId)
	if spellId == 88276 and self:AntiSpam(2, "CalltheWind") then
		self.vb.windCount = self.vb.windCount + 1
		warnCalltheWind:Schedule(1)
		if self.vb.windCount < 11 then
			timerCalltheWindCD:Start(20, self.vb.windCount+1)
		elseif self.vb.windCount >= 11 then
			timerCalltheWindCD:Start(21, self.vb.windCount+1)
		end
	end
end
