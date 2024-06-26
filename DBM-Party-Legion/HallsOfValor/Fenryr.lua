local mod	= DBM:NewMod(1487, "DBM-Party-Legion", 4, 721)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20230708234551")
mod:SetCreatureID(95674, 99868)--First engage, Second engage
mod:SetEncounterID(1807)
mod:SetUsedIcons(8)
mod:DisableEEKillDetection()--ENCOUNTER_END fires a wipe when fenryr casts stealth and runs to new location (P2)
mod:SetHotfixNoticeRev(20230306000000)
--mod.sendMainBossGUID = true--Boss does lots of on fly timer adjustments, lets not overwhelm external handlers just yet

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 196838 196543 197558 196512",
	"SPELL_CAST_SUCCESS 196567 196512 207707 196543",
	"SPELL_AURA_APPLIED 197556 196838",
	"SPELL_AURA_REMOVED 197556 196838",
	"UNIT_DIED"
)

local warnLeap							= mod:NewTargetAnnounce(197556, 2)
local warnPhase2						= mod:NewPhaseAnnounce(2, 2, nil, nil, nil, nil, nil, 2)
local warnFixate						= mod:NewTargetNoFilterAnnounce(196838, 2)
local warnFixateEnded					= mod:NewEndAnnounce(196838, 1)
local warnClawFrenzy					= mod:NewSpellAnnounce(196512, 3, nil, nil, 2)

local specWarnLeap						= mod:NewSpecialWarningMoveAway(197556, nil, nil, nil, 1, 2)
local specWarnHowl						= mod:NewSpecialWarningCast(196543, "SpellCaster", nil, nil, 1, 2) --Пугающий вой
local specWarnFixate					= mod:NewSpecialWarningRun(196838, nil, nil, nil, 4, 2) --Запах крови
local specWarnWolves					= mod:NewSpecialWarningSwitch(-12600, "Tank|Dps", nil, nil, 1, 2) --Эбеновый ворг

local timerLeapCD						= mod:NewCDTimer(31, 197556, nil, nil, nil, 3) --Хищный прыжок
local timerClawFrenzyCD					= mod:NewCDTimer(9.7, 196512, nil, nil, nil, 2, nil, DBM_COMMON_L.HEALER_ICON..DBM_COMMON_L.DEADLY_ICON, nil, 3, 3) --Бешеные когти
local timerHowlCD						= mod:NewCDTimer(31.5, 196543, nil, nil, nil, 2, nil, DBM_COMMON_L.INTERRUPT_ICON) --Пугающий вой
local timerScentCD						= mod:NewCDTimer(37.6, 196838, nil, nil, nil, 7) --Запах крови

local yellLeap							= mod:NewYell(197556, nil, nil, nil, "YELL") --Хищный прыжок
local yellFixate						= mod:NewYell(196838, nil, nil, nil, "YELL") --Запах крови

mod:AddSetIconOption("SetIconOnFixate", 196838, true, 0, {8}) --Запах крови
mod:AddRangeFrameOption(10, 197556)

mod.vb.phase = 1
mod.vb.clawCount = 0
mod.vb.howlCount = 0
mod.vb.leapCount = 0

local allProshlyapationsOfMurchalTimers = {
	[1] = {
		--Пугающий вой
		[196543] = {4.4, 28.8, 28, 32.7, 35.2, 35.3, 35.2, 35.2, 35.2, 35.2, 35.2},
		--Хищный прыжок
		[197558] = {8.3, 35.2, 35.2, 35.2, 35.2, 35.2, 35.1, 35.3},
		--Бешеные когти
		[196512] = {20, 9.7, 9.7, 15.8, 10.4, 9.7, 15, 9.7, 9.7, 15.8, 9.7, 9.7, 15.8, 9.7, 9.7, 15.7, 9.7, 9.7, 15.8},
	},
	[2] = {
		--Пугающий вой
		[196543] = {4.4, 37.4, 40.7, 40.8, 40.7, 40.7, 40.8, 40.7, 40.7, 40.7, 40.7},
		--Хищный прыжок
		[197558] = {9.5, 40.7, 40.7, 40.8, 40.8, 40.7, 40.7, 40.7, 40.7, 40.7, 40.7},
		--Бешеные когти
		[196512] = {20.3, 26.3, 14.3, 26.3, 14.3, 26.4, 14.4, 26.3, 14.3, 26.3, 14.3, 26.3, 14.3, 26.3, 14.3},
	},
}

function mod:FixateTarget(targetname, uId)
	if not targetname then return end
	if self:AntiSpam(5, targetname) then
		if targetname == UnitName("player") then
			specWarnFixate:Show()
			specWarnFixate:Play("runaway")
			specWarnFixate:ScheduleVoice(1, "keepmove")
			yellFixate:Yell()
		else
			warnFixate:Show(targetname)
		end
	end
	if self.Options.SetIconOnFixate then
		self:SetIcon(targetname, 8, 10)
	end
