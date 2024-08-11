local mod	= DBM:NewMod(2510, "DBM-Party-Dragonflight", 8, 1204)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240810070000")
mod:SetCreatureID(189727)
mod:SetEncounterID(2617)
mod:SetUsedIcons(8)
mod:SetHotfixNoticeRev(20240811070000)
mod:SetMinSyncRevision(20240811070000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 386757 386559 390111",
	"SPELL_CAST_SUCCESS 385963",
	"SPELL_AURA_APPLIED 385963",
	"SPELL_AURA_REMOVED 385963"
)

--[[
(ability.id = 386757 or ability.id = 386559 or ability.id = 390111) and type = "begincast"
 or ability.id = 385963 and type = "cast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
--TODO, review heroic logs in 10.1 to see if timer changes affect that mode
local warnFrostCyclone							= mod:NewCastAnnounce(390111, 2) --Морозный смерч
local warnFrostShock							= mod:NewSpellAnnounce(385963, 3) --Ледяной шок

local specWarnFrostCyclone						= mod:NewSpecialWarningDodge(390111, nil, nil, nil, 2, 2) --Морозный смерч
local specWarnHailstorm							= mod:NewSpecialWarningMoveTo(386757, nil, nil, nil, 3, 4) --Буря с градом
local specWarnGlacialSurge						= mod:NewSpecialWarningDodge(386559, "Ranged", nil, nil, 2, 2) --Ледяной всплеск
local specWarnGlacialSurge2						= mod:NewSpecialWarningRun(386559, "Melee", nil, nil, 4, 4) --Ледяной всплеск
local specWarnFrostShock						= mod:NewSpecialWarningYou(385963, nil, nil, nil, 1, 2) --Ледяной шок
local specWarnFrostShock2						= mod:NewSpecialWarningDispel(385963, "RemoveMagic", nil, nil, 1, 2) --Ледяной шок

local timerHailstormCD							= mod:NewCDTimer(22, 386757, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Буря с градом
local timerHailstorm							= mod:NewCastTimer(7, 386757, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5)
local timerGlacialSurgeCD						= mod:NewCDTimer(22, 386559, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON) --Ледяной всплеск
local timerFrostCycloneCD						= mod:NewCDTimer(29.9, 390111, nil, nil, nil, 7, nil, nil, nil, 2, 5) --Морозный смерч
local timerFrostShockCD							= mod:NewCDTimer(11, 385963, nil, "RemoveMagic", nil, 3, nil, DBM_COMMON_L.MAGIC_ICON..DBM_COMMON_L.HEALER_ICON) --Ледяной шок

local yellFrostShock							= mod:NewShortYell(385963, nil, nil, nil, "YELL") --Ледяной шок

mod:AddSetIconOption("SetIconOnFrostShock", 385963, true, 0, {8})

local boulder = DBM:GetSpellName(386222)

mod.vb.hailCount = 0
mod.vb.surgeCount = 0
mod.vb.cycloneCount = 0
mod.vb.shockCount = 0

function mod:OnCombatStart(delay)
	self.vb.hailCount = 0
	self.vb.surgeCount = 0
	self.vb.cycloneCount = 0
	self.vb.shockCount = 0
	timerFrostShockCD:Start(6-delay, 1) --
	if self:IsMythic() then
		timerFrostCycloneCD:Start(10-delay, 1) --
		timerHailstormCD:Start(20-delay)
		timerGlacialSurgeCD:Start(self:IsMythic() and 32 or 27-delay, 1) --
	else--TODO, verify heroic still does this
		timerHailstormCD:Start(10-delay)
		timerGlacialSurgeCD:Start(22-delay, 1)
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 386757 then
		self.vb.hailCount = self.vb.hailCount + 1
		specWarnHailstorm:Show(boulder)
		specWarnHailstorm:Play("findshelter")
		if self:IsMythic() then
			--20.0, 30.0, 42.0, 30.0
			if self.vb.hailCount % 2 == 0 then
				timerHailstormCD:Start(42, self.vb.hailCount+1)
			else
				timerHailstormCD:Start(30, self.vb.hailCount+1)
			end
		else
			timerHailstormCD:Start(22, self.vb.hailCount+1)
		end
		timerHailstorm:Start()
	elseif spellId == 386559 then --Ледяной всплеск
		self.vb.surgeCount = self.vb.surgeCount + 1
		if self:IsMelee() then
			specWarnGlacialSurge2:Show()
			specWarnGlacialSurge2:Play("watchstep")
		else
			specWarnGlacialSurge:Show()
			specWarnGlacialSurge:Play("watchstep")
		end
		if self:IsMythic() then
			--32.0, 30.0, 42.0, 30.0
			if self.vb.surgeCount % 2 == 0 then
				timerGlacialSurgeCD:Start(42, self.vb.surgeCount+1)
			else
				timerGlacialSurgeCD:Start(30, self.vb.surgeCount+1)
			end
		else
			timerGlacialSurgeCD:Start(22, self.vb.surgeCount+1)
		end
	elseif spellId == 390111 then
		self.vb.cycloneCount = self.vb.cycloneCount + 1
		warnFrostCyclone:Show()
		specWarnFrostCyclone:Show()
		specWarnFrostCyclone:Play("watchstep")
		if self:IsMythic() then
			--10.0, 35.0, 37.0, 35.0
			if self.vb.cycloneCount % 2 == 0 then
				timerFrostCycloneCD:Start(37, self.vb.cycloneCount+1)
			else
				timerFrostCycloneCD:Start(35, self.vb.cycloneCount+1)
			end
		else
			timerFrostCycloneCD:Start(30, self.vb.cycloneCount+1)
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 385963 then
		self.vb.shockCount = self.vb.shockCount + 1
		warnFrostShock:Show()
		if self:IsMythic() then
			if self.vb.shockCount % 2 == 1 then
				timerFrostShockCD:Start(12, self.vb.shockCount+1)
			else
				timerFrostShockCD:Start(60, self.vb.shockCount+1)
			end
		else
			timerFrostShockCD:Start(11, self.vb.shockCount+1)
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 385963 then
		if args:IsPlayer() then
			specWarnFrostShock:Show()
			specWarnFrostShock:Play("targetyou")
			yellFrostShock:Yell()
		else
			specWarnFrostShock2:Show(args.destName)
			specWarnFrostShock2:Play("helpdispel")
		end
		if self.Options.SetIconOnFrostShock then
			self:SetIcon(args.destName, 8)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 385963 then
		if self.Options.SetIconOnFrostShock then
			self:SetIcon(args.destName, 0)
		end
	end
end
