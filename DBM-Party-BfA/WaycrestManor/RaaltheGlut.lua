local mod	= DBM:NewMod(2127, "DBM-Party-BfA", 10, 1021)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260630000000")
mod:SetCreatureID(131863)
mod:SetEncounterID(2115)
mod:SetUsedIcons(8)
mod:SetHotfixNoticeRev(20260714000000)
mod:SetMinSyncRevision(20260714000000)
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
local warnRottenExpulsion			= mod:NewTargetNoFilterAnnounce(264694, 3, nil, nil, 168929) --Волна гнили (Обстрел)
local warnTenderize					= mod:NewCountAnnounce(264923, 2) --Отбивка

local specWarnConsumeAll			= mod:NewSpecialWarningMoveTo(264734, "Tank", nil, DBM_COMMON_L.AOEDAMAGE, 3, 4) --Поглощение (АоЕ)
local specWarnConsumeAll2			= mod:NewSpecialWarningDefensive(264734, "-Tank", nil, DBM_COMMON_L.AOEDAMAGE, 3, 2) --Поглощение (АоЕ)
local specWarnServant				= mod:NewSpecialWarningSwitch(264931, "Dps", nil, DBM_COMMON_L.ADDS, 1, 2) --Призыв слуг
local specWarnTenderize				= mod:NewSpecialWarningDodge(264923, nil, nil, DBM_COMMON_L.FRONTAL, 2, 2) --Отбивка (Фронталка)
local specWarnRottenExpulsion		= mod:NewSpecialWarningMoveAway(264694, nil, nil, DBM_COMMON_L.BOMBING, 4, 2) --Волна гнили (Обстрел)
local specWarnRottenExpulsion2		= mod:NewSpecialWarningDodge(264694, nil, nil, DBM_COMMON_L.BOMBING, 2, 2) --Волна гнили (Обстрел)
local specWarnGTFO					= mod:NewSpecialWarningGTFO(264712, nil, nil, nil, 1, 8) --Волна гнили

local timerServantCD				= mod:NewCDCountTimer(42, 264931, DBM_COMMON_L.ADDS.." (%s)", nil, nil, 1, nil, DBM_COMMON_L.DAMAGE_ICON, nil, 2, 5) --Призыв слуг 42.5
local timerTenderizeCD				= mod:NewCDCountTimer(41.9, 264923, DBM_COMMON_L.FRONTAL.." (%s)", nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Отбивка (Фронталка) 43.7
local timerRottenExpulsionCD		= mod:NewCDCountTimer(20.2, 264694, DBM_COMMON_L.BOMBING.." (%s)", nil, nil, 3) --Волна гнили (Обстрел) 14.6--26 (health based?)

local yellRottenExpulsion			= mod:NewYell(264694, 168929, nil, nil, "YELL") --Волна гнили (Обстрел)

mod:AddSetIconOption("SetIconOnRottenExpulsion", 264694, true, 5, {8}) --Волна гнили (Обстрел)

mod.vb.comboCount = 0
mod.vb.tenderizeCount = 0
mod.vb.rottenCount = 0
mod.vb.servantCount = 0

function mod:OnCombatStart(delay)
	self.vb.comboCount = 0
	self.vb.tenderizeCount = 0
	self.vb.rottenCount = 0
	self.vb.servantCount = 0
	timerRottenExpulsionCD:Start(5-delay, 1) --
	timerTenderizeCD:Start(30-delay, 1) --20.8
	timerServantCD:Start(42-delay, 1) --32.9
end

function mod:RottenExpulsionTarget(targetname)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnRottenExpulsion:Show()
		specWarnRottenExpulsion:Play("runout")
		yellRottenExpulsion:Yell()
	else
		specWarnRottenExpulsion2:Show()
		specWarnRottenExpulsion2:Play("watchstep")
		warnRottenExpulsion:Show(targetname)
	end
	if self.Options.SetIconOnRottenExpulsion then
		self:SetIcon(targetname, 8, 5)
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 264931 then --Призыв слуг
		self.vb.servantCount = self.vb.servantCount + 1
--		local bossHealth = self:GetBossHP(args.sourceGUID)
--		if bossHealth and bossHealth >= 10 then--Only warn to switch to add if boss above 10%, else ignore them
			specWarnServant:Show()
			specWarnServant:Play("killmob")
--		end
		timerServantCD:Start(nil, self.vb.servantCount+1) --42 сек норм от 1 пака треша до 2
	elseif spellId == 264923 then --Отбивка (Фронталка)
		self.vb.comboCount = self.vb.comboCount + 1
		warnTenderize:Show(self.vb.comboCount)
		if self.vb.comboCount == 1 then
			self.vb.tenderizeCount = self.vb.tenderizeCount + 1
			specWarnTenderize:Show()
			specWarnTenderize:Play("shockwave")
			timerTenderizeCD:Start(nil, self.vb.tenderizeCount+1) --41.9 норм от 1 комбо фронталок до 2
			if timerRottenExpulsionCD:GetRemaining(args.sourceGUID) < 12 then
				timerRottenExpulsionCD:AddTime(3, self.vb.rottenCount+1)
			end
		end
		if self.vb.comboCount == 3 then
			self.vb.comboCount = 0
		end
	elseif spellId == 264694 then --Волна гнили (Обстрел)
		self.vb.rottenCount = self.vb.rottenCount + 1
		--5, 29.2, 20.2, 23.1, 20.2 старое
		--5, 14.6, 24.4, 14.6, 27.3 новое
		self:ScheduleMethod(0.1, "BossTargetScanner", args.sourceGUID, "RottenExpulsionTarget", 0.1, 6)
		local timer
		if self.vb.rottenCount % 2 == 0 then
			timer = 24.4 --3, 5, 7
		else
			timer = 14.6 --2, 4, 6
		end
		timerRottenExpulsionCD:Start(timer, self.vb.rottenCount+1)
--[[		if self.vb.rottenCount == 1 then--2, 4, probably 6 --Криво работает на сервере
			timerRottenExpulsionCD:Start(29.2, self.vb.rottenCount+1)
		elseif self.vb.rottenCount == 3 then
			timerRottenExpulsionCD:Start(21.7, self.vb.rottenCount+1)
		else--2, 4, etc
			timerRottenExpulsionCD:Start(20.2, self.vb.rottenCount+1)
		end]]
	elseif spellId == 264734 then --Поглощение
		if self:IsTank() then
			specWarnConsumeAll:Show(DBM_COMMON_L.BOSS)
			specWarnConsumeAll:Play("movetoboss")
		elseif not UnitIsDeadOrGhost("player") then
			specWarnConsumeAll2:Show()
			specWarnConsumeAll2:Play("defensive")
		end
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 264712 and destGUID == UnitGUID("player") and self:AntiSpam(2, 4) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
