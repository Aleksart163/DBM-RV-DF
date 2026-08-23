local mod	= DBM:NewMod(1653, "DBM-Party-Legion", 1, 740)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260630000000")
mod:SetCreatureID(98696)
mod:SetEncounterID(1833)
mod:SetUsedIcons(3, 2, 1)
mod:SetHotfixNoticeRev(20260714000000)
mod:SetMinSyncRevision(20260714000000)
mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 197418 197546 197974 197797",
	"SPELL_CAST_SUCCESS 197478 197687 197622 197394 197546",
	"SPELL_AURA_APPLIED 197478",
	"SPELL_AURA_REMOVED 197478",
--	"SPELL_PERIODIC_DAMAGE",
--	"SPELL_PERIODIC_MISSED",
	"UNIT_DIED",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

--[[
--Legion numbers
"<3.42 23:50:12> [ENCOUNTER_START] ENCOUNTER_START#1833#Ilysanna Ravencrest#23#5", -- [7]
"<50.59 23:50:59> [UNIT_SPELLCAST_SUCCEEDED] Illysanna Ravencrest(??) boss1:Phase 2 Jump::3-3020-1501-31352-197622-00004A48A3:197622",
"<119.67 23:52:08> [UNIT_SPELLCAST_SUCCEEDED] Illysanna Ravencrest(??) boss1:Periodic Energize::3-3020-1501-31352-197394-0000CA48E8:197394",
"<213.28 23:53:41> [UNIT_SPELLCAST_SUCCEEDED] Illysanna Ravencrest(??) boss1:Phase 2 Jump::3-3020-1501-31352-197622-0003CA4945:197622",
--]]
--[[
(ability.id = 197418 or ability.id = 197546 or ability.id = 197974 or ability.id = 197797) and type = "begincast"
 or (ability.id = 197478 or ability.id = 197687 or ability.id = 197622 or ability.id = 197394) and type = "cast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
--TODO, maybe GTFO for standing in fire left by dark rush and eye beams?
--TODO, initial bonebreaking strike nameplate CD?
--Stage One: Vengeance
mod:AddTimerLine(DBM:EJ_GetSectionInfo(12277))
local warnPhase						= mod:NewPhaseChangeAnnounce(2, 2, nil, nil, nil, nil, nil, 2)
local warnBrutalGlaive				= mod:NewTargetAnnounce(197546, 2) --Жуткая глефа
local warnDarkRush					= mod:NewTargetAnnounce(197478, 3) --Темный рывок

local specWarnBrutalGlaive			= mod:NewSpecialWarningMoveAway(197546, nil, nil, nil, 1, 2) --Жуткая глефа
local specWarnVengefulShear			= mod:NewSpecialWarningDefensive(197418, nil, nil, nil, 3, 2) --Мстительное рассечение
local specWarnDarkRush				= mod:NewSpecialWarningMoveTo(197478, nil, nil, nil, 3, 2) --Темный рывок

local timerBrutalGlaiveCD			= mod:NewCDCountTimer(15.7, 197546, nil, nil, nil, 3) --Жуткая глефа 15 before
local timerVengefulShearCD			= mod:NewCDCountTimer(11, 197418, nil, "Tank", nil, 5, nil, DBM_COMMON_L.TANK_ICON) --Мстительное рассечение 11-16, delayed by dark rush
local timerDarkRushCD				= mod:NewCDCountTimer(31, 197478, nil, nil, nil, 3) --Темный рывок 30 before
local timerLeapCD					= mod:NewStageCountTimer(100, nil, nil, nil, nil, 6, nil, nil, nil, 1, 5) --Прыжок -12281

mod:AddSetIconOption("SetIconOnDarkRush", 197478, true, 6, {1, 2, 3}) --Темный рывок
--Stage Two: Fury
mod:AddTimerLine(DBM:EJ_GetSectionInfo(12281))
local warnEyeBeam					= mod:NewTargetNoFilterAnnounce(197696, 2) --Пронзающий взгляд

local specWarnEyeBeam				= mod:NewSpecialWarningRun(197696, nil, nil, nil, 4, 2) --Пронзающий взгляд
local specWarnBonebreakingStrike	= mod:NewSpecialWarningDodge(197974, "Melee", nil, DBM_COMMON_L.FRONTAL, 2, 2) --Костедробящий удар (Фронталка)
local specWarnArcaneBlitz			= mod:NewSpecialWarningInterrupt(197797, "HasInterrupt", nil, nil, 1, 2)

local timerEyeBeamCD				= mod:NewCDCountTimer(12, 197696, nil, nil, nil, 3) --Пронзающий взгляд 13.5
local timerBonebreakingStrikeCD		= mod:NewCDNPTimer(21.8, 197974, DBM_COMMON_L.FRONTAL, nil, nil, 3) --Костедробящий удар (Фронталка)
--local timerGroundedCD				= mod:NewStageContextTimer(44.8, -12277, nil, nil, nil, 6, 197394)

local yellDarkRush					= mod:NewYell(197478, nil, nil, nil, "YELL") --Темный рывок
local yellBrutalGlaive				= mod:NewYell(197546, nil, nil, nil, "YELL") --Жуткая глефа
local yellEyeBeam					= mod:NewYell(197696, nil, nil, nil, "YELL") --Пронзающий взгляд
local yellEyeBeamFades				= mod:NewShortFadesYell(197696, nil, nil, nil, "YELL") --Пронзающий взгляд

--mod:AddRangeFrameOption(5, 197546)--Range not given for Brutal Glaive

mod.vb.glaiveCount = 0
mod.vb.shearCount = 0
mod.vb.rushCount = 0
mod.vb.eyeCount = 0

function mod:BrutalGlaiveTarget(targetname, uId)
	if not targetname then
		warnBrutalGlaive:Show(DBM_COMMON_L.UNKNOWN)
		return
	end
	if targetname == UnitName("player") then
		specWarnBrutalGlaive:Show()
		specWarnBrutalGlaive:Play("runout")
		yellBrutalGlaive:Yell()
	else
		warnBrutalGlaive:Show(targetname)
	end
end

local function startProshlyapPhase1(self)
	self.vb.glaiveCount = 0
	self.vb.shearCount = 0
	self.vb.rushCount = 0
	self.vb.eyeCount = 0
	self:SetStage(1)
	warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(1))
	warnPhase:Play("phasechange")
	timerEyeBeamCD:Stop()
	timerBrutalGlaiveCD:Start(6, 1)
	timerDarkRushCD:Start(12, 1)
	timerVengefulShearCD:Start(13, 1)
	timerLeapCD:Start(103, 2)
end

local function startProshlyapPhase2(self)
	self.vb.eyeCount = 0
	self:SetStage(2)
	warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(2))
	warnPhase:Play("phasechange")
	timerBrutalGlaiveCD:Stop()
	timerVengefulShearCD:Stop()
	timerDarkRushCD:Stop()
	timerLeapCD:Start(42, 1)
	self:Schedule(145, startProshlyapPhase2, self)
