local mod	= DBM:NewMod(2500, "DBM-Raids-Dragonflight", 3, 1200)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240426070000")
mod:SetCreatureID(190496)
mod:SetEncounterID(2639)
mod:SetUsedIcons(8)
mod:SetHotfixNoticeRev(20240426070000)
--mod:SetMinSyncRevision(20211203000000)
mod.respawnTime = 29

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 380487 377166 377505 383073 376279 396351",
	"SPELL_AURA_APPLIED 386352 381253 376276 391592",
	"SPELL_AURA_APPLIED_DOSE 376276",
	"SPELL_AURA_REMOVED 386352 381253 391592"
)

--[[
(ability.id = 380487 or ability.id = 377166 or ability.id = 377505 or ability.id = 383073 or ability.id = 376279 or ability.id = 396351) and type = "begincast"
--]]
local warnRockBlast								= mod:NewTargetNoFilterAnnounce(380487, 4) --Каменный выброс
local warnAwakenedEarth							= mod:NewTargetNoFilterAnnounce(381253, 3)
local warnConcussiveSlam						= mod:NewStackAnnounce(376279, 2, nil, "Tank|Healer") --Оглушающий удар
local warnConcussiveSlam2						= mod:NewTargetNoFilterAnnounce(376279, 4) --Оглушающий удар

local specWarnRockBlast							= mod:NewSpecialWarningYou(380487, nil, nil, nil, 3, 4) --Каменный выброс
local specWarnBrutalReverberation				= mod:NewSpecialWarningDodge(386400, nil, nil, nil, 2, 2)
local specWarnAwakenedEarth						= mod:NewSpecialWarningYou(381253, nil, nil, nil, 1, 4) --Пробужденная земля
local specWarnResonatingAnnihilation			= mod:NewSpecialWarningCount(377166, nil, 307421, nil, 2, 2) --Резонирующая аннигиляция
local specWarnShatteringImpact					= mod:NewSpecialWarningDodge(383073, nil, nil, nil, 2, 2) --Дробящий удар
local specWarnConcussiveSlam					= mod:NewSpecialWarningDefensive(376279, nil, nil, nil, 3, 2) --Оглушающий удар
local specWarnConcussiveSlamTaunt				= mod:NewSpecialWarningTaunt(376279, nil, nil, nil, 1, 2) --Оглушающий удар
local specWarnFrenziedDevastation				= mod:NewSpecialWarningSpell(377505, nil, nil, nil, 3, 2) --Бешеное опустошение
local specWarnInfusedFallout					= mod:NewSpecialWarningYou(391592, nil, nil, nil, 1, 2) --Заряженное облако пыли
local specWarnGTFO								= mod:NewSpecialWarningGTFO(382458, nil, nil, nil, 1, 8)

