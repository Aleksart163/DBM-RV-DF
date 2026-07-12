local mod	= DBM:NewMod(2535, "DBM-Party-Dragonflight", 9, 1209)
local L		= mod:GetLocalizedStrings()

mod.statTypes = "normal,heroic,mythic,challenge"--No Follower dungeon

mod:SetRevision("20260630000000")
mod:SetMultiIDSingleBoss()
mod:SetCreatureID(198997, 201792, 201788, 201790)--It's technically just one creature animated 3 others, but checkbossHp will query all and return highest health for boss health percent
mod:SetEncounterID(2668)
--mod:SetUsedIcons(1, 2, 3)
--mod:SetBossHPInfoToHighest()--may not be needed due to shared/synced health pools
mod:SetHotfixNoticeRev(20260714000000)
mod:SetMinSyncRevision(20260714000000)
mod.respawnTime = 29
--mod.sendMainBossGUID = true--sendMainBossGUID is not sent because of stage 3 split

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 408029 406886 407159 408141",
	"SPELL_CAST_SUCCESS 408029 407978",
	"SPELL_AURA_APPLIED 407147 415097 415114 407406 418346",
	"SPELL_AURA_REMOVED 407406 415097 415114"
--	"SPELL_PERIODIC_DAMAGE",
--	"SPELL_PERIODIC_MISSED"
)

--[[
(ability.id = 406886 or ability.id = 407159 or ability.id = 408029 or ability.id = 408141) and type = "begincast"
 or ability.id = 407978 and type = "cast"
 or ability.id = 415097 or ability.id = 415114
 or (source.type = "NPC" and source.firstSeen = timestamp) and (source.id = 201792 or source.id = 201788 or source.id = 201790) or (target.type = "NPC" and target.firstSeen = timestamp) and (target.id = 201792 or target.id = 201788 or target.id = 201790)
 or type = "death" and (target.id = 201792 or target.id = 201788 or target.id = 201790)
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
 --TODO, maybe target scan frost to be slightly faster? Can also use applied of 408084 but that's even slower than success
 --TODO, Possibly transition stages on REMOVED not applied?
 --TODO, attach GUID to timers in a way that's compat with multi target
 --TODO, need much longer logs to fix many of timers again
--]]
local warnPhase								= mod:NewPhaseChangeAnnounce(2, 2, nil, nil, nil, nil, nil, 2)
local warnCorrosion							= mod:NewTargetNoFilterAnnounce(407406, 3) --Коррозия
local warnCorruptedMind						= mod:NewTargetNoFilterAnnounce(418346, 4, nil, nil, 362075) --Зараженный разум (подчинение)

local specWarnCorrosiveInfusion				= mod:NewSpecialWarningDodgeCount(406886, nil, nil, DBM_COMMON_L.BOMBING, 2, 2) --Разъедающее насыщение (Обстрел)
local specWarnCorrosion						= mod:NewSpecialWarningYou(407406, nil, nil, nil, 3, 2) --Коррозия
local specWarnCorrosionClear				= mod:NewSpecialWarningMoveTo(407406, nil, nil, nil, 4, 2) --Коррозия
local specWarnReclamation					= mod:NewSpecialWarningCount(407159, nil, nil, DBM_COMMON_L.FRONTAL, 2, 2) --Возвращение гнили
local specWarnNecroticWinds					= mod:NewSpecialWarningDodge(407978, nil, nil, DBM_COMMON_L.PUSHBACK, 1, 2) --Некротические ветра (Отталкивание)
local specWarnNecrofrost					= mod:NewSpecialWarningSwitch(408029, "Dps", nil, DBM_COMMON_L.ADD, 1, 2) --Некрохлад
local specWarnIncinBlightBreath				= mod:NewSpecialWarningDodge(408141, nil, nil, DBM_COMMON_L.FRONTAL, 1, 2) --Испепеляющее гнилостное дыхание (Фронталка)
local specWarnGTFO							= mod:NewSpecialWarningGTFO(407147, nil, nil, nil, 1, 8) --Просачивающаяся гниль

local timerCorrosiveInfusionCD				= mod:NewCDCountTimer(19.4, 406886, DBM_COMMON_L.BOMBING.." (%s)", nil, nil, 3) --Разъедающее насыщение (Обстрел)
local timerBlightReclamationCD				= mod:NewCDCountTimer(19.4, 407159, DBM_COMMON_L.FRONTAL.." (%s)", nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON) --Возвращение гнили
local timerNecroticWindsCD					= mod:NewCDCountTimer(31.5, 407978, DBM_COMMON_L.PUSHBACK.." (%s)", nil, nil, 2) --Некротические ветра (Отталкивание)
local timerNecrofrostCD						= mod:NewCDCountTimer(19.4, 408029, DBM_COMMON_L.ADD.." (%s)", nil, nil, 3, nil, DBM_COMMON_L.DAMAGE_ICON) --Некрохлад
local timerIncineratingBlightbreathCD		= mod:NewCDCountTimer(15.8, 408141, DBM_COMMON_L.FRONTAL.." (%s)", nil, nil, 3) --Испепеляющее гнилостное дыхание (Фронталка)

