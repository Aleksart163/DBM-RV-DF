local mod	= DBM:NewMod(2511, "DBM-Party-Dragonflight", 8, 1204)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240727070000")
mod:SetCreatureID(189729)
mod:SetEncounterID(2618)
mod:SetHotfixNoticeRev(20240728070000)
--mod:SetMinSyncRevision(20211203000000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 387504 387571 388424 387559",
	"SPELL_AURA_APPLIED 387585",
	"SPELL_AURA_REMOVED 387585",
	"UNIT_POWER_UPDATE",
	"UNIT_DIED"
)

--TODO: Warn Undertow? It's only used if tank is messing up
--[[
(ability.id = 387504 or ability.id = 387571 or ability.id = 388424 or ability.id = 387559) and type = "begincast"
 or ability.id = 387585
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
--Фаза 1
mod:AddTimerLine(DBM:EJ_GetSectionInfo(25529))
local warnFocusedDeluge							= mod:NewCastAnnounce(387571, 4) --Направленный потоп On for everyone, since there will likely be many slow tanks in pugs
local warnInfusedGlobule						= mod:NewCountAnnounce(387474, 2) --Заряженная капля
local warnTempestsFury							= mod:NewCountAnnounce(388424, 4) --Неистовство бури

local specWarnInfusedGlobule					= mod:NewSpecialWarningDodge(387474, nil, nil, nil, 1, 2) --Заряженная капля
local specWarnSquallBuffet						= mod:NewSpecialWarningDefensive(387504, nil, nil, nil, 3, 4) --Шквальный толчок
local specWarnTempestsFury						= mod:NewSpecialWarningDefensive(388424, "-Tank", nil, DBM_COMMON_L.AOEDAMAGE, 2, 4) --Неистовство бури (АоЕ)

local timerSquallBuffetCD						= mod:NewCDTimer(35, 387504, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON) --Шквальный толчок Squall Buffet/Focused Deluge tank combo
local timerInfusedGlobuleCD						= mod:NewCDCountTimer(17.5, 387474, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Заряженная капля
local timerTempestsFuryCD						= mod:NewCDCountTimer(31, 388424, DBM_COMMON_L.AOEDAMAGE.." (%s)", nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Неистовство бури (АоЕ)

local yellSquallBuffet							= mod:NewShortYell(387504, nil, nil, nil, "YELL") --Шквальный толчок

--Фаза 2
mod:AddTimerLine(DBM:EJ_GetSectionInfo(25531))
local warnSubmerged								= mod:NewSpellAnnounce(387585, 2) --Погружение
local warnSubmergedEnded						= mod:NewEndAnnounce(387585, 2) --Погружение

local timerSubmergedCD							= mod:NewCDTimer(30, 387585, nil, nil, nil, 6, nil, nil, nil, 2, 5) --Погружение

mod.vb.GlobCount = 0
mod.vb.tempestCount = 0

local function startProshlyapationOfMurchal(self) -- Proshlyapation of Murchal
	warnSubmerged:Show()
end

function mod:OnCombatStart(delay)
	self:SetStage(1)
	self.vb.GlobCount = 0
	self.vb.tempestCount = 0
	timerTempestsFuryCD:Start(4-delay, 1)--
	timerInfusedGlobuleCD:Start(7.9-delay, 1)--
	timerSquallBuffetCD:Start(15.9-delay)--
--	self:Schedule(53, startProshlyapationOfMurchal, self)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 387504 then
		if self:IsTanking("player", "boss1", nil, true) then
			specWarnSquallBuffet:Show()
			specWarnSquallBuffet:Play("defensive")
			yellSquallBuffet:Yell()
		end
	elseif spellId == 387571 then
		warnFocusedDeluge:Show()
	elseif spellId == 388424 then --Неистовство бури
		self.vb.tempestCount = self.vb.tempestCount + 1
		warnTempestsFury:Show(self.vb.tempestCount)
		specWarnTempestsFury:Show()
		specWarnTempestsFury:Play("defensive")
		if self.vb.tempestCount >= 1 then-- Прошляп Мурчаля с первых сезонов, в 4-ом не работает
			timerTempestsFuryCD:Start(31, self.vb.tempestCount+1)
		end
	elseif spellId == 387559 then --Заряженные капли
		self.vb.GlobCount = self.vb.GlobCount + 1
		warnInfusedGlobule:Show(self.vb.GlobCount)
		specWarnInfusedGlobule:Show()
		specWarnInfusedGlobule:Play("watchstep")
		if self:GetStage(1) and self.vb.GlobCount >= 1 then
			timerInfusedGlobuleCD:Start(23.2, self.vb.GlobCount+1)
		elseif self:GetStage(2) then
			if self.vb.GlobCount == 1 then --1ый каст через 10.5 после начала фазы, потом 24, дальше 8.8, а потом хз
				timerInfusedGlobuleCD:Start(24, self.vb.GlobCount+1) --24, 8.8
			elseif self.vb.GlobCount == 2 then
				timerInfusedGlobuleCD:Start(8.8, self.vb.GlobCount+1)
			else
				timerInfusedGlobuleCD:Start(24, self.vb.GlobCount+1)
			end
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 387585 and self:GetStage(1) then --Погружение
		self:SetStage(2)
	--	warnSubmerged:Show()
	--	timerSubmergedCD:Stop()
		timerSquallBuffetCD:Stop()
		timerInfusedGlobuleCD:Stop()
		timerTempestsFuryCD:Stop()
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 387585 then --Погружение
		self.vb.GlobCount = 0
		self.vb.tempestCount = 0
		warnSubmergedEnded:Show()
		timerTempestsFuryCD:Start(6.5, 1)--
		timerInfusedGlobuleCD:Start(10.5, 1)--
		timerSquallBuffetCD:Start(19.4)--
		timerSubmergedCD:Start(57)--
	--	self:Schedule(57, startProshlyapationOfMurchal, self)
	end
end

function mod:UNIT_POWER_UPDATE()
	local bossPower = UnitPower("boss1")
	if bossPower == 99 and self:AntiSpam(5, "FullPower") then --Прикол от разрабов? Лишь 99, не 100
		timerSquallBuffetCD:Stop()
		timerInfusedGlobuleCD:Stop()
		timerTempestsFuryCD:Stop()
		warnSubmerged:Show()
	end
end
