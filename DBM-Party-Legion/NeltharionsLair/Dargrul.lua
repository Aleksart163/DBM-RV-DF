local mod	= DBM:NewMod(1687, "DBM-Party-Legion", 5, 767)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240426175442")
mod:SetCreatureID(91007)
mod:SetEncounterID(1793)
mod:SetUsedIcons(8)
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 200732 200551 200637 200700 200404",
	"SPELL_AURA_APPLIED 200154",
	"SPELL_AURA_REMOVED 200154",
	"CHAT_MSG_RAID_BOSS_EMOTE"
)

--[[
(ability.id = 200732 or ability.id = 200551 or ability.id = 200637 or ability.id = 200700 or ability.id = 200404) and type = "begincast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
local warnCrystalSpikes				= mod:NewCastAnnounce(200551, 2) --Кристальные шипы
local warnBurningHatred				= mod:NewTargetNoFilterAnnounce(200154, 4, nil, nil, 96306) --Пламенная ненависть (Преследование)

local specWarnCrystalSpikes			= mod:NewSpecialWarningDodge(200551, "-Tank", nil, nil, 2, 2) --Кристальные шипы
local specWarnMoltenCrash			= mod:NewSpecialWarningDefensive(200732, nil, nil, nil, 3, 4) --Магматический удар
local specWarnLandSlide				= mod:NewSpecialWarningSpell(200700, "Tank", nil, nil, 1, 2) --Оползень
local specWarnMagmaSculptor			= mod:NewSpecialWarningSwitchCount(200637, "Dps", nil, nil, 1, 2) --Ваятель магмы
local specWarnMagmaWave				= mod:NewSpecialWarningMoveTo(200404, "-Tank", nil, nil, 2, 2) --Магматическая волна
local specWarnMagmaWave2			= mod:NewSpecialWarningSpell(200404, "Tank", nil, nil, 2, 2) --Магматическая волна
local specWarnBurningHatred			= mod:NewSpecialWarningRun(200154, nil, 96306, nil, 4, 2) --Пламенная ненависть (Преследование)

local timerMoltenCrashCD			= mod:NewCDCountTimer(16.5, 200732, nil, "Tank", nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON, nil, 2, 3) --Магматический удар 16.5-23
local timerLandSlideCD				= mod:NewCDTimer(16.5, 200700, nil, "Tank", nil, 5, nil, DBM_COMMON_L.TANK_ICON) --Оползень 16.5-27
local timerCrystalSpikesCD			= mod:NewCDTimer(21.4, 200551, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Кристальные шипы
local timerMagmaSculptorCD			= mod:NewCDCountTimer(71, 200637, nil, nil, nil, 1, nil, DBM_COMMON_L.DAMAGE_ICON..DBM_COMMON_L.DEADLY_ICON) --Ваятель магмы Everyone?
local timerMagmaWaveCD				= mod:NewCDCountTimer(60, 200404, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Магматическая волна
local timerMagmaWave				= mod:NewCastTimer(6, 200404, nil, nil, nil, 7, nil, nil, nil, 1, 5) --Магматическая волна

mod:AddSetIconOption("SetIconOnBurningHatred", 200154, true, 0, {8}) --Пламенная ненависть (Преследование)

local shelterName = DBM:GetSpellName(200551)

mod.vb.waveCount = 0
mod.vb.crashCount = 0
mod.vb.addCount = 0
--[[
function mod:MoltenCrashTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnMoltenCrash:Show()
		specWarnMoltenCrash:Play("defensive")
	end
end]]

function mod:OnCombatStart(delay)
	self.vb.waveCount = 0
	self.vb.crashCount = 0
	self.vb.addCount = 0
	timerCrystalSpikesCD:Start(5.8-delay)
	timerMagmaSculptorCD:Start(7.3-delay, 1)
	timerLandSlideCD:Start(15.5-delay)
	timerMoltenCrashCD:Start(18.7-delay, 1)
	timerMagmaWaveCD:Start(60.7-delay, 1)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 200732 then --Магматический удар
		self.vb.crashCount = self.vb.crashCount + 1
	--	self:BossTargetScanner(args.sourceGUID, "MoltenCrashTarget", 0.1, 2)
		if self:IsTanking("player", "boss1", nil, true) then
			specWarnMoltenCrash:Show()
			specWarnMoltenCrash:Play("defensive")
		end
		timerMoltenCrashCD:Start(15.9, self.vb.crashCount+1)
		--1 каст 18.7, 2 каст 16.1, 3 каст 15.9
	elseif spellId == 200551 then --Кристальные шипы
		warnCrystalSpikes:Show()
		specWarnCrystalSpikes:Show()
		specWarnCrystalSpikes:Play("watchstep")
		timerCrystalSpikesCD:Start()
	elseif spellId == 200637 then
		self.vb.addCount = self.vb.addCount + 1
		specWarnMagmaSculptor:Show(self.vb.addCount)
		specWarnMagmaSculptor:Play("killbigmob")
		timerMagmaSculptorCD:Start(nil, self.vb.addCount+1)
	elseif spellId == 200700 then
		specWarnLandSlide:Show()
		specWarnLandSlide:Play("shockwave")
		timerLandSlideCD:Start()
	elseif spellId == 200404 and self:AntiSpam(8, 1) then
		self.vb.waveCount = self.vb.waveCount + 1
		if self:IsTank() then
			specWarnMagmaWave2:Show()
			specWarnMagmaWave2:Play("specialsoon")
		else
			specWarnMagmaWave:Show(shelterName)
			specWarnMagmaWave:Play("findshelter")
		end
		timerMagmaWaveCD:Start(nil, self.vb.waveCount+1)
		timerMagmaWave:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 200154 then
		if args:IsPlayer() then
			specWarnBurningHatred:Show()
			specWarnBurningHatred:Play("targetyou")
		else
			warnBurningHatred:Show(args.destName)
		end
		if self.Options.SetIconOnBurningHatred then
			self:SetIcon(args.destName, 8)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 200154 then
		if self.Options.SetIconOnBurningHatred then
			self:SetIcon(args.destName, 0)
		end
	end
end
	
--1 second faster than combat log. 1 second slower than Unit event callout but that's no longer reliable.
function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if msg:find("spell:200404") and self:AntiSpam(8, 1) then
		self.vb.waveCount = self.vb.waveCount + 1
		if self:IsTank() then
			specWarnMagmaWave2:Show()
			specWarnMagmaWave2:Play("specialsoon")
		else
			specWarnMagmaWave:Show(shelterName)
			specWarnMagmaWave:Play("findshelter")
		end
		timerMagmaWaveCD:Start(nil, self.vb.waveCount+1)
		timerMagmaWave:Start()
	end
end
