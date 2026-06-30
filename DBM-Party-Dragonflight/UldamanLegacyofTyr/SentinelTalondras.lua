local mod	= DBM:NewMod(2484, "DBM-Party-Dragonflight", 2, 1197)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240428124541")
mod:SetCreatureID(184124)
mod:SetEncounterID(2557)
mod:SetUsedIcons(1, 2, 3, 8)
--mod:SetHotfixNoticeRev(20220322000000)
--mod:SetMinSyncRevision(20211203000000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 372719 372600 372623 372701",
	"SPELL_CAST_SUCCESS 372718",
	"SPELL_AURA_APPLIED 382071 372718 372719 372600",
	"SPELL_AURA_REMOVED 382071 372600 372719",
	"UNIT_POWER_UPDATE"
)

--TODO, review current solution is good enough. there are more elaborate ones but they may not be needed for most part except for niche cases.
--[[
(ability.id = 372719 or ability.id = 372600 or ability.id = 372623 or ability.id = 372701) and type = "begincast"
 or ability.id = 372718 and type = "cast"
 or ability.id = 372600 or ability.id = 372652 and target.id = 184124
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
local warnTitanicEmpowerment					= mod:NewSpellAnnounce(372719, 4) --Титаническое усиление
local warnTitanicEmpowermentOver				= mod:NewFadesAnnounce(372719, 1) --Титаническое усиление
local warnInexorable							= mod:NewSpellAnnounce(372600, 2) --Неумолимость
local warnInexorableOver						= mod:NewFadesAnnounce(372600, 1) --Неумолимость
local warnResonatingOrb							= mod:NewTargetNoFilterAnnounce(382071, 3) --Резонирующая сфера
local warnEarthenShards							= mod:NewTargetNoFilterAnnounce(372718, 4) --Земляные осколки

local specWarnEarthenShards						= mod:NewSpecialWarningDefensive(372718, nil, nil, nil, 3, 4) --Земляные осколки
local specWarnEarthenShards2					= mod:NewSpecialWarningTarget(372718, "Healer", nil, nil, 3, 4) --Земляные осколки
local specWarnTitanicEmpowerment				= mod:NewSpecialWarningSpell(372719, nil, 123471, nil, 3, 4) --Титаническое усиление (Усиление)
local specWarnTitanicEmpowerment2				= mod:NewSpecialWarningInterrupt(372719, "-Healer", 123471, nil, 3, 4) --Титаническое усиление (Усиление)
local specWarnResonatingOrb						= mod:NewSpecialWarningYouPos(382071, nil, nil, nil, 1, 2) --Резонирующая сфера
local specWarnCrushingStomp						= mod:NewSpecialWarningSpell(372701, nil, nil, DBM_COMMON_L.AOEDAMAGE, 2, 2) --Сокрушительная поступь

local timerTitanicEmpowermentCD					= mod:NewCDTimer(35, 372719, 123471, nil, nil, 7, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Титаническое усиление (Усиление)
local timerResonatingOrbCD						= mod:NewCDTimer(27, 382071, nil, nil, nil, 3, nil, nil, true) --Резонирующая сфера 25-30ish
local timerCrushingStompCD						= mod:NewCDTimer(12.5, 372701, DBM_COMMON_L.AOEDAMAGE, nil, nil, 2, nil, nil, true) --Сокрушительная поступь
local timerEarthenShardsCD						= mod:NewCDTimer(16, 372718, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON..DBM_COMMON_L.BLEED_ICON, true) --Земляные осколки

local yellResonatingOrb							= mod:NewShortPosYell(382071, nil, nil, nil, "YELL") --Резонирующая сфера
local yellResonatingOrbFades					= mod:NewIconFadesYell(382071, nil, nil, nil, "YELL") --Резонирующая сфера
local yellEarthenShards							= mod:NewShortYell(372718, nil, nil, nil, "YELL") --Земляные осколки

mod:AddSetIconOption("SetIconOnOrb", 382071, true, 0, {1, 2, 3}) --Резонирующая сфера
mod:AddSetIconOption("SetIconOnEarthenShards", 372718, true, 0, {8}) --Земляные осколки

mod.vb.orbIcon = 1
mod.vb.stompCount = 0

local Proshlyap = false

function mod:OnCombatStart(delay)
	Proshlyap = false
	self.vb.stompCount = 0
--	timerResonatingOrbCD:Start(1-delay)--Instantly on pull
	timerEarthenShardsCD:Start(4.4-delay) --
	timerCrushingStompCD:Start(9.9-delay) --
	if not self:IsNormal() then
		timerTitanicEmpowermentCD:Start(25.5-delay) --
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 372719 then --Титаническое усиление
		if Proshlyap then
			specWarnTitanicEmpowerment:Show()
			specWarnTitanicEmpowerment:Play("specialsoon")
		else
			specWarnTitanicEmpowerment2:Show(args.sourceName)
			specWarnTitanicEmpowerment2:Play("kickcast")
		end
		timerResonatingOrbCD:Stop()
		timerTitanicEmpowermentCD:Stop()
		timerCrushingStompCD:Stop()
		timerEarthenShardsCD:Stop()
	elseif spellId == 372600 then --Неумолимость
		timerResonatingOrbCD:Stop()
		timerTitanicEmpowermentCD:Stop()
		timerCrushingStompCD:Stop()
		timerEarthenShardsCD:Stop()
		if not self:IsNormal() then
			timerTitanicEmpowermentCD:Start(40) --Примерный таймер
		end
		timerResonatingOrbCD:Start(2.5)
		timerCrushingStompCD:Start(8.5)
		timerEarthenShardsCD:Start(12)
	elseif spellId == 372623 then --Резонирующая сфера
		self.vb.orbIcon = 1
		timerResonatingOrbCD:Start() --27.7 хороший таймер, если босс под усилением, 27 хороший таймер, если босс без усиления
	elseif spellId == 372701 then --Сокрушительная поступь (АОЕ)
		self.vb.stompCount = self.vb.stompCount + 1
		specWarnCrushingStomp:Show()
		specWarnCrushingStomp:Play("carefly")
		timerCrushingStompCD:Start() --12.5 сек хороший таймер, если босс под усилением (без усиления вроде тоже)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 372718 then
		timerEarthenShardsCD:Start() --норм в 16 сек если от каста до каста без усиления
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 382071 then
		local icon = self.vb.orbIcon
		if self.Options.SetIconOnOrb then
			self:SetIcon(args.destName, icon)
		end
		if args:IsPlayer() then
			specWarnResonatingOrb:Show(self:IconNumToTexture(icon))
			specWarnResonatingOrb:Play("mm"..icon)
			yellResonatingOrb:Yell(icon, icon)
			yellResonatingOrbFades:Countdown(spellId, nil, icon)
		end
		warnResonatingOrb:CombinedShow(0.5, args.destName)
		self.vb.orbIcon = self.vb.orbIcon + 1
	elseif spellId == 372718 then --Земляные осколки
		if args:IsPlayer() then
			specWarnEarthenShards:Show()
			specWarnEarthenShards:Play("defensive")
			yellEarthenShards:Yell()
		else
			warnEarthenShards:Show(args.destName)
			specWarnEarthenShards2:Show(args.destName)
			specWarnEarthenShards2:Play("healall")
		end
		if self.Options.SetIconOnEarthenShards then
			self:SetIcon(args.destName, 8, 10)
		end
	elseif spellId == 372719 then --Титаническое усиление
		timerResonatingOrbCD:Stop()
		timerTitanicEmpowermentCD:Stop()
		timerCrushingStompCD:Stop()
		timerEarthenShardsCD:Stop()
		warnTitanicEmpowerment:Show()
		timerEarthenShardsCD:Start(8.2) --
		timerCrushingStompCD:Start(12.9) --
		if not self:IsNormal() then
			timerTitanicEmpowermentCD:Start(67)
		end
	elseif spellId == 372600 then --Неумолимость
		if not Proshlyap then
			Proshlyap = true
		end
		timerResonatingOrbCD:Stop()
		timerCrushingStompCD:Stop()
		timerEarthenShardsCD:Stop()
		warnInexorable:Show()
		timerCrushingStompCD:Start(6)
		timerEarthenShardsCD:Start(10)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 382071 then
		if self.Options.SetIconOnOrb then
			self:SetIcon(args.destName, 0)
		end
		if args:IsPlayer() then
			yellResonatingOrbFades:Cancel()
		end
	elseif spellId == 372600 then --Неумолимость спало
		warnInexorableOver:Show()
		if Proshlyap then
			Proshlyap = false
		end
	elseif spellId == 372719 then --Титаническое усиление спало
		warnTitanicEmpowermentOver:Show()
	end
end

--[[function mod:UNIT_POWER_UPDATE()
	local bossPower = UnitPower("boss1")
	if self.vb.flightActive and bossPower == 0 then--Boss power reset
		timerTitanicEmpowermentCD:Stop()
	end
end]]
