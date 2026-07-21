local mod	= DBM:NewMod(2030, "DBM-Party-BfA", 1, 968)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260630000000")
mod:SetCreatureID(122968)
mod:SetEncounterID(2087)
mod:SetHotfixNoticeRev(20260714000000)
mod:SetMinSyncRevision(20260714000000)
mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 249923 259187 250096 249919 250050",
	"SPELL_AURA_APPLIED 250036",
	"SPELL_PERIODIC_DAMAGE 250036",
	"SPELL_PERIODIC_MISSED 250036",
	"CHAT_MSG_RAID_BOSS_EMOTE"
)

--[[
(ability.id = 249923 or ability.id = 250096 or ability.id = 250050 or ability.id = 249919 or ability.id = 259187) and type = "begincast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
 or ability.id = 250096 and (type = "cast" or type = "interrupt")
--]]
--TODO: Verify CHAT_MSG_RAID_BOSS_EMOTE for soulrend. I know i saw it but not sure I got spellId right since chatlog only grabs parsed name
local warnSoulRend					= mod:NewTargetAnnounce(259187, 4) --Раздирание души
local warnWrackingPain				= mod:NewTargetNoFilterAnnounce(250096, 4, nil, "Healer") --Нестерпимая боль

local specWarnSoulRend				= mod:NewSpecialWarningRun(259187, nil, nil, nil, 4, 4) --Раздирание души
local specWarnSoulRend2				= mod:NewSpecialWarningSwitch(259187, "Dps", nil, DBM_COMMON_L.ADDS, 3, 4) --Раздирание души
local specWarnWrackingPain			= mod:NewSpecialWarningInterrupt(250096, "HasInterrupt", nil, nil, 1, 2) --Нестерпимая боль
local specWarnWrackingPainYou		= mod:NewSpecialWarningYou(250096, nil, nil, nil, 1, 2) --Нестерпимая боль
local specWarnSkewer				= mod:NewSpecialWarningDefensive(249919, nil, nil, nil, 3, 2) --Пронзание
local specWarnEchoes				= mod:NewSpecialWarningDodge(250050, nil, nil, nil, 2, 2) --Эхо Шадры
local specWarnGTFO					= mod:NewSpecialWarningGTFO(250036, nil, nil, nil, 1, 8) --Темные отголоски

