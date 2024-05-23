local mod	= DBM:NewMod("TheNokhudOffensiveTrash", "DBM-Party-Dragonflight", 3)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20231026112110")
--mod:SetModelID(47785)
mod.isTrashMod = true

mod:RegisterEvents(
	"SPELL_CAST_START 387145 386024 387127 384336 387629 387614 387411 382233 373395 383823 384365 386694 387125 387440 386012 386028",
	"SPELL_CAST_SUCCESS 384476",
	"SPELL_AURA_APPLIED 395035 334610 386223 345561",
--	"SPELL_AURA_APPLIED_DOSE 339528",
--	"SPELL_AURA_REMOVED 339525",
	"SPELL_PERIODIC_DAMAGE 386912",
	"SPELL_PERIODIC_MISSED 386912"
	"UNIT_DIED"
)

--TODO, https://www.wowhead.com/beta/spell=381683/swift-stab ?
--TODO, target scan https://www.wowhead.com/beta/spell=387127/chain-lightning ?
--Lady's Trash, minus bottled anima, which will need a unit event to detect it looks like
--[[
(ability.id = 373395 or ability.id = 387411 or ability.id = 373395 or ability.id = 383823 or ability.id = 384365 or ability.id = 387440 or ability.id = 384336 or ability.id = 386024) and type = "begincast"
--]]
local warnThunderClap						= mod:NewCastAnnounce(386028, 4) --Удар грома
local warnTotemicOverload					= mod:NewCastAnnounce(387145, 3) --Тотемная перегрузка
local warnChantoftheDead					= mod:NewCastAnnounce(387614, 3) --Песнопения мертвых
local warnTempest							= mod:NewCastAnnounce(373395, 4)
local warnDeathBoltVolley					= mod:NewCastAnnounce(387411, 3)
local warnBloodcurdlingShout				= mod:NewCastAnnounce(373395, 3)
local warnRallytheClan						= mod:NewCastAnnounce(383823, 4, nil, nil, nil, nil, nil, 3)--Has to be stunned/disrupted
local warnDisruptiveShout					= mod:NewCastAnnounce(384365, 3)
local warnStormsurge						= mod:NewCastAnnounce(386694, 3)
local warnThunderstrike						= mod:NewCastAnnounce(387125, 3, nil, nil, "Tank")
local warnDesecratingRoar					= mod:NewCastAnnounce(387440, 4, nil, nil, nil, nil, nil, 3)--Has to be stunned/disrupted

local specWarnThunderClap					= mod:NewSpecialWarningDodge(386028, "Melee", nil, nil, 2, 2) --Удар грома
local specWarnShatterSoul					= mod:NewSpecialWarningMoveTo(395035, nil, nil, nil, 1, 2)
local specWarnChainLightning				= mod:NewSpecialWarningMoveAway(387127, nil, nil, nil, 1, 2)
local specWarnHuntPrey						= mod:NewSpecialWarningYou(334610, nil, nil, nil, 1, 2)--This might throw duplicate spell alert in debug, that's cause it is in fact used in necrotic wake too
local specWarnWarStomp						= mod:NewSpecialWarningDodge(384336, nil, nil, nil, 2, 2)
local specWarnBroadStomp					= mod:NewSpecialWarningDodge(382233, nil, nil, nil, 2, 2)
local specWarnRottingWind					= mod:NewSpecialWarningDodge(387629, nil, nil, nil, 2, 2)
local specWarnRainofArrows					= mod:NewSpecialWarningDodge(384476, nil, nil, nil, 2, 2)
--local yellConcentrateAnimaFades				= mod:NewShortFadesYell(339525)
--local specWarnSharedSuffering				= mod:NewSpecialWarningYou(339607, nil, nil, nil, 1, 2)
local specWarnStormshield					= mod:NewSpecialWarningDispel(386223, "MagicDispeller", nil, nil, 1, 2)
local specWarnTempest						= mod:NewSpecialWarningInterrupt(386024, "HasInterrupt", nil, nil, 1, 2)
local specWarnDeathBoltVolley				= mod:NewSpecialWarningInterrupt(387411, "HasInterrupt", nil, nil, 1, 2)
local specWarnBloodcurdlingShout			= mod:NewSpecialWarningInterrupt(373395, "HasInterrupt", nil, nil, 1, 2)
local specWarnDisruptiveShout				= mod:NewSpecialWarningInterrupt(384365, "HasInterrupt", nil, nil, 1, 2)
local specWarnStormbolt						= mod:NewSpecialWarningInterrupt(386012, "HasInterrupt", nil, nil, 1, 2) --Грозовой удар
local specWarnGTFO							= mod:NewSpecialWarningGTFO(386912, nil, nil, nil, 1, 8) --Туча энергии бури

