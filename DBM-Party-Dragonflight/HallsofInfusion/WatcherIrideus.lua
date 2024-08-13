local mod	= DBM:NewMod(2504, "DBM-Party-Dragonflight", 8, 1204)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240412075414")
mod:SetCreatureID(189719)
mod:SetEncounterID(2615)
mod:SetHotfixNoticeRev(20240628070000)
--mod:SetMinSyncRevision(20211203000000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 389179 384014 384524 389446 384351",
	"SPELL_AURA_APPLIED 389179 383840 389443",
	"SPELL_AURA_REMOVED 389179 383840",
	"SPELL_PERIODIC_DAMAGE 389181",
	"SPELL_PERIODIC_MISSED 389181"
)

--[[
(ability.id = 389179 or ability.id = 384351 or ability.id = 384014 or ability.id = 384524 or ability.id = 389446) and type = "begincast"
 or ability.id = 383840
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
 or (source.type = "NPC" and source.firstSeen = timestamp) or (target.type = "NPC" and target.firstSeen = timestamp)
--]]
--Stage One: A Chance at Redemption
--mod:AddTimerLine(DBM:EJ_GetSectionInfo(25745))
local warnPowerLoverload						= mod:NewTargetAnnounce(389179, 3) --Перегрузка

local specWarnPowerOverload						= mod:NewSpecialWarningMoveAway(389179, nil, nil, nil, 1, 2) --Перегрузка
local specWarnSparkVolley						= mod:NewSpecialWarningDodge(384351, nil, nil, nil, 4, 2) --Череда разрядов
local specWarnStaticSurge						= mod:NewSpecialWarningDefensiveCount(384014, nil, nil, nil, 2, 2) --Статический выброс
local specWarnGTFO								= mod:NewSpecialWarningGTFO(389181, nil, nil, nil, 1, 8) --Статическое поле
local specWarnTitanticFist						= mod:NewSpecialWarningDodge(384524, nil, nil, nil, 2, 2) --Кулак титана

local timerPowerOverloadCD						= mod:NewCDTimer(28, 389179, nil, nil, nil, 3, nil, DBM_COMMON_L.MAGIC_ICON) --Перегрузка
local timerSparkVolleyCD						= mod:NewCDTimer(30, 384351, nil, nil, nil, 3, nil, DBM_COMMON_L.MAGIC_ICON) --Череда разрядов
local timerStaticSurgeCD						= mod:NewCDCountTimer(28, 384014, nil, nil, nil, 2) --Статический выброс
local timerTitanicFistCD						= mod:NewCDTimer(30, 384524, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON) --Кулак титана
--Perephase: Ochken of Murchal
--mod:AddTimerLine(DBM:EJ_GetSectionInfo(25744))
local warnAblativeBarrier						= mod:NewSpellAnnounce(383840, 2) --Абляционный барьер
local warnAblativeBarrierOver					= mod:NewEndAnnounce(383840, 1) --Абляционный барьер
local warnNullifyingPulse						= mod:NewCastAnnounce(389446, 4) --Нейтрализующая пульсация
local warnPurifyingBlast						= mod:NewTargetNoFilterAnnounce(389443, 3, nil, false) --Очищающая вспышка

local specWarnNullifyingPulse					= mod:NewSpecialWarningRun(389446, "Melee", nil, nil, 4, 2) --Нейтрализующая пульсация

local yellPowerOverload							= mod:NewShortYell(389179, nil, nil, nil, "YELL") --Перегрузка
local yellPowerOverloadFades					= mod:NewShortFadesYell(389179, nil, nil, nil, "YELL") --Перегрузка

mod.vb.surgeCount = 0
mod.vb.titanicFistCount = 0
mod.vb.sparkVolleyCount = 0
mod.vb.ochkenProshlyapationsCount = 1

