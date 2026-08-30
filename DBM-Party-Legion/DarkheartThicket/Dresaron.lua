local mod	= DBM:NewMod(1656, "DBM-Party-Legion", 2, 762)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260630000000")
mod:SetCreatureID(99200)
mod:SetEncounterID(1838)
mod:SetHotfixNoticeRev(20260714000000)
mod:SetMinSyncRevision(20260714000000)
--mod.respawnTime = 29
mod:DisableESCombatDetection()--Remove if blizz fixes trash firing ENCOUNTER_START
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 199389 199345 191325",
	"SPELL_CAST_SUCCESS 199329",
	"SPELL_PERIODIC_DAMAGE 199460",
	"SPELL_PERIODIC_MISSED 199460",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

--[[
(ability.id = 199389 or ability.id = 199345 or ability.id = 191325) and type = "begincast"
 or ability.name = "Breath of Corruption" and type = "damage"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
local warnRoar						= mod:NewSpellAnnounce(199389, 2, nil, nil, 405332) --Сотрясающий землю рык (Сотрясающий рык)
local warnRoar2						= mod:NewPreWarnAnnounce(199389, 5, 1, nil, nil, 405332) --Сотрясающий землю рык (Сотрясающий рык)

local specWarnDownDraft				= mod:NewSpecialWarningMoveTo(199345, nil, nil, DBM_COMMON_L.PUSHBACK, 4, 2) --Нисходящий поток (Отталкивание)
local specWarnBreath				= mod:NewSpecialWarningDodge(191325, nil, nil, DBM_COMMON_L.FRONTAL, 2, 2) --Дыхание порчи (Фронталка)
local specWarnFallingRocks			= mod:NewSpecialWarningGTFO(199460, nil, nil, nil, 1, 8) --Каменная осыпь

local timerBreathCD					= mod:NewCDCountTimer(22, 191325, DBM_COMMON_L.FRONTAL.." (%s)", nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON) --Дыхание порчи (Фронталка) 22/30 alternating? need more logs to confirm
local timerEarthShakerCD			= mod:NewCDCountTimer(30.3, 199389, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Сотрясающий землю рык OLD: 21
local timerDownDraftCD				= mod:NewCDCountTimer(31.2, 199345, DBM_COMMON_L.PUSHBACK.." (%s)", nil, nil, 7, nil, nil, nil, 1, 5) --Нисходящий поток (Отталкивание) 31.2
local timerDownDraft				= mod:NewCastTimer(9, 199345, DBM_COMMON_L.PUSHBACK, nil, nil, 7, nil, nil, nil, 1, 3) --Нисходящий поток (Отталкивание)

--local yellBreath					= mod:NewYell(199332)

mod.vb.breathCount = 0
mod.vb.earthCount = 0
mod.vb.draftCount = 0
mod.vb.proshlyapBreathCount = 0

local proshlyapationDownDraftTimers = {11.2, 31.2, 30.3} --Нисходящий поток (Отталкивание) 7 кастов норм
local proshlyapationBreathTimers = {7.2, 23, 30.3} --Дыхание порчи (Фронталка) 8 кастов норм

local function checkBreathProshlyap(self)
	self.vb.proshlyapBreathCount = self.vb.proshlyapBreathCount + 1
	specWarnBreath:Show()
	specWarnBreath:Play("breathsoon")
	local timer
	if self:IsMythic() then
		timer = proshlyapationBreathTimers[self.vb.proshlyapBreathCount+1] or 30.3
	end
	timerBreathCD:Start(timer, self.vb.proshlyapBreathCount+1)
	self:Schedule(timer, checkBreathProshlyap, self)
	DBM:AddMsg("Запущена тестовая версия проверки таймеров на каст Дыхание порчи. Если они неточные, то необходимо связаться с разработчиком аддона.")
--	DBM:Debug("Murchal Proshlyap (Проверка Дыхания порчи)", 2)
end

function mod:OnCombatStart(delay)
	self.vb.proshlyapBreathCount = 0
	self.vb.breathCount = 0
	self.vb.earthCount = 0
	self.vb.draftCount = 0
--	timerBreathCD:Start(13.3-delay, 1)--13.3-15.4
--	timerDownDraftCD:Start(19.4-delay, 1)--19.4-22.7
--	timerEarthShakerCD:Start(31.6-delay, 1)--31.6-34.8
	timerBreathCD:Start(7.2-delay, 1) --
	self:Schedule(7.2-delay, checkBreathProshlyap, self)
	timerDownDraftCD:Start(11.2-delay, 1) --
	timerEarthShakerCD:Start(34.3-delay, 1) --
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 199389 then
		self.vb.earthCount = self.vb.earthCount + 1
		warnRoar:Show()
		timerEarthShakerCD:Start(nil, self.vb.earthCount+1)
		warnRoar2:Schedule(25.3)
		warnRoar2:ScheduleVoice(25.3, "aesoon")
	elseif spellId == 199345 then
		self.vb.draftCount = self.vb.draftCount + 1
		specWarnDownDraft:Show(DBM_COMMON_L.BOSS)
		specWarnDownDraft:Play("movetoboss")
		local timer
		timer = proshlyapationDownDraftTimers[self.vb.draftCount+1] or 30.3
		timerDownDraftCD:Start(timer, self.vb.draftCount+1)
		timerDownDraft:Start()
	elseif spellId == 191325 then--If they ever enable it in combat log, it'll be this ID
		DBM:Debug("Check Murchal proshlyap (Начался каст дыхания)", 2)
--		self.vb.breathCount = self.vb.breathCount + 1
--		specWarnBreath:Show(self.vb.breathCount)
--		specWarnBreath:Play("breathsoon")
--		--"Breath of Corruption-199332-npc:99200-000021BD9C = pull:14.6, 22.0, 30.4", -- [8]
--		if self.vb.breathCount == 2 then--TODO, longer pulls to find out if it's 30 every other one
--			timerBreathCD:Start(30, self.vb.breathCount+1)
--		else
--			timerBreathCD:Start(22, self.vb.breathCount+1)
--		end
	end
end

function mod:SPELL_CAST_SUCCESS(args) --Сломано на стороне сервера
	local spellId = args.spellId
	if spellId == 199329 or spellId == 191325 then
		DBM:Debug("Check Murchal proshlyap (Случился каст дыхания 1)", 2)
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 199460 and destGUID == UnitGUID("player") and self:AntiSpam(2, 1) then
		specWarnFallingRocks:Show(spellName)
		specWarnFallingRocks:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE

--For time stamping purposes for WCL parsing, shows us time from cast til damage (~2 sec)
--NOTE spell damage not reliable, the tank actually can side step it, just right now not all tanks on PTR are (thankfully for timer purposes)
--"<1405.08 22:44:10> [UNIT_SPELLCAST_SUCCEEDED] Dresaron(75.6%-0.0%){Target:Fxa} -Breath of Corruption- [[boss1:Cast-3-5770-1466-11160-199332-001921C31C:199332]]", -- [17494]
--"<1405.09 22:44:10> [UNIT_SPELLCAST_START] Dresaron(75.6%-0.0%){Target:Fxa} -Breath of Corruption- 2s [[boss1:Cast-3-5770-1466-11160-191325-001AA1C31C:191325]]", -- [17498]
--"<1406.30 22:44:12> [UNIT_TARGET] boss1#Dresaron#Target: ??#TargetOfTarget: ??", -- [17511]
--"<1407.09 22:44:12> [UNIT_SPELLCAST_CHANNEL_START] Dresaron(71.2%-0.0%){Target:??} -Breath of Corruption- 2s [[boss1:nil:191325]]", -- [17524]
--"<1407.12 22:44:12> [CLEU] SPELL_DAMAGE#Creature-0-5770-1466-11160-99200-000021BD9C#Dresaron#Player-5764-000CFD06#Fxa#191326#Breath of Corruption", -- [17526]
function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, spellId) --Сломано разрабами и не работает
	if spellId == 199332 then--Target scanning not an option, boss wipes target as seen above
	--	self.vb.breathCount = self.vb.breathCount + 1
		DBM:Debug("Check Murchal proshlyap (Случился каст дыхания 2)", 2)
--[[		specWarnBreath:Show()
		self.vb.breathCount = self.vb.breathCount + 1
		specWarnBreath:Show()
		specWarnBreath:Play("breathsoon")
		--"Breath of Corruption-199332-npc:99200-000021BD9C = pull:14.6, 22.0, 30.4", -- [8]
		if self.vb.breathCount == 2 then--TODO, longer pulls to find out if it's 30 every other one

@@ -136,6 +138,5 @@ function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, spellId) --Сломано разр
		else
			timerBreathCD:Start(22, self.vb.breathCount+1)
		end
		DBM:Debug("Check Murchal proshlyap (Случился каст дыхания 2)", 2)]]
	end
end
