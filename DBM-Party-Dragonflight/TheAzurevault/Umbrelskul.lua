local mod	= DBM:NewMod(2508, "DBM-Party-Dragonflight", 6, 1203)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240426062327")
mod:SetCreatureID(186738)
mod:SetEncounterID(2584)
mod:SetHotfixNoticeRev(20230110000000)
--mod:SetMinSyncRevision(20211203000000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 384978 385399 385075 388804 384699",
	"SPELL_CAST_SUCCESS 384696 385399 388804",
	"SPELL_AURA_APPLIED 384978",
	"SPELL_AURA_REMOVED 384978"
)

--TODO, Current under-tuning makes the crystals and fracture completely inconsiquential. Until that changes, not much to do with those.
--TODO, target scan arcane eruption?
--TODO, Even on really long M+, Unleashed was never cast more than once, with upwards of 107 seconds between first cast and kill
--TODO, Brittle not in CLEU so can't be implemented yet
--[[
(ability.id = 384978 or ability.id = 384699 or ability.id = 385399 or ability.id = 385075 or ability.id = 388804)  and type = "begincast"
 or ability.id = 384696 and type = "cast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
local warnArcaneEruption						= mod:NewCountAnnounce(385075, 3) --Чародейское извержение

local specWarnDragonStrike						= mod:NewSpecialWarningDefensive(384978, nil, nil, nil, 3, 4) --Удар дракона
local specWarnDragonStrikeDebuff				= mod:NewSpecialWarningDispel(384978, "RemoveMagic", nil, nil, 3, 2) --Удар дракона
local specWarnCrystallineRoar					= mod:NewSpecialWarningDodgeCount(384699, nil, nil, nil, 3, 2) --Кристаллический рев
local specWarnUnleashedDestruction				= mod:NewSpecialWarningCount(385399, nil, nil, nil, 2, 2) --Высвобожденное разрушение

local timerDragonStrikeCD						= mod:NewCDTimer(7.3, 384978, nil, "Tank|Healer|RemoveMagic", nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.MAGIC_ICON)--Удар дракона 7.3-24, probably delayed by CLEU events I couldn't see
local timerCrystallineRoarCD					= mod:NewCDCountTimer(111.6, 384699, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Кристаллический рев
local timerUnleashedDestructionCD				= mod:NewCDCountTimer(103.1, 385399, nil, nil, nil, 2)--Высвобожденное разрушение 103-115
local timerArcaneEruptionCD						= mod:NewCDCountTimer(54.6, 385075, nil, nil, nil, 3) --Чародейское извержение

local yellDragonStrike							= mod:NewShortYell(384978, nil, nil, nil, "YELL") --Удар дракона

mod:AddSetIconOption("SetIconOnDragonStrike", 384978, true, 0, {8}) --Удар дракона
mod:AddInfoFrameOption(388777, false)

mod.vb.roarCount = 0
mod.vb.unleashedCast = 0
mod.vb.eruptionCount = 0

function mod:DragonStrikeTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnDragonStrike:Show()
		specWarnDragonStrike:Play("defensive")
		yellDragonStrike:Yell()
	end
end

function mod:OnCombatStart(delay)
	self.vb.roarCount = 0
	self.vb.unleashedCast = 0
	self.vb.eruptionCount = 0
	timerDragonStrikeCD:Start(10-delay)
	timerCrystallineRoarCD:Start(12.5-delay, 1)
	timerArcaneEruptionCD:Start(29.5-delay, 1)--28.9-37, Highly variable if it gets spell queued behind more tank casts
	timerUnleashedDestructionCD:Start(43-delay, 1)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 384978 then --Удар дракона
		self:BossTargetScanner(args.sourceGUID, "DragonStrikeTarget", 0.1, 2)
		timerDragonStrikeCD:Start()
	elseif spellId == 385399 or spellId == 388804 then--Высвобожденное разрушение Easy, Hard
		specWarnUnleashedDestruction:Show(self.vb.unleashedCast+1)
		specWarnUnleashedDestruction:Play("carefly")
	elseif spellId == 385075 then --Чародейское извержение
		self.vb.eruptionCount = self.vb.eruptionCount + 1
		warnArcaneEruption:Show(self.vb.eruptionCount)
		timerArcaneEruptionCD:Start(nil, self.vb.eruptionCount+1)
	elseif spellId == 384699 then --Кристаллический рев
		self.vb.roarCount = self.vb.roarCount + 1
		specWarnCrystallineRoar:Show(self.vb.roarCount)
		specWarnCrystallineRoar:Play("shockwave")
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 384696 then
	--	self.vb.roarCount = self.vb.roarCount + 1
	--	specWarnCrystallineRoar:Show(self.vb.roarCount)
	--	specWarnCrystallineRoar:Play("shockwave")
		timerCrystallineRoarCD:Start(nil, self.vb.roarCount+1)
	elseif spellId == 385399 or spellId == 388804 then--Easy, Hard
		self.vb.unleashedCast = self.vb.unleashedCast + 1--Only increment cast count if it actually finishes
		timerUnleashedDestructionCD:Start(100.1, self.vb.unleashedCast+1)--Even this cast can be interrupted kited boss around so we have to move timer to success
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 384978 then --Удар дракона
		if self:IsSpellCaster() then
			specWarnDragonStrikeDebuff:Show(args.destName)
			specWarnDragonStrikeDebuff:Play("helpdispel")
		end
		if self.Options.SetIconOnDragonStrike then
			self:SetIcon(args.destName, 8)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 384978 then --Удар дракона
		if self.Options.SetIconOnDragonStrike then
			self:SetIcon(args.destName, 0)
		end
	end
end
