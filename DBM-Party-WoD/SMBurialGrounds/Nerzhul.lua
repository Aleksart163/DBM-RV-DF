local mod	= DBM:NewMod(1160, "DBM-Party-WoD", 6, 537)
local L		= mod:GetLocalizedStrings()

mod.statTypes = "normal,heroic,mythic,challenge,timewalker"

mod:SetRevision("20240201070000")
mod:SetCreatureID(76407)
mod:SetEncounterID(1682)
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 154442",
	"SPELL_AURA_APPLIED 154469",
	"SPELL_SUMMON 154350",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

--[[
ability.id = 154442 and type = "begincast"
 or ability.id = 154350
 or ability.id = 154671
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
--TODO, 154350 is not firing spell summmon anymore in 10.0.2 M+ version, Omen of Death moved to USCS but target scan needs to be rechecked as well
local warnOmenOfDeath			= mod:NewSpellAnnounce(154350, 4)

local specWarnRitualOfBones		= mod:NewSpecialWarningDodge(154671, nil, nil, nil, 3, 2) --Костяной ритуал
local specWarnRitualOfBones2	= mod:NewSpecialWarningYou(154469, nil, nil, nil, 3, 4)
local specWarnMalevolence		= mod:NewSpecialWarningDodge(154442, nil, nil, nil, 2, 2)

local timerRitualOfBonesCD		= mod:NewCDTimer(51.5, 154671, nil, nil, nil, 7, nil, nil, nil, 3, 5) --Костяной ритуал
local timerOmenOfDeathCD		= mod:NewCDTimer(10.5, 154350, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Знамение смерти

mod.vb.MurchalProshlyapenCount = 0

local MurchalProshlyap = false

local function startProshlyapationOfMurchal(self)
	if not UnitIsDeadOrGhost("player") then
		specWarnRitualOfBones:Show()
		specWarnRitualOfBones:Play("specialsoon")
	end
	if not MurchalProshlyap then
		MurchalProshlyap = true
	end
	timerRitualOfBonesCD:Start()
	timerOmenOfDeathCD:Start(25.5)
	self.vb.MurchalProshlyapenCount = 0
	DBM:Debug("MurchalProshlyapenCount = 0")
	self:Schedule(51.5, startProshlyapationOfMurchal, self)
end

function mod:OnCombatStart(delay)
	self.vb.MurchalProshlyapenCount = 0
	MurchalProshlyap = false
	timerOmenOfDeathCD:Start(9.7-delay)
	timerRitualOfBonesCD:Start(20.5-delay)
	self:Schedule(20.5, startProshlyapationOfMurchal, self)
end

function mod:OnCombatEnd()
	self:Unschedule(startProshlyapationOfMurchal)
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 154442 then
		specWarnMalevolence:Show()
		specWarnMalevolence:Play("shockwave")
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 154469 then
		if args:IsPlayer() then
			specWarnRitualOfBones2:Show()
			specWarnRitualOfBones2:Play("defensive")
		end
	end
end

function mod:SPELL_SUMMON(args)
	if args.spellId == 154350 then
		self.vb.MurchalProshlyapenCount = self.vb.MurchalProshlyapenCount + 1
		warnOmenOfDeath:Show()
		if MurchalProshlyap then
			if self.vb.MurchalProshlyapenCount == 1 then
				timerOmenOfDeathCD:Start(14.8)
				DBM:Debug("MurchalProshlyapenCount = 1")
			elseif self.vb.MurchalProshlyapenCount == 2 then
				timerOmenOfDeathCD:Start(11)
				DBM:Debug("MurchalProshlyapenCount = 2")
			end
		end
	end
end