local allProshlyapationsOfMurchal = {
	[1] = {
		--Кулак титана
		[384524] = {6, 18, 22.1, 18.1, 19.4, 18.5, 18, 19.4, 21},
		--Череда разрядов
		[384351] = {29.9, 31, 31, 31, 36},
		--Статический выброс
	--	[384014] = {10.9, 28, 28, 28, 28.9, 60},
	},
	[2] = {
		--Кулак титана
		[384524] = {8.1, 18, 22.1, 18, 18, 19.9, 18, 18, 21.3},
		--Череда разрядов
		[384351] = {31.6, 31, 31, 31, 36},
		--Статический выброс
	--	[384014] = {13, 28, 28, 28, 28.6, 60},
	},
}

function mod:OnCombatStart(delay)
	self.vb.surgeCount = 0
	self.vb.titanicFistCount = 0
	self.vb.sparkVolleyCount = 0
	self.vb.ochkenProshlyapationsCount = 1
	self:SetStage(1)
	timerTitanicFistCD:Start(6-delay)--
	timerStaticSurgeCD:Start(10.9-delay, 1)--
	timerPowerOverloadCD:Start(26.1-delay)--
	timerSparkVolleyCD:Start(29.9-delay)--
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 389179 then --Перегрузка
		timerPowerOverloadCD:Start()
	elseif spellId == 384351 then --Череда разрядов
		self.vb.sparkVolleyCount = self.vb.sparkVolleyCount + 1
		specWarnSparkVolley:Show()
		specWarnSparkVolley:Play("watchstep")
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, self.vb.ochkenProshlyapationsCount, spellId, self.vb.sparkVolleyCount+1)
		if timer then
			timerSparkVolleyCD:Start(timer, self.vb.sparkVolleyCount+1)
		end
	elseif spellId == 384014 then --Статический выброс
		self.vb.surgeCount = self.vb.surgeCount + 1
		specWarnStaticSurge:Show(self.vb.surgeCount)
		specWarnStaticSurge:Play("aesoon")
		timerStaticSurgeCD:Start(nil, self.vb.surgeCount+1)
	elseif spellId == 384524 then --Кулак титана
		self.vb.titanicFistCount = self.vb.titanicFistCount + 1
		if self:IsTanking("player", "boss1", nil, true) then
			specWarnTitanticFist:Show()
			specWarnTitanticFist:Play("shockwave")
		end
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, self.vb.ochkenProshlyapationsCount, spellId, self.vb.titanicFistCount+1)
		if timer then
			timerTitanicFistCD:Start(timer, self.vb.titanicFistCount+1)
		end
	elseif spellId == 389446 and self:AntiSpam(3, 1) then
		warnNullifyingPulse:Show()
		specWarnNullifyingPulse:Show()
		specWarnNullifyingPulse:Play("justrun")
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 389179 then
		if args:IsPlayer() then
			specWarnPowerOverload:Show()
			specWarnPowerOverload:Play("runout")
			yellPowerOverload:Yell()
			yellPowerOverloadFades:Countdown(spellId)
		else
			warnPowerLoverload:CombinedShow(0.3, args.destName)
		end
	elseif spellId == 383840 then --Абляционный барьер
		warnAblativeBarrier:Show()
		timerPowerOverloadCD:Stop()
		timerSparkVolleyCD:Stop()
		timerStaticSurgeCD:Stop()
		timerTitanicFistCD:Stop()
	elseif spellId == 389443 then
		warnPurifyingBlast:CombinedShow(1, args.destName)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 389179 then
		if args:IsPlayer() then
			yellPowerOverloadFades:Cancel()
		end
	elseif spellId == 383840 then --Абляционный барьер
		self.vb.ochkenProshlyapationsCount = self.vb.ochkenProshlyapationsCount + 1
		self.vb.surgeCount = 0
		self.vb.titanicFistCount = 0
		self.vb.sparkVolleyCount = 0
		warnAblativeBarrierOver:Show()
		if self:GetStage(1) then
			self:SetStage(2)
		end
		timerTitanicFistCD:Start(8.1)--
		timerStaticSurgeCD:Start(13, 1)--
		timerPowerOverloadCD:Start(30)--
		timerSparkVolleyCD:Start(31.6)--
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 389181 and destGUID == UnitGUID("player") and self:AntiSpam(2, 4) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