local timerThunderClapCD					= mod:NewCDNPTimer(19.5, 386028, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON) --Удар грома
local timerRallytheClanCD					= mod:NewCDNPTimer(20, 383823, nil, nil, nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Клич клана 20-23
local timerWarStompCD						= mod:NewCDNPTimer(15.7, 384336, nil, nil, nil, 3) --Громовая поступь
local timerChantoftheDeadCD					= mod:NewCDNPTimer(23, 387614, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON) --Песнопения мертвых
local timerDisruptingShoutCD				= mod:NewCDNPTimer(21.8, 384365, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Прерывающий крик 20-30ish
local timerTempestCD						= mod:NewCDNPTimer(20, 386024, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Буря20-25
local timerDesecratingRoarCD				= mod:NewCDNPTimer(15.8, 387440, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Оскверняющий рык
local timerDeathBoltVolleyCD				= mod:NewCDNPTimer(10.9, 387411, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Залп стрел смерти
local timerBloodcurdlingShoutCD				= mod:NewCDNPTimer(19.1, 373395, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Кровожадный вопль

local yellChainLightning					= mod:NewYell(387127, nil, nil, nil, "YELL")

--local playerName = UnitName("player")

local teeramod = DBM:GetModByName("2478")

--Antispam IDs for this mod: 1 run away, 2 dodge, 3 dispel, 4 incoming damage, 5 you/role, 6 misc, 7 off interrupt

function mod:CLTarget(targetname)
	if not targetname then return end
	if targetname == UnitName("player") then
		if self:AntiSpam(4, 5) then
			specWarnChainLightning:Show()
			specWarnChainLightning:Play("runout")
		end
		yellChainLightning:Yell()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if not self:IsValidWarning(args.sourceGUID) then return end
	if spellId == 387145 and self:AntiSpam(5, 4) then
		warnTotemicOverload:Show()
	elseif spellId == 386024 then
		timerTempestCD:Start(nil, args.sourceGUID)
		if self.Options.SpecWarn386024interrupt and self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnTempest:Show(args.sourceName)
			specWarnTempest:Play("kickcast")
		elseif self:AntiSpam(3, 7) then
			warnTempest:Show()
		end
	elseif spellId == 387411 then
		timerDeathBoltVolleyCD:Start(nil, args.sourceGUID)
		if self.Options.SpecWarn387411interrupt and self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnDeathBoltVolley:Show(args.sourceName)
			specWarnDeathBoltVolley:Play("kickcast")
		elseif self:AntiSpam(3, 7) then
			warnDeathBoltVolley:Show()
		end
	elseif spellId == 373395 then
		timerBloodcurdlingShoutCD:Start(nil, args.sourceGUID)
		if self.Options.SpecWarn373395interrupt and self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnBloodcurdlingShout:Show(args.sourceName)
			specWarnBloodcurdlingShout:Play("kickcast")
		elseif self:AntiSpam(3, 7) then
			warnBloodcurdlingShout:Show()
		end
	elseif spellId == 383823 then
		timerRallytheClanCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, 5) then
			warnRallytheClan:Show()
			warnRallytheClan:Play("crowdcontrol")
		end
	elseif spellId == 387440 then
		timerDesecratingRoarCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, 5) then
			warnDesecratingRoar:Show()
			warnDesecratingRoar:Play("crowdcontrol")
		end
	elseif spellId == 384365 then
		timerDisruptingShoutCD:Start(nil, args.sourceGUID)
		if self.Options.SpecWarn384365interrupt and self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnDisruptiveShout:Show(args.sourceName)
			specWarnDisruptiveShout:Play("kickcast")
		elseif self:AntiSpam(3, 7) then
			warnDisruptiveShout:Show()
		end
	elseif spellId == 386012 then --Грозовой удар
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnStormbolt:Show(args.sourceName)
			specWarnStormbolt:Play("kickcast")
		end
	elseif spellId == 387127 then
		self:BossTargetScanner(args.sourceGUID, "CLTarget", 0.1, 2)
	elseif spellId == 384336 then
		timerWarStompCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, 2) then
			specWarnWarStomp:Show()
			specWarnWarStomp:Play("watchstep")
		end
	elseif spellId == 387629 and self:AntiSpam(3, 2) then
		specWarnRottingWind:Show()
		specWarnRottingWind:Play("shockwave")
	elseif spellId == 382233 and self:AntiSpam(3, 2) then
		specWarnBroadStomp:Show()
		specWarnBroadStomp:Play("shockwave")
	elseif spellId == 387614 then --Песнопения мертвых
		timerChantoftheDeadCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, "ChantoftheDead") then
			warnChantoftheDead:Show()
		end
	elseif spellId == 386694 and self:AntiSpam(3, 6) then
		warnStormsurge:Show()
	elseif spellId == 387125 and self:AntiSpam(3, 5) then
		warnThunderstrike:Show()
	elseif spellId == 386028 then
		timerThunderClapCD:Start(nil, args.sourceGUID)
		specWarnThunderClap:Show()
		specWarnThunderClap:Play("runout")
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if not self:IsValidWarning(args.sourceGUID) then return end
	if spellId == 384476 and self:AntiSpam(3, 2) then
		specWarnRainofArrows:Show()
		specWarnRainofArrows:Play("watchstep")
	end
end


function mod:SPELL_AURA_APPLIED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 395035 and args:IsPlayer() then
		specWarnShatterSoul:Show(L.Soul)
		specWarnShatterSoul:Play("targetyou")
	elseif spellId == 334610 and args:IsPlayer() and not self:IsTank() and self:AntiSpam(3, 5) then
		specWarnHuntPrey:Show()
		specWarnHuntPrey:Play("targetyou")
	elseif spellId == 386223 and args:IsDestTypeHostile() and self:AntiSpam(3, 3) then
		specWarnStormshield:Show(args.destName)
		specWarnStormshield:Play("helpdispel")
	elseif spellId == 345561 and self:AntiSpam(5, 8) then--Life Link
		teeramod:SendSync("TeeraRP")
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 192796 then--Nokhud Hornsounder
		timerRallytheClanCD:Stop(args.destGUID)
	elseif cid == 191847 then--Nokhud Plainstomper
		timerWarStompCD:Stop(args.destGUID)
		timerDisruptingShoutCD:Stop(args.destGUID)
	elseif cid == 192800 then--Nokhud Lancemaster
		timerDisruptingShoutCD:Stop(args.destGUID)
	elseif cid == 194894 then--Primalist Stormspeaker
		timerTempestCD:Stop(args.destGUID)
	elseif cid == 195878 then--Uthel Beastcaller
		timerDesecratingRoarCD:Stop(args.destGUID)
	elseif cid == 195851 then --Мурчальский вестник прошляпа
		timerChantoftheDeadCD:Stop(args.destGUID)
	elseif cid == 195928 or cid == 195927 or cid == 195930 or cid == 195929 then--All 4 Soulharvesters
		timerDeathBoltVolleyCD:Stop(args.destGUID)
	elseif cid == 193462 then--Batak
		timerBloodcurdlingShoutCD:Stop(args.destGUID)
	elseif cid == 195696 then
		timerThunderClapCD:Stop(args.destGUID)
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 386912 and destGUID == UnitGUID("player") and self:AntiSpam(2, "StormsurgeCloud") then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
