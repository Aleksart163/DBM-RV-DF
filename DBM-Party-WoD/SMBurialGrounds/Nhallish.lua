local mod	= DBM:NewMod(1168, "DBM-Party-WoD", 6, 537)
local L		= mod:GetLocalizedStrings()

mod.statTypes = "normal,heroic,mythic,challenge,timewalker"

mod:SetRevision("20230504231118")
mod:SetCreatureID(75829)
mod:SetEncounterID(1688)
mod:SetUsedIcons(8)
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 152801 153067 152792 153623 152962",
	"SPELL_AURA_APPLIED 152979 153033",
	"SPELL_AURA_REMOVED 152979 153033",
	"SPELL_PERIODIC_DAMAGE 153070",
	"SPELL_ABSORBED 153070"
)

--[[
(ability.id = 152801 or ability.id = 153067) and type = "begincast"
 or ability.id = 152979 and type = "applydebuff"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
local warnVoidBlast				= mod:NewTargetNoFilterAnnounce(152792, 4) --Вспышка Бездны

local specWarnVoidBlast			= mod:NewSpecialWarningDefensive(152792, nil, nil, nil, 3, 4) --Вспышка Бездны
local specWarnVoidVortex		= mod:NewSpecialWarningRun(152801, nil, nil, 2, 4, 2) --Водоворот Бездны
local specWarnSoulShred			= mod:NewSpecialWarningSpell(152979, nil, nil, nil, 1, 2) --Осколок души
local specWarnVoidDevastation	= mod:NewSpecialWarningDodge(153067, nil, nil, nil, 2, 2) --Опустошение Бездны
local specWarnVoidDevastationM	= mod:NewSpecialWarningGTFO(153070, nil, nil, nil, 1, 8)
local specWarnReturnedSoul		= mod:NewSpecialWarningYou(153033, nil, nil, nil, 1, 2) --Вернувшаяся душа

local timerVoidBlastCD			= mod:NewCDTimer(77, 152792, nil, nil, nil, 3, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON) --Вспышка Бездны
local timerPlanarShiftCD		= mod:NewCDTimer(77, 153623, nil, nil, nil, 3) --Сдвиг плоскости
local timerVoidVortexCD			= mod:NewCDTimer(77, 152801, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON) --Водоворот Бездны
local timerSoulStealCD			= mod:NewNextTimer(75, 152962, nil, nil, nil, 7) --Кража души
local timerSoulShred			= mod:NewBuffFadesTimer(20, 152979, nil, nil, nil, 7) --Осколок души
local timerReturnedSoul			= mod:NewBuffFadesTimer(20, 153033, nil, nil, nil, 7) --Вернувшаяся душа
local timerVoidDevastationCD	= mod:NewNextTimer(77, 153067, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON) --Опустошение Бездны

local yellVoidBlast				= mod:NewShortYell(152792, nil, nil, nil, "YELL") --Вспышка Бездны

mod:AddSetIconOption("SetIconOnVoidBlast", 152792, true, 0, {8})

function mod:VoidBlastTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnVoidBlast:Show()
		specWarnVoidBlast:Play("defensive")
		yellVoidBlast:Yell()
	else
		warnVoidBlast:Show(targetname)
	end
	if self.Options.SetIconOnVoidBlast then
		self:SetIcon(targetname, 8, 5)
	end
end

function mod:OnCombatStart(delay)
	timerVoidBlastCD:Start(10.5-delay) --
	timerPlanarShiftCD:Start(25.5-delay) --
	timerVoidVortexCD:Start(27.5-delay) --
	timerSoulStealCD:Start(37-delay)
	timerVoidDevastationCD:Start(65.3-delay)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 152801 then
		timerVoidVortexCD:Start()
		specWarnVoidVortex:Show()
		specWarnVoidVortex:Play("runaway")
	elseif spellId == 153067 then --Опустошение Бездны
		specWarnVoidDevastation:Show()
		specWarnVoidDevastation:Play("watchstep")
		timerVoidDevastationCD:Start()
	elseif spellId == 152792 then --Вспышка Бездны
		self:BossTargetScanner(args.sourceGUID, "VoidBlastTarget", 0.1, 2)
		timerVoidBlastCD:Start()
	elseif spellId == 152962 then --Кража души
		timerSoulStealCD:Start()
	elseif spellId == 153623 then --Сдвиг плоскости
		timerPlanarShiftCD:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 152979 then --Осколок души
		if args:IsPlayer() then
			specWarnSoulShred:Show()
			specWarnSoulShred:Play("killspirit")
			timerSoulShred:Start()
		end
	elseif spellId == 153033 then --Вернувшаяся душа
		if args:IsPlayer() then
			specWarnReturnedSoul:Show()
			specWarnReturnedSoul:Play("targetyou")
			timerReturnedSoul:Start()
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 152979 and args:IsPlayer() then --Осколок души
		timerSoulShred:Stop()
	elseif spellId == 153033 and args:IsPlayer() then --Вернувшаяся душа
		timerReturnedSoul:Stop()
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, destName, _, _, spellId, spellName)
	if spellId == 153070 and destGUID == UnitGUID("player") and self:AntiSpam(2, 1) then
		specWarnVoidDevastationM:Show(spellName)
		specWarnVoidDevastationM:Play("watchfeet")
	end
end
mod.SPELL_ABSORBED = mod.SPELL_PERIODIC_DAMAGE