local timerSoulrend					= mod:NewCastTimer(5, 259187, DBM_COMMON_L.ADDS, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Раздирание души
local timerSoulrendCD				= mod:NewCDCountTimer(38.4, 259187, nil, nil, nil, 3, nil, DBM_COMMON_L.DAMAGE_ICON) --Раздирание души
local timerWrackingPainCD			= mod:NewCDCountTimer(16.7, 250096, nil, nil, nil, 3, nil, DBM_COMMON_L.HEALER_ICON) --Нестерпимая боль 17-23
local timerSkewerCD					= mod:NewCDCountTimer(12, 249919, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON) --Пронзание
local timerEchoesCD					= mod:NewCDCountTimer(31.2, 250050, nil, nil, nil, 3) --Эхо Шадры

local yellSoulRend					= mod:NewYell(259187, nil, nil, nil, "YELL") --Раздирание души
local yellSoulRend2					= mod:NewShortFadesYell(259187, nil, nil, nil, "YELL") --Раздирание души
local yellWrackingPain				= mod:NewYell(250096, nil, nil, nil, "YELL") --Нестерпимая боль

mod.vb.soulCount = 0
mod.vb.wrackCount = 0
mod.vb.skewerCount = 0
mod.vb.echoCount = 0

--Skewer trigger 2.4 ICD
--Echos also triggers 3.5 ICD
--Soulrend triggers 6 ICD
--Wracking pain triggers 1.5 ICD+cast time before interrupt (not worth coding for)
local function updateAllTimers(self, ICD)
	DBM:Debug("updateAllTimers running", 3)
	if timerSoulrendCD:GetRemaining(self.vb.soulCount+1) < ICD then
		local elapsed, total = timerSoulrendCD:GetTime(self.vb.soulCount+1)
		local extend = ICD - (total-elapsed)
		DBM:Debug("timerSoulrendCD extended by: "..extend, 2)
		timerSoulrendCD:Update(elapsed, total+extend, self.vb.soulCount+1)
	end
	if timerWrackingPainCD:GetRemaining(self.vb.wrackCount+1) < ICD then
		local elapsed, total = timerWrackingPainCD:GetTime(self.vb.wrackCount+1)
		local extend = ICD - (total-elapsed)
		DBM:Debug("timerWrackingPainCD extended by: "..extend, 2)
		timerWrackingPainCD:Update(elapsed, total+extend, self.vb.wrackCount+1)
	end
	if timerSkewerCD:GetRemaining(self.vb.skewerCount+1) < ICD then
		local elapsed, total = timerSkewerCD:GetTime(self.vb.skewerCount+1)
		local extend = ICD - (total-elapsed)
		DBM:Debug("timerSkewerCD extended by: "..extend, 2)
		timerSkewerCD:Update(elapsed, total+extend, self.vb.skewerCount+1)
	end
	if timerEchoesCD:GetRemaining(self.vb.echoCount+1) < ICD then
		local elapsed, total = timerEchoesCD:GetTime(self.vb.echoCount+1)
		local extend = ICD - (total-elapsed)
		DBM:Debug("timerEchoesCD extended by: "..extend, 2)
		timerEchoesCD:Update(elapsed, total+extend, self.vb.echoCount+1)
	end
end

function mod:WrackingPainTarget(targetname)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnWrackingPainYou:Show()
		specWarnWrackingPainYou:Play("targetyou")
		yellWrackingPain:Yell()
	else
		warnWrackingPain:Show(targetname)
	end
end

function mod:OnCombatStart(delay)
	self.vb.soulCount = 0
	self.vb.wrackCount = 0
	self.vb.skewerCount = 0
	self.vb.echoCount = 0
	timerWrackingPainCD:Start(3.5-delay, 1)
	timerSkewerCD:Start(5-delay, 1)
	timerSoulrendCD:Start(7-delay, 1)
	timerEchoesCD:Start(15.6-delay, 1)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 249923 or spellId == 259187 then
		self.vb.soulCount = self.vb.soulCount + 1
		timerSoulrendCD:Start(nil, self.vb.soulCount+1)
		if not self:IsNormal() and not self:IsTank() then
			specWarnSoulRend:Show()
			specWarnSoulRend:Play("runout")
		end
		specWarnSoulRend2:Schedule(5)
		specWarnSoulRend2:ScheduleVoice(5, "changetarget")
		timerSoulrend:Start()
		updateAllTimers(self, 6)
	elseif spellId == 250096 then--Can stutter cast, but since it can be kicked on non mythic+, timer can't be moved to success
		self.vb.wrackCount = self.vb.wrackCount + 1
		timerWrackingPainCD:Start(nil, self.vb.wrackCount+1)
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnWrackingPain:Show(args.sourceName)
			specWarnWrackingPain:Play("kickcast")
		else
			self:ScheduleMethod(0.1, "BossTargetScanner", args.sourceGUID, "WrackingPainTarget", 0.1, 7, true)
		end
	elseif spellId == 249919 then
		self.vb.skewerCount = self.vb.skewerCount + 1
		if self:IsTanking("player", "boss1", nil, true) then
			specWarnSkewer:Show()
			specWarnSkewer:Play("defensive")
		end
		timerSkewerCD:Start(nil, self.vb.skewerCount+1)
		updateAllTimers(self, 2.4)
	elseif spellId == 250050 then
		self.vb.echoCount = self.vb.echoCount + 1
		specWarnEchoes:Show()
		specWarnEchoes:Play("watchstep")
		timerEchoesCD:Start(nil, self.vb.echoCount+1)
		updateAllTimers(self, 3.5)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 250036 and args:IsPlayer() and self:AntiSpam(2, 1) then
		specWarnGTFO:Show(args.spellName)
		specWarnGTFO:Play("watchfeet")
	end
end

--Same time as SPELL_CAST_START but has target information on normal
function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg, _, _, _, targetname)
	if msg:find("spell:249924") then
		if targetname then--Normal, only one person affected, name in emote (name isn't in emote in other difficulties)
			if targetname == UnitName("player") then
				specWarnSoulRend:Show()
				specWarnSoulRend:Play("runout")
				yellSoulRend:Yell()
				yellSoulRend2:Countdown(5)
			else
			--	warnSoulRend:Show(targetname)
				warnSoulRend:CombinedShow(0.3, targetname) --тест версия
			end
		end
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 250036 and destGUID == UnitGUID("player") and self:AntiSpam(2, 1) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
