local mod	= DBM:NewMod(1672, "DBM-Party-Legion", 1, 740)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260630000000")
mod:SetCreatureID(98965, 98970)
mod:SetEncounterID(1835)
mod:SetUsedIcons(8)
mod:SetHotfixNoticeRev(20260714000000)
mod:SetMinSyncRevision(20260714000000)
mod.respawnTime = 29
mod:SetBossHPInfoToHighest()

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 198820 199143 199193 202019 198641 201733",
	"SPELL_CAST_SUCCESS 198635 198641 199193",
	"SPELL_AURA_APPLIED 201733 199368",
	"SPELL_AURA_REMOVED 199193",
	"UNIT_DIED"
)

--TODO, figure out swarm warnings, how many need to switch and kill?
--TODO, boss guids for nameplate aura timers, i'm feeling lazy about this right now cause it'd require scanning at different timings
--[[
(ability.id = 198820 or ability.id = 199143 or ability.id = 199193 or ability.id = 202019 or ability.id = 198641 or ability.id = 201733) and type = "begincast"
 or ability.id = 198635 and type = "cast"
 or ability.id = 199193 and type = "removebuff"
 or target.id = 98965 and type = "death"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
--Фаза 1
mod:AddTimerLine(DBM:EJ_GetSectionInfo(12502))
local warnWhirlingBlade				= mod:NewTargetNoFilterAnnounce(198641, 2) --Крутящийся клинок

local specWarnDarkblast				= mod:NewSpecialWarningDodge(198820, nil, nil, DBM_COMMON_L.FRONTAL, 2, 2) --Темный взрыв (Фронталка)
local specWarnWhirlingBlade			= mod:NewSpecialWarningMoveAway(198641, nil, nil, nil, 4, 2) --Крутящийся клинок

local timerDarkBlastCD				= mod:NewCDCountTimer(18.1, 198820, DBM_COMMON_L.FRONTAL.." (%s)", nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Темный взрыв (Фронталка)
local timerWhirlingBladeCD			= mod:NewCDCountTimer(23, 198641, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Крутящийся клинок
local timerUnerringShearCD			= mod:NewCDCountTimer(12.1, 198635, nil, "Tank", nil, 5, nil, DBM_COMMON_L.TANK_ICON, nil, mod:IsTank() and 2 or nil, 4) --Неумолимый удар
--Фаза 2
mod:AddTimerLine(DBM:EJ_GetSectionInfo(12509))
local warnPhase						= mod:NewPhaseChangeAnnounce(2, 2, nil, nil, nil, nil, nil, 2)
local warnCloud						= mod:NewCountAnnounce(199143, 2) --Гипнотическое облако
local warnSwarm						= mod:NewTargetNoFilterAnnounce(201733, 2) --Жалящий рой
local warnLegacyRavencrest			= mod:NewPreWarnAnnounce(199368, 5, 1) --Наследие Гребня Ворона
local warnShadowBoltVolley			= mod:NewCastAnnounce(202019, 4) --Залп стрел Тьмы
local warnGuile						= mod:NewPreWarnAnnounce(199193, 5, 1) --Хитроумие повелителя ужаса

local specWarnSwarm					= mod:NewSpecialWarningDefensive(201733, nil, nil, nil, 3, 2) --Жалящий рой
local specWarnGuile					= mod:NewSpecialWarningDodge(199193, nil, nil, nil, 2, 2) --Хитроумие повелителя ужаса
local specWarnGuileEnded			= mod:NewSpecialWarningEnd(199193, nil, nil, nil, 1, 2) --Хитроумие повелителя ужаса
local specWarnShadowBoltVolley		= mod:NewSpecialWarningDefensive(202019, nil, nil, DBM_COMMON_L.AOEDAMAGE, 3, 2) --Залп стрел Тьмы (АоЕ)
local specWarnLegacyRavencrest		= mod:NewSpecialWarningYou(199368, nil, nil, DBM_COMMON_L.DAMAGEUP, 1, 2) --Наследие Гребня Ворона

local timerLegacyRavencrestCD		= mod:NewCDTimer(27, 199368, DBM_COMMON_L.DAMAGEUP, nil, nil, 7, nil, DBM_COMMON_L.DEADLY_ICON, nil, 2, 5) --Наследие Гребня Ворона
local timerGuileCD					= mod:NewCDCountTimer(39, 199193, nil, nil, nil, 6, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Хитроумие повелителя ужаса
local timerGuile					= mod:NewBuffFadesTimer(22.7, 199193, nil, nil, nil, 6, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Хитроумие повелителя ужаса 20
local timerCloudCD					= mod:NewCDCountTimer(32.7, 199143, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Гипнотическое облако
local timerSwarmCD					= mod:NewCDCountTimer(17, 201733, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Жалящий рой 17-21
local timerShadowBoltVolleyCD		= mod:NewCDCountTimer(9.7, 202019, DBM_COMMON_L.AOEDAMAGE.." (%s)", nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Залп стрел Тьмы (АоЕ)

local yellWhirlingBlade				= mod:NewYell(198641, nil, nil, nil, "YELL") --Крутящийся клинок
local yellSwarm						= mod:NewYell(201733, nil, nil, nil, "YELL") --Жалящий рой

mod:AddSetIconOption("SetIconOnWhirlingBlade", 198641, true, 0, {8}) --Крутящийся клинок
mod:AddSetIconOption("SetIconOnSwarm", 201733, true, 0, {8}) --Жалящий рой

--Stage 1
mod.vb.bladeCount = 0
mod.vb.blastCount = 0
mod.vb.shearCount = 0
--Stage 2
mod.vb.shadowboltCount = 0
mod.vb.guileCount = 0
mod.vb.cloudCount = 0
mod.vb.swarmCount = 0

function mod:WhirlingBladeTarget(targetname)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnWhirlingBlade:Show()
		specWarnWhirlingBlade:Play("runout")
		yellWhirlingBlade:Yell()
	else
		warnWhirlingBlade:Show(targetname)
	end
	if self.Options.SetIconOnWhirlingBlade then
		self:SetIcon(targetname, 8, 5)
	end
end

function mod:SwarmTarget(targetname)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnSwarm:Show()
		specWarnSwarm:Play("targetyou")
		yellSwarm:Yell()
	else
		warnSwarm:Show(targetname)
	end
	if self.Options.SetIconOnSwarm then
		self:SetIcon(targetname, 8, 5)
	end
end

function mod:OnCombatStart(delay)
	self:SetStage(1)
	--Stage 1
	self.vb.bladeCount = 0
	self.vb.blastCount = 0
	self.vb.shearCount = 0
	--Stage 2
	self.vb.shadowboltCount = 0
	self.vb.guileCount = 0
	self.vb.cloudCount = 0
	self.vb.swarmCount = 0
	timerUnerringShearCD:Start(5.5-delay, 1)
	timerWhirlingBladeCD:Start(10-delay, 1)--Either whirling or dark can come first, other will be immediately after
	timerDarkBlastCD:Start(9.5-delay, 1)--Either whirling or dark can come first, other will be immediately after
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 198820 then
		self.vb.blastCount = self.vb.blastCount + 1
		if self:GetStage(1) then
			specWarnDarkblast:Show()
			specWarnDarkblast:Play("watchstep")
			timerDarkBlastCD:Start(nil, self.vb.blastCount+1)
		end
	elseif spellId == 199143 then
		self.vb.cloudCount = self.vb.cloudCount + 1
		warnCloud:Show(self.vb.cloudCount)
		timerCloudCD:Start(nil, self.vb.cloudCount+1)
	elseif spellId == 199193 then --Хитроумие повелителя ужаса
		--Seems to pause and resume timers but with an extra 3 secondcs
		--As such, just adding 23 is cleaner than actually doing the pause + 3 seconds
		timerCloudCD:Stop()
		timerSwarmCD:Stop()
	--	timerCloudCD:AddTime(31.1, self.vb.cloudCount+1) --23
	--	timerSwarmCD:AddTime(38.3, self.vb.swarmCount+1) --23
	--	timerShadowBoltVolleyCD:AddTime(23, self.vb.shadowboltCount+1)
		self.vb.guileCount = self.vb.guileCount + 1
		specWarnGuile:Show()
		specWarnGuile:Play("watchstep")
		specWarnGuile:ScheduleVoice(1.5, "keepmove")
		timerGuile:Start()
	elseif spellId == 202019 then
		self.vb.shadowboltCount = self.vb.shadowboltCount + 1
		warnShadowBoltVolley:Show()
		if self.vb.shadowboltCount == 1 then
			specWarnShadowBoltVolley:Show()
			specWarnShadowBoltVolley:Play("defensive")
		end
	--	timerShadowBoltVolleyCD:Start(nil, self.vb.shadowboltCount+1)
	elseif spellId == 198641 then
		self:ScheduleMethod(0.1, "BossTargetScanner", args.sourceGUID, "WhirlingBladeTarget", 0.1, 6)
	--	warnWhirlingBlade:Show(self.vb.bladeCount+1)
	elseif spellId == 201733 then
		self.vb.swarmCount = self.vb.swarmCount + 1
		self:ScheduleMethod(0.1, "BossTargetScanner", args.sourceGUID, "SwarmTarget", 0.1, 6)
		timerSwarmCD:Start(nil, self.vb.swarmCount+1)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 198635 then
		self.vb.shearCount = self.vb.shearCount + 1
		timerUnerringShearCD:Start(nil, self.vb.shearCount+1)
	elseif spellId == 198641 then
		self.vb.bladeCount = self.vb.bladeCount + 1
		timerWhirlingBladeCD:Start(20.5, self.vb.bladeCount+1)--23 - 2.5
	elseif spellId == 199193 then
		specWarnDarkblast:Show()
		specWarnDarkblast:Play("watchstep")
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 199368 then --Наследие Гребня Ворона
		if args:IsPlayer() then
			specWarnLegacyRavencrest:Show()
			specWarnLegacyRavencrest:Play("targetyou")
		end
--[[	elseif spellId == 201733 then
		if args:IsPlayer() then
			specWarnSwarm:Show()
			specWarnSwarm:Play("targetyou")
		else
			warnSwarm:Show(args.destName)
		end]]
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 199193 then
		specWarnGuileEnded:Show()
		specWarnGuileEnded:Play("safenow")
		--2 примерных таймера, разрабы вполне могли их поломать
		timerGuileCD:Start(63.8, self.vb.guileCount+1)
		warnGuile:Schedule(58.8)
		--Должны быть норм таймеры после 1 хитроумия, дальше хз
		timerCloudCD:Start(19.4, self.vb.cloudCount+1)
		timerSwarmCD:Start(15.5, self.vb.swarmCount+1)
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 98965 then--Kur'talos Ravencrest
		self:SetStage(2)
		warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(2))
		warnPhase:Play("ptwo")
		warnLegacyRavencrest:Schedule(22)
		timerDarkBlastCD:Stop()
		timerUnerringShearCD:Stop()
		timerWhirlingBladeCD:Stop()
		timerLegacyRavencrestCD:Start()
		timerShadowBoltVolleyCD:Start(19.8, 1)
		if not self:IsNormal() then
			timerSwarmCD:Start(24, 1)
		end
		timerCloudCD:Start(14.9, 1) --27.2
		timerGuileCD:Start(36.7, 1) --
		warnGuile:Schedule(31.7) --
	end
end