local yellCorrosion							= mod:NewYell(407406, nil, nil, nil, "YELL") --Коррозия
local yellCorrosionFades					= mod:NewShortFadesYell(407406, nil, nil, nil, "YELL") --Коррозия WHen countdown shows, it needs to be passed, so it's a share yell not an avoid one, IE red text
local yellNecrofrost						= mod:NewYell(408029, DBM_COMMON_L.ADD, nil, nil, "YELL") --Некрохлад

mod.vb.corrosiveCount = 0
mod.vb.reclaimCount = 0
mod.vb.windsCount = 0--Reused for necrofrost
mod.vb.fireBreathCount = 0

function mod:OnCombatStart(delay)
	self.vb.corrosiveCount = 0
	self.vb.reclaimCount = 0
	self.vb.windsCount = 0
	self.vb.fireBreathCount = 0
	self:SetStage(1)
	timerCorrosiveInfusionCD:Start(4.5-delay, 1)
	timerBlightReclamationCD:Start(14.2-delay, 1)
end

local function checkDebuffPass(self)
	--Next pass is to tank
	if timerBlightReclamationCD:GetRemaining(self.vb.reclaimCount+1) < 6 then
		--Have debuff, and not the tank, and debuff will expire after next Blight Reclamation, it should go to the tank
		if not self:IsTanking("player", "boss1", nil, true) then
			specWarnCorrosionClear:Show(DBM_COMMON_L.TANK)
			specWarnCorrosionClear:Play("movetotank")
		end
	--Next pass is NOT to tank
	else
		--No tank check, because this condition will run if 5 seconds left on debuff but > 5 seconds til breath, so tank has to pass it too
		specWarnCorrosionClear:Show(DBM_COMMON_L.ALLY)
		specWarnCorrosionClear:Play("gathershare")--Will be changed to "passdebuff" or something later?
	end
end