end

function mod:OnCombatStart(delay)
	self.vb.phase = 1
	self.vb.clawCount = 0
	self.vb.howlCount = 0
	self.vb.leapCount = 0
	self:SetWipeTime(5)
	--If howl isn't cast within that 1 second of cooldown window before leap comes off CD, leap takes higher priority and is cast instead and flips order rest of pull
	--Claw frenzy can be 2nd or 3rd as well, depending on spell queue. for most part initial timers can't be fully trusted until first 2 of 3 casts happen and correct them
	timerHowlCD:Start(4.4-delay) --
	timerLeapCD:Start(8.3-delay) --
	timerClawFrenzyCD:Start(20-delay, 1)
end

function mod:OnCombatEnd()
	self:UnregisterShortTermEvents()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 196838 then --Запах крови
		timerScentCD:Start(40.7)
		self:BossTargetScanner(args.sourceGUID, "FixateTarget", 0.2, 6)--Target scanning used to grab target 2-3 seconds faster. Doesn't seem to anymore?
	elseif spellId == 196543 then --Пугающий вой
		self.vb.howlCount = self.vb.howlCount + 1
		specWarnHowl:Show()
		specWarnHowl:Play("stopcast")
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchalTimers, false, self.vb.phase, spellId, self.vb.howlCount+1)
		if timer then
			timerHowlCD:Start(timer, self.vb.howlCount+1)
		end
	elseif spellId == 197558 then --Хищный прыжок
		self.vb.leapCount = self.vb.leapCount + 1
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchalTimers, false, self.vb.phase, spellId, self.vb.leapCount+1)
		if timer then
			timerLeapCD:Start(timer, self.vb.leapCount+1)
		end
	elseif spellId == 196512 and self:AntiSpam(3, 1) then --Бешеные когти
		self.vb.clawCount = self.vb.clawCount + 1
		warnClawFrenzy:Show()
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchalTimers, false, self.vb.phase, spellId, self.vb.clawCount+1)
		if timer then
			timerClawFrenzyCD:Start(timer, self.vb.clawCount+1)
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 196567 then--Stealth (boss retreat)
		--Stop all timers but not combat
		for _, v in ipairs(self.timers) do
			v:Stop()
		end
		--Artificially set no wipe to 30 minutes
		self:SetWipeTime(1800)
		--Scan for Boss to be re-enraged
		self:RegisterShortTermEvents(
			"ENCOUNTER_START"
		)
	elseif spellId == 196543 then --Пугающий вой
		if self.vb.phase == 2 then
			specWarnWolves:Show()
			specWarnWolves:Play("killmob")
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 197556 then
		warnLeap:CombinedShow(0.3, args.destName)
		if args:IsPlayer() then
			specWarnLeap:Show()
			specWarnLeap:Play("runout")
			yellLeap:Yell()
			if self.Options.RangeFrame then
				DBM.RangeCheck:Show(10)
			end
		end
	elseif spellId == 196838 then
		--Backup if target scan failed
		if self:AntiSpam(5, args.destName) then
			if args:IsPlayer() then
				specWarnFixate:Show()
				specWarnFixate:Play("runaway")
				specWarnFixate:ScheduleVoice(1, "keepmove")
			else
				warnFixate:Show(args.destName)
			end
		end
		if self.Options.SetIconOnFixate then
			self:SetIcon(args.destName, 8, 10)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 197556 and args:IsPlayer() and self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	elseif spellId == 196838 and args:IsPlayer() then
		warnFixateEnded:Show()
	end
end

function mod:ENCOUNTER_START(encounterID)
	--Re-engaged, kill scans and long wipe time
	if encounterID == 1807 and self:IsInCombat() then
		self.vb.clawCount = 0
		self.vb.howlCount = 0
		self.vb.leapCount = 0
--		self:SetWipeTime(5)
--		self:UnregisterShortTermEvents()
		self.vb.phase = 2
		warnPhase2:Show()
		warnPhase2:Play("ptwo")
		timerHowlCD:Start(4.4)
		timerLeapCD:Start(9.5)--9.3-15
		timerClawFrenzyCD:Start(20.3, 1)--12-45 (massive variation cause if it's not cast immediately it gets spell queued behind leap, howl and then casts at 22-25 unless scent also spell queues it then it's 42-45sec ater p2 start
		timerScentCD:Start(23.7)--20-27.8
	end
end

function mod:UNIT_DIED(args)
	if self:GetCIDFromGUID(args.destGUID) == 99868 then
		DBM:EndCombat(self)
	end
end