local timerInfusedFalloutCD						= mod:NewNextCountTimer(35, 391592, nil, nil, nil, 3, nil, DBM_COMMON_L.MYTHIC_ICON) --Заряженное облако пыли
local timerRockBlastCD							= mod:NewNextCountTimer(35, 380487, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Каменный выброс
local timerResonatingAnnihilationCD				= mod:NewNextCountTimer(96.4, 377166, 307421, nil, nil, 7, nil, nil, nil, 1, 5) --Резонирующая аннигиляция
local timerResonatingAnnihilation				= mod:NewCastTimer(5.5, 377166, 307421, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Резонирующая аннигиляция
local timerShatteringImpactCD					= mod:NewNextCountTimer(35, 383073, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Дробящий удар
local timerConcussiveSlamCD						= mod:NewNextCountTimer(35, 376279, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON) --Оглушающий удар
local timerFrenziedDevastationCD				= mod:NewNextTimer(387.9, 377505, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON) --Бешеное опустошение

local yellConcussiveSlam						= mod:NewShortYell(376279, nil, nil, nil, "YELL") --Оглушающий удар
local yellInfusedFallout						= mod:NewIconRepeatYell(391592, nil, nil, nil, "YELL") --Заряженное облако пыли
local yellRockBlast								= mod:NewShortYell(380487, nil, nil, nil, "YELL") --Каменный выброс
local yellRockBlastFades						= mod:NewShortFadesYell(380487, nil, nil, nil, "YELL") --Каменный выброс
local yellAwakenedEarth							= mod:NewShortPosYell(381253, nil, nil, nil, "YELL") --Пробужденная земля
local yellAwakenedEarthFades					= mod:NewIconFadesYell(381253, nil, nil, nil, "YELL") --Пробужденная земля

mod:AddSetIconOption("SetIconOnRockBlast", 380487, true, false, {8}) --Каменный выброс
mod:AddSetIconOption("SetIconOnConcussiveSlam", 376279, true, 0, {8}) --Оглушающий удар
--mod:AddInfoFrameOption(361651, true)--Likely will be used for dust
--mod:AddSetIconOption("SetIconOnAwakenedEarth", 381253, true, false, {1, 2, 3, 4, 5, 6, 7, 8})

--mod.vb.rockIcon = 1
mod.vb.awakenedIcon = 1
mod.vb.annihilationCount = 0
mod.vb.rockCount = 0
mod.vb.slamCount = 0
mod.vb.impactCount = 0
mod.vb.infusedCount = 0
mod.vb.frenziedStarted = false
local ProshlyapMurchalya = nil
local difficultyName = "other"
local allTimers = {
	["mythic"] = {
		--Infused Fallout (Mythic)
		[396351] = {28.1, 42, 25.4, 30.7, 40.9, 24.6, 29.1, 43.3, 23.4, 29.1},--Missing some data
		--Оглушающий удар
		[376279] = {12, 22, 20.9, 22, 31.5, 21.9, 21, 21.9, 31.5, 21.9, 21, 21.9, 31.5, 21.9, 31.5, 5.5, 2.5, 13.5}, --С последними прошляпами Мурчаля и его подпивасов
		--Rock Blast
		[380487] = {3, 43, 53.5, 42.9, 53.4, 43, 53.4, 42.9},--Final cast guessed based on pattern
		--Дробящий удар
		[383073] = {23, 42.9, 53.4, 42.9, 53.5, 42.9, 53.5, 45.3},--Final cast guessed based on pattern
	},
	["other"] = {
		--Concussive Slam
--		[376279] = {14.0, 19.9, 22.0, 19.9, 34.5, 20.0, 22.0, 20.0, 34.4, 20.0, 22.0, 20.0, 34.5, 19.9, 22.0, 20.0},--Old beta timers
		[376279] = {16.0, 18.0, 23.9, 17.9, 36.5, 17.9, 23.9, 17.9, 36.5, 17.9, 23.9, 17.9, 36.4, 17.9, 23.9, 17.9},--New Retail
		--Rock Blast
		[380487] = {6.0, 41.9, 54.4, 41.9, 54.4, 41.9, 54.4, 42.0},
		--Shattering Impact
		[383073] = {27.0, 42.0, 54.4, 42.0, 54.4, 42.0, 54.4, 42.0},
	},
}

function mod:ConcussiveSlamTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnConcussiveSlam:Show()
		specWarnConcussiveSlam:Play("defensive")
		yellConcussiveSlam:Yell()
	else
		warnConcussiveSlam2:Show(targetname)
	end
	if self.Options.SetIconOnConcussiveSlam then
		self:SetIcon(targetname, 8, 3)
	end
end

local function yellRepeater(self, text, repeatTotal)
	repeatTotal = repeatTotal + 1
	if ProshlyapMurchalya then
		yellInfusedFallout:Yell(text)
	end
	self:Schedule(2, yellRepeater, self, text, repeatTotal)
end

function mod:OnCombatStart(delay)
	ProshlyapMurchalya = false
	self.vb.annihilationCount = 0
	self.vb.rockCount = 0
	self.vb.slamCount = 0
	self.vb.impactCount = 0
	self.vb.frenziedStarted = false
	if self:IsMythic() then
		difficultyName = "mythic"
		self.vb.infusedCount = 0
		timerRockBlastCD:Start(3-delay, 1)
		timerInfusedFalloutCD:Start(28.1-delay, 1)
		timerConcussiveSlamCD:Start(12-delay, 1)
		timerShatteringImpactCD:Start(23-delay, 1)
		timerResonatingAnnihilationCD:Start(88-delay, 1)
		timerFrenziedDevastationCD:Start(385.9-delay)
	else
		difficultyName = "other"
		timerRockBlastCD:Start(6-delay, 1)
		timerConcussiveSlamCD:Start(16-delay, 1)
		timerShatteringImpactCD:Start(27-delay, 1)
		timerResonatingAnnihilationCD:Start(90-delay, 1)
		timerFrenziedDevastationCD:Start(387.9-delay)
	end
	if not self:IsTrivial() then
		self:RegisterShortTermEvents(
			"SPELL_PERIODIC_DAMAGE 382458",
			"SPELL_PERIODIC_MISSED 382458"
		)
	end
end

function mod:OnCombatEnd()
	self:UnregisterShortTermEvents()
--	if self.Options.InfoFrame then
--		DBM.InfoFrame:Hide()
--	end
end

function mod:OnTimerRecovery()
	if self:IsMythic() then
		difficultyName = "mythic"
	else
		difficultyName = "other"
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 380487 then
--		self.vb.rockIcon = 1
		self.vb.awakenedIcon = 1
		self.vb.rockCount = self.vb.rockCount + 1
		local timer = self:GetFromTimersTable(allTimers, difficultyName, false, spellId, self.vb.rockCount+1)
		if timer then
			timerRockBlastCD:Start(timer, self.vb.rockCount+1)
		end
	elseif spellId == 377166 then
		self.vb.annihilationCount = self.vb.annihilationCount + 1
		specWarnResonatingAnnihilation:Show(self.vb.annihilationCount)
		specWarnResonatingAnnihilation:Play("specialsoon")
		if not self:IsMythic() then
			if self.vb.annihilationCount < 4 then
				timerResonatingAnnihilationCD:Start(nil, self.vb.annihilationCount+1)
			end
			timerResonatingAnnihilation:Start(6.5)
		else
			if self.vb.annihilationCount == 3 then
				timerResonatingAnnihilationCD:Start(98.5, self.vb.annihilationCount+1)
			elseif self.vb.annihilationCount == 4 then
				timerResonatingAnnihilationCD:Stop()
			else
				timerResonatingAnnihilationCD:Start(nil, self.vb.annihilationCount+1)
			end
			timerResonatingAnnihilation:Start()
		end
		if self.vb.annihilationCount == 4 then
			self:UnregisterShortTermEvents()
		end
	elseif spellId == 377505 and not self.vb.frenziedStarted then
		self.vb.frenziedStarted = true
		specWarnFrenziedDevastation:Show()
		specWarnFrenziedDevastation:Play("stilldanger")
	elseif spellId == 383073 then
		self.vb.impactCount = self.vb.impactCount + 1
		specWarnShatteringImpact:Show()
		specWarnShatteringImpact:Play("watchstep")
		local timer = self:GetFromTimersTable(allTimers, difficultyName, false, spellId, self.vb.impactCount+1)
		if timer then
			timerShatteringImpactCD:Start(timer, self.vb.impactCount+1)
		end
	elseif spellId == 376279 then
		self.vb.slamCount = self.vb.slamCount + 1
		self:BossTargetScanner(args.sourceGUID, "ConcussiveSlamTarget", 0.1, 2)
		local timer = self:GetFromTimersTable(allTimers, difficultyName, false, spellId, self.vb.slamCount+1)
		if timer then
			timerConcussiveSlamCD:Start(timer, self.vb.slamCount+1)
		end
	elseif spellId == 396351 then
		self.vb.infusedCount = self.vb.infusedCount + 1
		local timer = self:GetFromTimersTable(allTimers, difficultyName, false, spellId, self.vb.infusedCount+1)
		if timer then
			timerInfusedFalloutCD:Start(timer, self.vb.infusedCount+1)
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 386352 then
		if args:IsPlayer() then
			specWarnRockBlast:Show()
			specWarnRockBlast:Play("targetyou")--"mm"..icon
			yellRockBlast:Yell()
			yellRockBlastFades:Countdown(5)
		else
			warnRockBlast:Show(args.destName)
		end
		if self.Options.SetIconOnRockBlast then
			self:SetIcon(args.destName, 8, 5)
		end
	elseif spellId == 381253 then
		local icon = self.vb.awakenedIcon
	--[[	if self.Options.SetIconOnAwakenedEarth then
			self:SetIcon(args.destName, icon)
		end]]
		if args:IsPlayer() then
			specWarnAwakenedEarth:Show()
			specWarnAwakenedEarth:Play("targetyou")
			yellAwakenedEarth:Yell(icon, icon)
			yellAwakenedEarthFades:Countdown(5, nil, icon)
		end
		warnAwakenedEarth:CombinedShow(0.5, args.destName)
		self.vb.awakenedIcon = self.vb.awakenedIcon + 1
	elseif spellId == 376276 and not args:IsPlayer() then
		local amount = args.amount or 1
		if amount >= 2 then
			local _, _, _, _, _, expireTime = DBM:UnitDebuff("player", spellId)
			local remaining
			if expireTime then
				remaining = expireTime-GetTime()
			end
			local timer = (self:GetFromTimersTable(allTimers, difficultyName, false, 376279, self.vb.slamCount+1) or 17.9) - 5
			if (not remaining or remaining and remaining < timer) and not UnitIsDeadOrGhost("player") and not self:IsHealer() then
				specWarnConcussiveSlamTaunt:Show(args.destName)
				specWarnConcussiveSlamTaunt:Play("tauntboss")
			end
		else
			warnConcussiveSlam:Show(args.destName, amount)
		end
	elseif spellId == 391592 then
		if args:IsPlayer() then
			specWarnInfusedFallout:Show()
			specWarnInfusedFallout:Play("targetyou")
			yellInfusedFallout:Yell(7, "")
			self:Unschedule(yellRepeater)
			yellRepeater(self, 7, 0)
			ProshlyapMurchalya = true
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 386352 then
		if self:AntiSpam(3, 1) then
			specWarnBrutalReverberation:Show()
			specWarnBrutalReverberation:Play("watchstep")
		end
		if args:IsPlayer() then
			yellRockBlastFades:Cancel()
		end
	elseif spellId == 381253 then
		if args:IsPlayer() then
			yellAwakenedEarthFades:Cancel()
		end
	--[[	if self.Options.SetIconOnAwakenedEarth then
			self:SetIcon(args.destName, 0)
		end]]
	elseif spellId == 391592 then
		if args:IsPlayer() then
			self:Unschedule(yellRepeater)
			ProshlyapMurchalya = false
		end
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 382458 and destGUID == UnitGUID("player") and self:AntiSpam(2, 4) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