local function checkProshlyapOfMurchal(self) --Старт таймеров 2 фазы
	timerCorrosiveInfusionCD:Start(6.1, 1)
	timerNecroticWindsCD:Start(19.7, 1)
	timerBlightReclamationCD:Start(16.7, 1) --
	DBM:Debug("Murchal proshlyap (Начался бой с Анзон (Фаза 2))", 2)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 406886 then
		self.vb.corrosiveCount = self.vb.corrosiveCount + 1
		specWarnCorrosiveInfusion:Show(self.vb.corrosiveCount)
		specWarnCorrosiveInfusion:Play("watchstep")
		local timer
		if self:GetStage(1) then
			timer = 16.2 --Было 17
		elseif self:GetStage(2) then
			timer = 31.5
		else--Stage 3
			timer = 61.9
			--Update min timers on abilities affected by this
			if timerIncineratingBlightbreathCD:GetRemaining(self.vb.fireBreathCount+1) < 8 then
				local elapsed, total = timerIncineratingBlightbreathCD:GetTime(self.vb.fireBreathCount+1)
				local extend = 8 - (total-elapsed)
				DBM:Debug("timerIncineratingBlightbreathCD extended by: "..extend, 2)
				timerIncineratingBlightbreathCD:Update(elapsed, total+extend, self.vb.fireBreathCount+1)
			end
			if timerNecrofrostCD:GetRemaining(self.vb.windsCount+1) < 15.7 then
				local elapsed, total = timerNecrofrostCD:GetTime(self.vb.windsCount+1)
				local extend = 15.7 - (total-elapsed)
				DBM:Debug("timerNecrofrostCD extended by: "..extend, 2)
				timerNecrofrostCD:Update(elapsed, total+extend, self.vb.windsCount+1)
			end
		end
		timerCorrosiveInfusionCD:Start(timer, self.vb.corrosiveCount+1)
	elseif spellId == 407159 then
		self.vb.reclaimCount = self.vb.reclaimCount + 1
		specWarnReclamation:Show(self.vb.reclaimCount)
		specWarnReclamation:Play("shockwave")--Shockwave used so it doesn't use same voice as other breath
		local timer
		if self:GetStage(1) then
			timer = 17
		elseif self:GetStage(2) then
			timer = 31.5
			--rule only applies to stage 2. If time left on corrosive is less than 5.2, it's extended. this is what causes it to be 34 instead of 31.5 sometimes
			if timerIncineratingBlightbreathCD:GetRemaining(self.vb.corrosiveCount+1) < 5.2 then
				local elapsed, total = timerIncineratingBlightbreathCD:GetTime(self.vb.corrosiveCount+1)
				local extend = 5.2 - (total-elapsed)
				DBM:Debug("timerIncineratingBlightbreathCD extended by: "..extend, 2)
				timerIncineratingBlightbreathCD:Update(elapsed, total+extend, self.vb.corrosiveCount+1)
			end
		else
			timer = 61.9
		end
		timerBlightReclamationCD:Start(timer, self.vb.reclaimCount+1)
	elseif spellId == 408029 then
		self.vb.windsCount = self.vb.windsCount + 1
		--The timers that are delayed will be auto corrected by Corrosive cast
		timerNecrofrostCD:Start(19.4, self.vb.windsCount+1)
	elseif spellId == 408141 then
		self.vb.fireBreathCount = self.vb.fireBreathCount + 1
		specWarnIncinBlightBreath:Show()
		specWarnIncinBlightBreath:Play("breathsoon")
		--The timers that are delayed will be auto corrected by Corrosive cast
		timerIncineratingBlightbreathCD:Start(15.8, self.vb.fireBreathCount+1)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 408029 then
		if args:IsPlayer() then
			yellNecrofrost:Yell()
		else
			specWarnNecrofrost:Show()
			specWarnNecrofrost:Play("targetchange")
		end
	elseif spellId == 407978 then
		self.vb.windsCount = self.vb.windsCount + 1
		specWarnNecroticWinds:Show()
		specWarnNecroticWinds:Play("aesoon")
		specWarnNecroticWinds:ScheduleVoice(1.5, "watchstep")
		timerNecroticWindsCD:Start(31.5, self.vb.windsCount+1)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 407147 and args:IsPlayer() and self:AntiSpam(3, 2) then
		specWarnGTFO:Show(args.spellName)
		specWarnGTFO:Play("watchfeet")
	elseif spellId == 415097 then --Тлетворное перенаправление (На Гнили, до появления 1-го дракона)
		self:SetStage(2)
		self.vb.corrosiveCount = 0
		self.vb.reclaimCount = 0
		warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(2))
		warnPhase:Play("ptwo")
		timerCorrosiveInfusionCD:Stop()
		timerBlightReclamationCD:Stop()
		self:Schedule(2, checkProshlyapOfMurchal, self)
	elseif spellId == 415114 then --Тлетворное перенаправление (На Гнили, до появления 2ых драконов)
		self:SetStage(3)
		self.vb.corrosiveCount = 0
		self.vb.reclaimCount = 0
		self.vb.windsCount = 0
		warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(3))
		warnPhase:Play("pthree")
		timerCorrosiveInfusionCD:Stop()
		timerBlightReclamationCD:Stop()
		timerNecroticWindsCD:Stop()
	elseif spellId == 407406 then --Коррозия
		if args:IsPlayer() and self:AntiSpam(2, 2) then
			specWarnCorrosion:Show()
			specWarnCorrosion:Play("targetyou")
			yellCorrosion:Yell()
			yellCorrosionFades:Countdown(spellId, 3)
			self:Unschedule(checkDebuffPass)
			self:Schedule(7, checkDebuffPass, self)--Check pass conditions 5 seconds til expire
		else
			warnCorrosion:CombinedShow(0.5, args.destName)
		end
	elseif spellId == 418346 then
		warnCorruptedMind:Show(args.destName)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 407406 then --Коррозия
		if args:IsPlayer() then
			yellCorrosionFades:Cancel()
			self:Unschedule(checkDebuffPass)
		end
	elseif spellId == 415097 then --Тлетворное перенаправление (начало Фазы 2)
		--Starting timers here better
		--Включить, если заработает
		DBM:Debug("Murchal proshlyap (Таймеры заработали, необходимо поправить)", 2)
	--	warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(2))
	--	warnPhase:Play("ptwo")
	--	timerCorrosiveInfusionCD:Start(6.1, 1)
	--	timerNecroticWindsCD:Start(16, 1)
	--	timerBlightReclamationCD:Start(30.1, 1)
	elseif spellId == 415114 then --Тлетворное перенаправление (начало Фазы 3)
		--Starting timers here better
		timerCorrosiveInfusionCD:Start(14.5, 1) --Выглядит норм
		timerIncineratingBlightbreathCD:Start(25, 1) --было 22.8
		timerNecrofrostCD:Start(30, 1) --было 31.4 
		timerBlightReclamationCD:Start(20.9, 1) --Выглядит норм (Было 64)
		DBM:Debug("Murchal proshlyap (Начался бой с Дажак и Лозкелет (Фаза 3))", 2)
	end
end

--[[
function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 386201 and destGUID == UnitGUID("player") and self:AntiSpam(2, 4) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
--]]
