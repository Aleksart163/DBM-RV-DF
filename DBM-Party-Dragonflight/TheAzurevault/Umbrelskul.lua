local mod	= DBM:NewMod(2508, "DBM-Party-Dragonflight", 6, 1203)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20231029212301")
mod:SetCreatureID(186738)
mod:SetEncounterID(2584)
mod:SetUsedIcons(8)
mod:SetHotfixNoticeRev(20230110000000)
--mod:SetMinSyncRevision(20211203000000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 384978 385399 385075 388804 384699",
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
local warnArcaneEruption						= mod:NewSpellAnnounce(385075, 3) --Чародейское извержение

local specWarnDragonStrike						= mod:NewSpecialWarningDefensive(384978, nil, nil, nil, 3, 2) --Удар дракона
local specWarnDragonStrikeDebuff				= mod:NewSpecialWarningDispel(384978, "RemoveMagic", nil, nil, 3, 2) --Удар дракона
local specWarnCrystallineRoar					= mod:NewSpecialWarningDodge(384699, nil, nil, nil, 2, 2) --Кристаллический рев
local specWarnUnleashedDestruction				= mod:NewSpecialWarningSpell(385399, nil, nil, nil, 2, 2) --Высвобожденное разрушение

local timerDragonStrikeCD						= mod:NewCDTimer(15.9, 384978, nil, "Tank|Healer|RemoveMagic", nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.MAGIC_ICON) --Удар дракона 7.3-24, probably delayed by CLEU events I couldn't see
local timerCrystallineRoarCD					= mod:NewCDTimer(111.4, 384699, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Кристаллический рев
local timerUnleashedDestructionCD				= mod:NewCDTimer(103.1, 385399, nil, nil, nil, 2) --Высвобожденное разрушение
local timerArcaneEruptionCD						= mod:NewCDTimer(54, 385075, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Чародейское извержение

local yellDragonStrike							= mod:NewShortYell(384978, nil, nil, nil, "YELL") --Удар дракона

mod:AddSetIconOption("SetIconOnDragonStrike", 384978, true, 0, {8})

mod.vb.unleashedCast = 0
mod.vb.arcaneEruptionCount = 0

function mod:DragonStrikeTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnDragonStrike:Show()
		specWarnDragonStrike:Play("defensive")
		yellDragonStrike:Yell()
	end
end

function mod:OnCombatStart(delay)
	self.vb.unleashedCast = 0
	self.vb.arcaneEruptionCount = 0
	timerDragonStrikeCD:Start(10-delay)
	timerCrystallineRoarCD:Start(12.5-delay)
	timerArcaneEruptionCD:Start(29.5-delay)--28.9-37, Highly variable if it gets spell queued behind more tank casts
	timerUnleashedDestructionCD:Start(43-delay)
end

function mod:OnCombatEnd()
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 384978 then --Удар дракона
		self:BossTargetScanner(args.sourceGUID, "DragonStrikeTarget", 0.1, 2)
		timerDragonStrikeCD:Start()
	elseif spellId == 385399 or spellId == 388804 then --Высвобожденное разрушение Easy, Hard
		self.vb.unleashedCast = self.vb.unleashedCast + 1
		--43, 114, 110
		specWarnUnleashedDestruction:Show()
		specWarnUnleashedDestruction:Play("carefly")
		timerUnleashedDestructionCD:Start()
	elseif spellId == 385075 then --Чародейское извержение
		--29.5, 54, 56, 58, 56
		self.vb.arcaneEruptionCount = self.vb.arcaneEruptionCount + 1
		warnArcaneEruption:Show()
		timerArcaneEruptionCD:Start()
	elseif spellId == 384699 then --Кристаллический рев
		--12.5, 111.4, 114
		specWarnCrystallineRoar:Show()
		specWarnCrystallineRoar:Play("shockwave")
		timerCrystallineRoarCD:Start()
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
