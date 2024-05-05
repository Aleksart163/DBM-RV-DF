local mod	= DBM:NewMod(335, "DBM-Party-MoP", 1, 313)
local L		= mod:GetLocalizedStrings()

mod.statTypes = "normal,heroic,challenge,timewalker"

mod:SetRevision("20230504231118")
mod:SetCreatureID(56439)
mod:SetEncounterID(1439)
mod:SetHotfixNoticeRev(20230103000000)
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 117665",
	"SPELL_CAST_SUCCESS 106113",--106736
	"SPELL_AURA_APPLIED 117665 106113 110099",
	"SPELL_AURA_REMOVED 117665 106113"
)

--[[
(ability.id = 106736 or ability.id = 106113) and type = "cast"
 or ability.id = 117665 and (type = "begincast" or type = "removebuff")
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
--NOTE, 106736 no longer in combat log
--TODO, verify bounds of reality on more logs, including non mythic+
--local warnWitherWill					= mod:NewSpellAnnounce(106736, 3, nil, false, 2)
local warnTouchofNothingness			= mod:NewTargetNoFilterAnnounce(106113, 3) --Осознание ничтожности

local specWarnBoundsOfReality			= mod:NewSpecialWarningSpell(117665, nil, nil, nil, 2, 2) --Границы реальности
local specWarnTouchOfNothingness		= mod:NewSpecialWarningMoveAway(106113, nil, nil, nil, 2, 2) --Осознание ничтожности
local specWarnTouchOfNothingnessDispel	= mod:NewSpecialWarningDispel(106113, "RemoveMagic", nil, nil, 3, 2) --Осознание ничтожности
local specWarnShadowsOfDoubt			= mod:NewSpecialWarningGTFO(110099, nil, nil, nil, 1, 8)--Actually used by his trash, but in a speed run, you tend to pull it all together

local timerTouchofNothingnessCD			= mod:NewCDTimer(20.2, 106113, nil, nil, 3, 3, nil, DBM_COMMON_L.MAGIC_ICON) --Осознание ничтожности 15.5~20 second variations.
local timerTouchofNothingness			= mod:NewTargetTimer(30, 106113, nil, false, 2, 5, nil, DBM_COMMON_L.MAGIC_ICON) --Осознание ничтожности
local timerBoundsOfRealityCD			= mod:NewCDTimer(58.2, 117665, nil, nil, nil, 6, nil, nil, nil, 3, 5) --Границы реальности
local timerBoundsOfReality				= mod:NewBuffFadesTimer(30, 117665, nil, nil, nil, 6) --Границы реальности

local yellTouchOfNothingness			= mod:NewYell(106113, nil, nil, nil, "YELL") --Осознание ничтожности

function mod:OnCombatStart(delay)
	timerTouchofNothingnessCD:Start(10.9-delay)
	timerBoundsOfRealityCD:Start(20.3-delay)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 117665 then --Границы реальности
		specWarnBoundsOfReality:Show()
		specWarnBoundsOfReality:Play("specialsoon")
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 106113 then
		timerTouchofNothingnessCD:Start()
--	elseif args.spellId == 106736 then
--		warnWitherWill:Show()
	end
end


function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 117665 then
		timerTouchofNothingnessCD:Cancel()
		timerBoundsOfReality:Start()
		timerBoundsOfRealityCD:Start(self:IsMythicPlus() and 68.2 or 58.2)--TODO, confirm if non mythic plus still 58
	elseif args.spellId == 106113 then --Осознание ничтожности
		if args:IsPlayer() then
			specWarnTouchOfNothingness:Show()
			specWarnTouchOfNothingness:Play("scatter")
			yellTouchOfNothingness:Yell()
		elseif not args:IsPlayer() then
			warnTouchofNothingness:CombinedShow(0.8, args.destName)
			specWarnTouchOfNothingnessDispel:CombinedShow(0.8, args.destName)
			specWarnTouchOfNothingnessDispel:ScheduleVoice(0.8, "helpdispel")
		end
		timerTouchofNothingness:Start(args.destName)
	elseif args.spellId == 110099 and args:IsPlayer() then
		specWarnShadowsOfDoubt:Show(args.spellName)
		specWarnShadowsOfDoubt:Play("watchfeet")
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 117665 then
		timerBoundsOfReality:Cancel()
	elseif args.spellId == 106113 then
		timerTouchofNothingness:Cancel(args.destName)
	end
end
