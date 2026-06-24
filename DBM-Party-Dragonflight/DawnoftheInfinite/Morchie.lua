local mod	= DBM:NewMod(2536, "DBM-Party-Dragonflight", 9, 1209)
local L		= mod:GetLocalizedStrings()

mod.statTypes = "normal,heroic,mythic,challenge"--No Follower dungeon

mod:SetRevision("20240206052800")
mod:SetCreatureID(198999)
mod:SetEncounterID(2671)
mod:SetUsedIcons(1, 2, 3, 4, 5, 6)
mod:SetHotfixNoticeRev(20240205000000)
mod:SetMinSyncRevision(20240205000000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 404916 403891 404364 405279 406481 407504",
	"SPELL_SUMMON 403902",
	"SPELL_AURA_APPLIED 401200 401667",--412768
	"SPELL_AURA_REMOVED 401200",
	"SPELL_DAMAGE 412769",
	"SPELL_MISSED 412769"
)

--[[
(ability.id = 404916 or ability.id = 403891 or ability.id = 405279 or ability.id = 406481 or ability.id = 407504) and type = "begincast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
 or ability.id = 404364 and type = "begincast"
--]]
--NOTE:, based on logs, tank can NOT sidestep Sand Blast, so warning is using generic text cause tank positions, rest avoid
--TODO, Initial data (literally just 2 pulls sadly, suggests timers are sequenced in a fixed pattern. If that's case then mod needs some LONG pulls to populate tables
--TODO, announce https://www.wowhead.com/ptr-2/spell=413208/sand-buffeted for healers?
--TODO, nameplate aura on trapped familar face? need to see how good visual is for it first
--TODO, detect when your add breaks free from trap and warn you it's lose again?
--TODO Familiar Faces timers
local warnMoreProblems								= mod:NewCastAnnounce(403891, 3) --Новые проблемы!
local warnDragonBreath								= mod:NewCastAnnounce(404364, 4, nil, nil, nil, 18357) --Дыхание дракона (Дыхание)
local warnFamiliarFaces								= mod:NewCountAnnounce(405279, 3) --Знакомые лица
local warnFixate									= mod:NewYouAnnounce(401200, 4) --Сосредоточение внимания
local warnTimeStasis								= mod:NewTargetNoFilterAnnounce(401667, 4) --Временной стазис

local specWarnSandBlast								= mod:NewSpecialWarningDefensive(404916, nil, nil, DBM_COMMON_L.FRONTAL, 2, 2) --Песчаный вихрь (Фронталка)
local specWarnSandBlast2							= mod:NewSpecialWarningDodge(404916, nil, nil, DBM_COMMON_L.FRONTAL, 2, 2) --Песчаный вихрь (Фронталка)
local specWarnMoreProblems							= mod:NewSpecialWarningSpell(403891, nil, nil, nil, 3, 4) --Новые проблемы!
local specWarnDragonBreath							= mod:NewSpecialWarningRun(404364, nil, 18357, nil, 4, 4) --Дыхание дракона (Дыхание)
local specWarnTimeTraps								= mod:NewSpecialWarningDodgeCount(406481, nil, nil, nil, 2, 2) --Временные ловушки
local specWarnGTFO									= mod:NewSpecialWarningGTFO(412769, nil, nil, nil, 1, 8) --Безвременное разложение

local timerSandBlastCD								= mod:NewCDCountTimer(21.8, 404916, DBM_COMMON_L.FRONTAL.." (%s)", nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON) --Песчаный вихрь (Фронталка) 21.8-38.8
local timerMoreProblemsCD							= mod:NewCDCountTimer(39.7, 403891, nil, nil, nil, 7, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Новые проблемы!
local timerFamiliarFacesCD							= mod:NewCDCountTimer(23, 405279, DBM_COMMON_L.ADDS.." (%s)", nil, nil, 1, nil, nil, nil, 2, 3) --Знакомые лица
local timerTimeTrapsCD								= mod:NewCDCountTimer(50.9, 406481, nil, nil, nil, 3) --Временные ловушки
local timerDragonBreath								= mod:NewCastTimer(8, 404364, 18357, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Дыхание дракона (Дыхание)

local yellTimeStasis								= mod:NewShortYell(401667, nil, nil, nil, "YELL") --Временной стазис
local yellSandBlast									= mod:NewShortYell(404916, nil, nil, nil, "YELL") --Песчаный вихрь

--mod:AddInfoFrameOption(391977, true)
mod:AddSetIconOption("SetIconOnImages", 403891, true, 5, {1, 2, 3, 4, 5, 6})
mod:AddNamePlateOption("NPAuraOnFixate", 401200)

local askShown = false
--local myGUIDAdd = nil
mod.vb.blastCount = 0
mod.vb.problemsCount = 0
mod.vb.problemIcons = 1
mod.vb.facesCount = 0
mod.vb.trapsCount = 0
--Even on a +25 I could not find a pull longer than this
local allTimers = {--Timers up to 3:43 for 10.2+ (with late october timer changes).
	--Песчаный вихрь
	[404916] = {3, 27, 19.9, 28.9, 12, 12, 11.9, 24, 11.9, 12.0, 12.0, 24.0, 12.0, 12.0},
	--Новые проблемы!
	[403891] = {10, 50, 60, 60, 60},
	--Временные ловушки
	[406481] = {36, 48, 24, 47.9, 48.0},
	--Знакомые лица
	[405279] = {43, 52.9, 48, 23.9, 48.0, 48.0, 24.0},
}

--[[
local function updateAllTimers(self, ICD)
	DBM:Debug("updateAllTimers running", 3)
	--Abilities that exist in P1 and P2
	if timerSandBlastCD:GetRemaining(self.vb.blastCount+1) < ICD then
		local elapsed, total = timerSandBlastCD:GetTime(self.vb.blastCount+1)
		local extend = ICD - (total-elapsed)
		DBM:Debug("timerSandBlastCD extended by: "..extend, 2)
		timerSandBlastCD:Update(elapsed, total+extend, self.vb.blastCount+1)
	end
	if timerMoreProblemsCD:GetRemaining(self.vb.problemIcons+1) < ICD then
		local elapsed, total = timerMoreProblemsCD:GetTime(self.vb.problemIcons+1)
		local extend = ICD - (total-elapsed)
		DBM:Debug("timerMoreProblemsCD extended by: "..extend, 2)
		timerMoreProblemsCD:Update(elapsed, total+extend, self.vb.problemIcons+1)
	end
	if timerTimeTrapsCD:GetRemaining(self.vb.trapsCount+1) < ICD then
		local elapsed, total = timerTimeTrapsCD:GetTime(self.vb.trapsCount+1)
		local extend = ICD - (total-elapsed)
		DBM:Debug("timerTimeTrapsCD extended by: "..extend, 2)
		timerTimeTrapsCD:Update(elapsed, total+extend, self.vb.trapsCount+1)
	end
end
--]]

function mod:OnCombatStart(delay)
	askShown = false
	self.vb.blastCount = 0
	self.vb.problemsCount = 0
	self.vb.facesCount = 0
	self.vb.trapsCount = 0
	timerSandBlastCD:Start(3-delay, 1)
	timerMoreProblemsCD:Start(10-delay, 1)
	timerTimeTrapsCD:Start(36-delay, 1)
	timerFamiliarFacesCD:Start(43-delay, 1)
	if self.Options.NPAuraOnFixate then
		DBM:FireEvent("BossMod_EnableHostileNameplates")
	end
end

function mod:OnCombatEnd()
	if self.Options.NPAuraOnFixate then
		DBM.Nameplate:Hide(true, nil, nil, nil, true, true)
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 404916 then --Песчаный вихрь (Фронталка)
		self.vb.blastCount = self.vb.blastCount + 1
		if self:IsTanking("player", "boss1", nil, true) then
			specWarnSandBlast:Show()
			specWarnSandBlast:Play("defensive")
			yellSandBlast:Yell()
		else
			specWarnSandBlast2:Show()
			specWarnSandBlast2:Play("shockwave")
		end
		local timer = self:GetFromTimersTable(allTimers, false, false, spellId, self.vb.blastCount+1)
		if timer then
			timerSandBlastCD:Start(timer, self.vb.blastCount+1)
		else
			if not askShown then
				askShown = true
				DBM:AddMsg("Timers not known beyond this point, please share your WCL with DBM authors if you can")
			end
		end
--		updateAllTimers(self, 4.9)
	elseif spellId == 403891 then --Новые проблемы!
		self.vb.problemsCount = self.vb.problemsCount + 1
		self.vb.problemIcons = 1
		warnMoreProblems:Show()
		specWarnMoreProblems:Show()
		specWarnMoreProblems:Play("specialsoon")
		local timer = self:GetFromTimersTable(allTimers, false, false, spellId, self.vb.problemsCount+1)
		if timer then
			timerMoreProblemsCD:Start(timer, self.vb.problemsCount+1)
		else
			if not askShown then
				askShown = true
				DBM:AddMsg("Timers not known beyond this point, please share your WCL with DBM authors if you can")
			end
		end
	elseif spellId == 404364 and self:AntiSpam(3, 1) then--All 6 cast it at once
		warnDragonBreath:Show()
		specWarnDragonBreath:Show()
		specWarnDragonBreath:Play("breathsoon")
		timerDragonBreath:Start()
	elseif spellId == 405279 or spellId == 407504 then
		self.vb.facesCount = self.vb.facesCount + 1
		warnFamiliarFaces:Show(self.vb.facesCount)
		local timer = self:GetFromTimersTable(allTimers, false, false, 405279, self.vb.facesCount+1)
		if timer then
			timerFamiliarFacesCD:Start(timer, self.vb.facesCount+1)
		else
			if not askShown then
				askShown = true
				DBM:AddMsg("Timers not known beyond this point, please share your WCL with DBM authors if you can")
			end
		end
	elseif spellId == 406481 then
		self.vb.trapsCount = self.vb.trapsCount + 1
		specWarnTimeTraps:Show(self.vb.trapsCount)
		specWarnTimeTraps:Play("watchstep")
		local timer = self:GetFromTimersTable(allTimers, false, false, spellId, self.vb.trapsCount+1)
		if timer then
			timerTimeTrapsCD:Start(timer, self.vb.trapsCount+1)
		else
			if not askShown then
				askShown = true
				DBM:AddMsg("Timers not known beyond this point, please share your WCL with DBM authors if you can")
			end
		end
	end
end

function mod:SPELL_SUMMON(args)
	local spellId = args.spellId
	if spellId == 403902 then --Новые проблемы!
		if self.Options.SetIconOnImages then
			self:ScanForMobs(args.destGUID, 2, self.vb.problemIcons, 1, nil, 12, "SetIconOnImages")
		end
		self.vb.problemIcons = self.vb.problemIcons + 1
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 401200 and args:IsPlayer() then
--		myGUIDAdd = args.sourceGUID
		warnFixate:Show()
		if self.Options.NPAuraOnFixate then
			DBM.Nameplate:Show(true, args.sourceGUID, spellId)
		end
	elseif spellId == 401667 then --Временной стазис
		warnTimeStasis:Show(args.destName)
		if args:IsPlayer() then
			yellTimeStasis:Yell()
		end
--	elseif spellId == 412768 then--Anachronistic Decay applying, adds free
--		if myGUIDAdd and myGUIDAdd == args.destGUID then
--
--		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 401200 and args:IsPlayer() then
		if self.Options.NPAuraOnFixate then
			DBM.Nameplate:Hide(true, args.sourceGUID, spellId)
		end
	end
end

function mod:SPELL_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 412769 and destGUID == UnitGUID("player") and self:AntiSpam(3, 4) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_MISSED = mod.SPELL_DAMAGE