end

function mod:OnCombatStart(delay)
	self:SetStage(1)
	self.vb.glaiveCount = 0
	self.vb.shearCount = 0
	self.vb.rushCount = 0
	self.vb.eyeCount = 0
	timerBrutalGlaiveCD:Start(5.5-delay, 1)
	timerVengefulShearCD:Start(8-delay, 1)
	timerDarkRushCD:Start(11-delay, 1)
	timerLeapCD:Start(36.5, 2)--33.9-35.2 (they changed his starting energy from Legion)
	self:Schedule(36.5, startProshlyapPhase2, self)
	self:Schedule(78, startProshlyapPhase1, self)
end

function mod:OnCombatEnd()
	self:Unschedule(startProshlyapPhase1)
	self:Unschedule(startProshlyapPhase2)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 197418 then
		self.vb.shearCount = self.vb.shearCount + 1
		if self:IsTanking("player", "boss1", nil, true) then
			specWarnVengefulShear:Show()
			specWarnVengefulShear:Play("defensive")
		end
		timerVengefulShearCD:Start(nil, self.vb.shearCount+1)
	elseif spellId == 197546 then
		self:BossTargetScanner(args.sourceGUID, "BrutalGlaiveTarget", 0.1, 10, true)
	elseif spellId == 197974 then
		specWarnBonebreakingStrike:Show()
		specWarnBonebreakingStrike:Play("shockwave")
		timerBonebreakingStrikeCD:Start(nil, args.sourceGUID)
	elseif spellId == 197797 and self:CheckInterruptFilter(args.sourceGUID, false, true) then
		specWarnArcaneBlitz:Show(args.sourceName)
		specWarnArcaneBlitz:Play("kickcast")
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 197478 then
		self.vb.rushCount = self.vb.rushCount + 1
		timerDarkRushCD:Start(nil, self.vb.rushCount+1)
	elseif spellId == 197687 then--No longer fires applied event, so success has to be used, even if it misses or gets dropped off target by some kind of feign
		self.vb.eyeCount = self.vb.eyeCount + 1
		if self.vb.eyeCount < 3 then
			timerEyeBeamCD:Start(nil, self.vb.eyeCount+1)
		end
		if args:IsPlayer() then
			specWarnEyeBeam:Show()
			specWarnEyeBeam:Play("laserrun")
			yellEyeBeam:Yell()
			yellEyeBeamFades:Countdown(12, 5)
		else
			warnEyeBeam:Show(args.destName)
		end
	elseif spellId == 197546 then
		self.vb.glaiveCount = self.vb.glaiveCount + 1
		timerBrutalGlaiveCD:Start(13.7, self.vb.glaiveCount+1)--Stutter casts, so moved to success event
	elseif spellId == 197622 then --Прыжок (Сломано разрабами)
