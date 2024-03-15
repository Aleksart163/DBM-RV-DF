local mod	= DBM:NewMod("VaultoftheIncarnatesTrash", "DBM-Raids-Dragonflight", 3)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20230908090104")
--mod:SetModelID(47785)
mod:SetUsedIcons(8)
mod.isTrashMod = true

mod:RegisterEvents(
	"SPELL_CAST_START 393783 393787 392635 392280",
	"SPELL_CAST_SUCCESS 393787 392280",
	"SPELL_AURA_APPLIED 395273"
--	"SPELL_AURA_APPLIED_DOSE 339528",
--	"SPELL_AURA_REMOVED 339525"
)

--TODO, icon mark shared suffering? Maybe when they fix ENCOUNTER_START, for now I don't want to risk trash mod messing with a boss mods icon marking
--Lady's Trash, minus bottled anima, which will need a unit event to detect it looks like
--local warnConcentrateAnima					= mod:NewTargetNoFilterAnnounce(339525, 3)

--local specWarnConcentrateAnima				= mod:NewSpecialWarningMoveAway(310780, nil, nil, nil, 1, 2)
--local yellConcentrateAnima					= mod:NewYell(339525)
--local yellConcentrateAnimaFades				= mod:NewShortFadesYell(339525)
--local specWarnSharedSuffering				= mod:NewSpecialWarningYou(339607, nil, nil, nil, 1, 2)
--local specWarnDirgefromBelow				= mod:NewSpecialWarningInterrupt(310839, "HasInterrupt", nil, nil, 1, 2)
local specWarnElectricSurge						= mod:NewSpecialWarningMoveAway(395273, nil, nil, nil, 4, 2)
local specWarnPulverizingBreath					= mod:NewSpecialWarningDefensive(392635, nil, nil, nil, 3, 2) --Дробящее дыхание
local specWarnMagmaBreath						= mod:NewSpecialWarningDefensive(393783, nil, nil, nil, 3, 2) --Дыхание магмой
local specWarnStoneBarrage						= mod:NewSpecialWarningDefensive(392280, "-Tank", nil, nil, 2, 2) --Каменный обстрел
local specWarnStoneBarrage2						= mod:NewSpecialWarningDodge(392280, nil, nil, nil, 2, 2) --Каменный обстрел
local specWarnIgnite							= mod:NewSpecialWarningDefensive(393787, "-Tank", nil, nil, 2, 2) --Воспламенение
local specWarnIgnite2							= mod:NewSpecialWarningDodge(393787, nil, nil, nil, 2, 2) --Воспламенение

local yellElectricSurge							= mod:NewShortYell(395273, nil, nil, nil, "YELL") --Электрический импульс
local yellElectricSurge2						= mod:NewShortFadesYell(395273, nil, nil, nil, "YELL") --Электрический импульс
local yellPulverizingBreath						= mod:NewShortYell(392635, nil, nil, nil, "YELL") --Дробящее дыхание
local yellMagmaBreath							= mod:NewShortYell(393783, nil, nil, nil, "YELL") --Дыхание магмой

mod:AddSetIconOption("SetIconOnPulverizingBreath", 392635, true, 0, {8})
mod:AddSetIconOption("SetIconOnMagmaBreathTarget", 393783, true, 0, {8})

function mod:PulverizingBreathTarget(targetname)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnPulverizingBreath:Show()
		specWarnPulverizingBreath:Play("defensive")
		yellPulverizingBreath:Yell()
	end
	if self.Options.SetIconOnPulverizingBreath then
		self:SetIcon(targetname, 8, 5)
	end
end

function mod:MagmaBreathTarget(targetname)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnMagmaBreath:Show()
		specWarnMagmaBreath:Play("defensive")
		yellMagmaBreath:Yell()
	end
	if self.Options.SetIconOnMagmaBreathTarget then
		self:SetIcon(targetname, 8, 5)
	end
end

--local playerName = UnitName("player")

--Antispam IDs for this mod: 1 run away, 2 dodge, 3 dispel, 4 incoming damage, 5 you/role, 6 misc

function mod:SPELL_CAST_START(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 392635 then --Дробящее дыхание
		self:ScheduleMethod(0.1, "BossTargetScanner", args.sourceGUID, "PulverizingBreathTarget", 0.1, 8)
	elseif spellId == 393783 then --Дыхание магмой
		self:ScheduleMethod(0.1, "BossTargetScanner", args.sourceGUID, "MagmaBreathTarget", 0.1, 2)
	elseif spellId == 392280 then --Каменный обстрел
		specWarnStoneBarrage:Show()
		specWarnStoneBarrage:Play("defensive")
	elseif spellId == 393787 then --Воспламенение
		specWarnIgnite:Show()
		specWarnIgnite:Play("defensive")
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 392280 then --Каменный обстрел
		specWarnStoneBarrage2:Show()
		specWarnStoneBarrage2:Play("watchfeet")
	elseif spellId == 393787 then --Воспламенение
		specWarnIgnite2:Show()
		specWarnIgnite2:Play("watchfeet")
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 395273 then --Электрический импульс
		if args:IsPlayer() then
			specWarnElectricSurge:Show()
			specWarnElectricSurge:Play("runout")
			yellElectricSurge:Yell()
			yellElectricSurge2:Countdown(spellId, 3)
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

--[[
function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 339525 and args:IsPlayer() then

	end
end
]]
