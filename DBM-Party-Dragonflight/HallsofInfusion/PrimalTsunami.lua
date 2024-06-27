local mod	= DBM:NewMod(2511, "DBM-Party-Dragonflight", 8, 1204)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240327002727")
mod:SetCreatureID(189729)
mod:SetEncounterID(2618)
mod:SetHotfixNoticeRev(20230507000000)
--mod:SetMinSyncRevision(20211203000000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 387504 387571 388424 387559",
	"SPELL_AURA_APPLIED 387585",
	"SPELL_AURA_REMOVED 387585"
)

--TODO: Warn Undertow? It's only used if tank is messing up
--[[
(ability.id = 387504 or ability.id = 387571 or ability.id = 388424 or ability.id = 387559) and type = "begincast"
 or ability.id = 387585
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
--Stage One: Violent Swells
mod:AddTimerLine(DBM:EJ_GetSectionInfo(25529))
local warnFocusedDeluge							= mod:NewCastAnnounce(387571, 3) --Направленный потоп On for everyone, since there will likely be many slow tanks in pugs
local warnInfusedGlobule						= mod:NewCountAnnounce(387474, 2) --Заряженная капля
local warnTempestsFury							= mod:NewCountAnnounce(388424, 3, nil, "Tank|Healer") --Неистовство бури

local specWarnSquallBuffet						= mod:NewSpecialWarningDefensive(387504, nil, nil, nil, 3, 4) --Шквальный толчок
local specWarnTempestsFury						= mod:NewSpecialWarningDefensive(388424, "-Tank", nil, nil, 2, 4) --Неистовство бури

local timerSquallBuffetCD						= mod:NewCDTimer(35, 387504, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON) --Шквальный толчок Squall Buffet/Focused Deluge tank combo
local timerInfusedGlobuleCD						= mod:NewCDCountTimer(17.5, 387474, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Заряженная капля
local timerTempestsFuryCD						= mod:NewCDCountTimer(31, 388424, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Неистовство бури

--Stage Two: Infused Waters
mod:AddTimerLine(DBM:EJ_GetSectionInfo(25531))
local warnSubmerged								= mod:NewSpellAnnounce(387585, 2) --Погружение
local warnSubmergedEnded						= mod:NewEndAnnounce(387585, 2) --Погружение

--local timerSubmergedCD						= mod:NewCDTimer(29.9, 387585, nil, nil, nil, 6)--Phasing timer (Now Health based 50%)

mod.vb.GlobCount = 0
mod.vb.tempestCount = 0

function mod:OnCombatStart(delay)
	self:SetStage(1)
	self.vb.GlobCount = 0
	self.vb.tempestCount = 0
	timerTempestsFuryCD:Start(4-delay, 1)
	timerInfusedGlobuleCD:Start(8-delay, 1)
	timerSquallBuffetCD:Start(16-delay)
--	timerSubmergedCD:Start(52.1-delay)--Phasing timer (Now Health based 50%)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 387504 then
		if self:IsTanking("player", "boss1", nil, true) then
			specWarnSquallBuffet:Show()
			specWarnSquallBuffet:Play("carefly")
		end
	elseif spellId == 387571 then
		warnFocusedDeluge:Show()
	elseif spellId == 388424 then --Неистовство бури
		self.vb.tempestCount = self.vb.tempestCount + 1
		warnTempestsFury:Show(self.vb.tempestCount)
		specWarnTempestsFury:Show()
		specWarnTempestsFury:Play("defensive")
		if self.vb.tempestCount == 1 then--Only 2 cast per rotation
			timerTempestsFuryCD:Start(31, 2)
		end
	elseif spellId == 387559 then
		self.vb.GlobCount = self.vb.GlobCount + 1
		warnInfusedGlobule:Show(self.vb.GlobCount)
		if self.vb.GlobCount == 1 then--Only 2 cast per rotation
			timerInfusedGlobuleCD:Start(17.5, 2)
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 387585 and self:GetStage(1) then--Submerged
		self:SetStage(2)
		warnSubmerged:Show()
		timerSquallBuffetCD:Stop()
		timerInfusedGlobuleCD:Stop()
		timerTempestsFuryCD:Stop()
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 387585 and self:GetStage(2) then--Submerged
		self:SetStage(1)
		self.vb.GlobCount = 0
		self.vb.tempestCount = 0
		warnSubmerged:Show()
		timerTempestsFuryCD:Start(7, 1)
		timerInfusedGlobuleCD:Start(11, 1)
		timerSquallBuffetCD:Start(19.3)
--		timerSubmergedCD:Start(55)--NEED MORE DATA, drycoded
	end
end
