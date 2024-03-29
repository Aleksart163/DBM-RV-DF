local mod	= DBM:NewMod(2492, "DBM-Party-Dragonflight", 6, 1203)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20231029212301")
mod:SetCreatureID(186644)
mod:SetEncounterID(2582)
mod:SetUsedIcons(1, 2, 3)
mod:SetHotfixNoticeRev(20221127000000)
--mod:SetMinSyncRevision(20211203000000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 374364 374567 386660 374789",
	"SPELL_CAST_SUCCESS 374720",
	"SPELL_AURA_APPLIED 374567",
	"SPELL_AURA_REMOVED 374567"
)

--TODO, verify number of players affected by explosive eruption
--TODO, who does Errupting Fissure target? verify target scan
--[[
(ability.id = 374364 or ability.id = 374567 or ability.id = 386660 or ability.id = 374789) and type = "begincast"
 or ability.id =  374720 and type = "cast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
local warnLeylineSprouts						= mod:NewSpellAnnounce(374364, 3)

local specWarnExplosiveEruption					= mod:NewSpecialWarningYouPos(374567, nil, nil, nil, 1, 2)
local specWarnConsumingStomp					= mod:NewSpecialWarningSpell(374720, nil, nil, nil, 2, 2)
local specWarnEruptingFissure					= mod:NewSpecialWarningDodge(386660, nil, nil, nil, 2, 2)
local specWarnInfusedStrike						= mod:NewSpecialWarningDefensive(374789, nil, nil, nil, 3, 2)

local timerLeylineSproutsCD						= mod:NewCDTimer(48.1, 374364, nil, nil, nil, 3)
local timerExplosiveEruptionCD					= mod:NewCDTimer(48.5, 374567, nil, nil, nil, 3)
local timerConsumingStompCD						= mod:NewCDTimer(48.5, 374720, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON)
local timerEruptingFissureCD					= mod:NewCDTimer(48.5, 386660, nil, nil, nil, 3)
local timerInfusedStrikeCD						= mod:NewCDTimer(48.5, 374789, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON)

local yellExplosiveEruption						= mod:NewShortPosYell(374567, nil, nil, nil, "YELL")
local yellExplosiveEruptionFades				= mod:NewIconFadesYell(374567, nil, nil, nil, "YELL")

mod:AddSetIconOption("SetIconOnExplosiveEruption", 374567, true, false, {1, 2, 3})

mod.vb.DebuffIcon = 1

function mod:InfusedStrikeTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnInfusedStrike:Show()
		specWarnInfusedStrike:Play("defensive")
	end
end

function mod:OnCombatStart(delay)
	timerLeylineSproutsCD:Start(3.2-delay)
	timerInfusedStrikeCD:Start(10.1-delay)
	timerEruptingFissureCD:Start(20.2-delay)
	timerExplosiveEruptionCD:Start(30.7-delay)
	timerConsumingStompCD:Start(45-delay)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 374364 then
		warnLeylineSprouts:Show()
		timerLeylineSproutsCD:Start()
	elseif spellId == 374567 then
		self.vb.DebuffIcon = 1
		timerExplosiveEruptionCD:Start()
	elseif spellId == 386660 then
		specWarnEruptingFissure:Show()
		specWarnEruptingFissure:Play("shockwave")
		timerEruptingFissureCD:Start()
	elseif spellId == 374789 then
		self:BossTargetScanner(args.sourceGUID, "InfusedStrikeTarget", 0.1, 2)
		timerInfusedStrikeCD:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 374720 then
		specWarnConsumingStomp:Show()
		specWarnConsumingStomp:Play("aesoon")
		timerConsumingStompCD:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 374567 then
		local icon = self.vb.DebuffIcon
		if self.Options.SetIconOnExplosiveEruption then
			self:SetIcon(args.destName, icon)
		end
		if args:IsPlayer() then
			specWarnExplosiveEruption:Show(self:IconNumToTexture(icon))
			specWarnExplosiveEruption:Play("mm"..icon)
			yellExplosiveEruption:Yell(icon, icon)
			yellExplosiveEruptionFades:Countdown(spellId, nil, icon)
		end
		self.vb.DebuffIcon = self.vb.DebuffIcon + 1
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 374567 then
		if self.Options.SetIconOnExplosiveEruption then
			self:SetIcon(args.destName, 0)
		end
	end
end