--		self.vb.eyeCount = 0
--		self:SetStage(2)
--		timerBrutalGlaiveCD:Stop()
--		timerVengefulShearCD:Stop()
--		timerDarkRushCD:Stop()
--		timerEyeBeamCD:Start(4, 1)--cast 1.5 after
--		timerGroundedCD:Start(37)--44.8
		DBM:Debug("Check Murchal proshlyap (Разрабы починили Прыжок на 2 фазу)", 2)
	elseif spellId == 197394 then --Накопление энергии (Сломано разрабами)
--		self.vb.glaiveCount = 0
--		self.vb.shearCount = 0
--		self.vb.rushCount = 0
--		self.vb.eyeCount = 0
--		self:SetStage(1)
--		timerEyeBeamCD:Stop()
--		timerBrutalGlaiveCD:Start(6, 1)
--		timerDarkRushCD:Start(12, 1)
--		timerVengefulShearCD:Start(13, 1)
--		timerLeapCD:Start(93.4, 2)--Same as it was back then. yay for consistency
		DBM:Debug("Check Murchal proshlyap (Разрабы починили Накопление энергии)", 2)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 197478 then
		warnDarkRush:CombinedShow(0.3, args.destName)
		if args:IsPlayer() then
			specWarnDarkRush:Show(DBM_COMMON_L.BOSS)
			specWarnDarkRush:Play("movetoboss")
			yellDarkRush:Yell()
		end
		if self.Options.SetIconOnDarkRush then
			self:SetAlphaIcon(0.5, args.destName, 3)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 197478 and self.Options.SetIconOnDarkRush then
		self:SetIcon(args.destName, 0)
	end
end

--[[
function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId)
	if spellId == 153616 and destGUID == UnitGUID("player") and self:AntiSpam(2, 1) then

	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE--]]

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 100485 then--Soul-torn Vanguard
		timerBonebreakingStrikeCD:Stop(args.destGUID)
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, spellId)
	if spellId == 197622 then --Прыжок на фазу 2
--		warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(2))
--		warnPhase:Play("phasechange")
--		timerBrutalGlaiveCD:Stop()
--		timerVengefulShearCD:Stop()
--		timerDarkRushCD:Stop()
		DBM:Debug("Check Murchal proshlyap (Случился прыжок на 2 фазу)", 2)
	elseif spellId == 197394 then --реген энергии
--		warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(1))
--		warnPhase:Play("phasechange")
		DBM:Debug("Check Murchal proshlyap (Начался реген энергии)", 2)
	end
end
