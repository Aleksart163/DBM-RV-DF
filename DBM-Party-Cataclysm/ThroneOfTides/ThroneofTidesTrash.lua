if (DBM:GetTOC() < 100200) then return end--DO NOT DELETE DO NOT DELETE DO NOT DELETE. We don't want this module loading in cataclysm
local mod	= DBM:NewMod("ThroneofTidesTrash", "DBM-Party-Cataclysm", 9)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260630000000")
--mod:SetModelID(47785)
mod:SetZone(643)

mod.isTrashMod = true
mod.isTrashModBossFightAllowed = true

mod:RegisterEvents(
	"SPELL_CAST_START 76813 76815 76820 426741 426684 426645 428926 76590 429021 426783 428542 429176 426905 76634",
--	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED 76820 428542 426618 426659 75992",
	"SPELL_AURA_APPLIED_DOSE 426659",
	"SPELL_AURA_REMOVED 76820 75992",
	"SPELL_PERIODIC_DAMAGE 426688",
	"SPELL_PERIODIC_MISSED 426688",
	"UNIT_DIED"
)

--TODO, additional spells not covered in wowhead guide?
--TODO, hybrid the mod for cataclysm classic (which basically would only have like 3-4 spells of this entire list
--[[
(ability.id = 76813 or ability.id = 76815 or ability.id = 76820 or ability.id = 426741 or ability.id = 426684 or ability.id = 426645 or ability.id = 428926 or ability.id = 76590 or ability.id = 429021 or ability.id = 426783 or ability.id = 428542 or ability.id = 429176 or ability.id = 426905) and type = "begincast"
--]]
--https://www.wowhead.com/guide/mythic-plus-dungeons/throne-of-the-tides-strategy
local warnLightningSurge			= mod:NewTargetNoFilterAnnounce(75992, 2) --Выброс тока
local warnCrushingDepths			= mod:NewTargetNoFilterAnnounce(428542, 4) --Морская пучина
local warnSlitheringAssault			= mod:NewTargetNoFilterAnnounce(426618, 2, nil, "RemoveEnrage") --Змеиная скорость
local warnHealingWave				= mod:NewCastAnnounce(76813, 3) --Волна исцеления
local warnHex						= mod:NewCastAnnounce(76820, 2) --Сглаз
local warnClenchingTentacles		= mod:NewCastAnnounce(428926, 4, nil, nil, nil, nil, nil, 13) --Стискивающие щупальца
local warnPsionicPulse				= mod:NewCastAnnounce(426905, 4, nil, nil, nil, nil, nil, 3) --Псионный импульс
local warnAcidBarrage				= mod:NewSpellAnnounce(426645, 4) --Обстрел кислотой , nil, nil, nil, nil, nil, 3
local warnRazorJaws					= mod:NewStackAnnounce(426659, 2, nil, "Tank|Healer") --Острые клыки

local specWarnSwell					= mod:NewSpecialWarningSpell(76634, nil, nil, DBM_COMMON_L.AOEDAMAGE, 2, 2) --Зыбь (АоЕ)
local specWarnLightningSurge		= mod:NewSpecialWarningMoveAway(75992, nil, nil, nil, 4, 2) --Выброс тока
local specWarnClenchingTentacles	= mod:NewSpecialWarningSpell(428926, nil, nil, DBM_COMMON_L.ATTRACTION, 1, 2) --Стискивающие щупальца (Притягивание)
local specWarnShadowSmash			= mod:NewSpecialWarningRun(76590, nil, 185824, nil, 4, 2) --Мощный удар тьмы (Взрыв)
local specWarnVolatileBolt			= mod:NewSpecialWarningDodge(426684, nil, 174716, nil, 2, 2) --Нестабильная стрела (Бомба)
local specWarnShellbreaker			= mod:NewSpecialWarningDefensive(426741, nil, nil, nil, 3, 2) --Крушитель раковин
local specWarnCrush					= mod:NewSpecialWarningDefensive(429021, nil, nil, nil, 1, 2) --Сокрушение
--local yellnViciousAmbush			= mod:NewYell(388984)
local specWarnHealingWave			= mod:NewSpecialWarningInterrupt(76813, "HasInterrupt", nil, nil, 1, 2) --Волна исцеления
local specWarnWrath					= mod:NewSpecialWarningInterrupt(76815, false, nil, nil, 1, 2)--TODO, Is this even used in 10.2 version? no log of it
local specWarnMindFlay				= mod:NewSpecialWarningInterrupt(426783, "HasInterrupt", nil, nil, 1, 2)
local specWarnAquablast				= mod:NewSpecialWarningInterrupt(429176, "HasInterrupt", nil, nil, 1, 2)
local specWarnHex					= mod:NewSpecialWarningDispel(76820, "RemoveCurse", nil, nil, 1, 2) --Сглаз
local specWarnGTFO					= mod:NewSpecialWarningGTFO(426688, nil, nil, nil, 1, 8)

local timerSwellCD					= mod:NewCDNPTimer(20, 76634, DBM_COMMON_L.AOEDAMAGE, nil, nil, 2) --Зыбь (АоЕ)
local timerHealingWaveCD			= mod:NewCDNPTimer(17, 76813, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Волна исцеления 17-18.2
local timerHexCD					= mod:NewCDNPTimer(20.4, 76820, nil, nil, nil, 5, nil, DBM_COMMON_L.CURSE_ICON) --Сглаз Weak sample size, could be wrong
local timerCrushingDepthsCD			= mod:NewCDNPTimer(27.9, 428542, nil, nil, nil, 5, nil, DBM_COMMON_L.HEALER_ICON) --Морская пучина Weak sample size, could be wrong
local timerShellbreakerCD			= mod:NewCDNPTimer(17, 426741, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON) --Крушитель раковин 17-19 (8.4?)
local timerVolatileBoltCD			= mod:NewCDNPTimer(20.6, 426684, 174716, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Нестабильная стрела (Бомба) 20.6-24.2
local timerAcidBarrageCD			= mod:NewCDNPTimer(10.2, 426645, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON) --Обстрел кислотой 10.2-13 (8.7 lowest?)
local timerClenchingTentaclesCD		= mod:NewCDNPTimer(24, 428926, DBM_COMMON_L.ATTRACTION, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON) --Стискивающие щупальца (Притягивание) 24.3-25.5
local timerCrushCD					= mod:NewCDNPTimer(17, 429021, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON) --Сокрушение
local timerPsionicPulseCD			= mod:NewCDNPTimer(7, 426905, nil, nil, nil, 2) --Псионный импульс
local timerMindFlayCD				= mod:NewCDNPTimer(8.1, 426783, nil, nil, nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON)

local yellHex						= mod:NewYell(76820, nil, nil, nil, "YELL") --Сглаз
local yellHexFades					= mod:NewShortFadesYell(76820, nil, nil, nil, "YELL") --Сглаз
local yellLightningSurge			= mod:NewYell(75992, nil, nil, nil, "YELL") --Выброс тока
local yellLightningSurgeFades		= mod:NewShortFadesYell(75992, nil, nil, nil, "YELL") --Выброс тока
local yellCrushingDepths			= mod:NewYell(428542, nil, nil, nil, "YELL") --Морская пучина
--Antispam IDs for this mod: 1 run away, 2 dodge, 3 dispel, 4 incoming damage, 5 you/role, 6 misc, 7 off interrupt, 8 GTFO

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if not self:IsValidWarning(args.sourceGUID) then return end
	if spellId == 76813 then
		timerHealingWaveCD:Start(nil, args.sourceGUID)
		if self.Options.SpecWarn76813interrupt and self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnHealingWave:Show(args.sourceName)
			specWarnHealingWave:Play("kickcast")
		elseif self:AntiSpam(3, 7) then
			warnHealingWave:Show()
		end
	elseif spellId == 76815 then
		--TODO, timer? Does this even exist?
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnWrath:Show(args.sourceName)
			specWarnWrath:Play("kickcast")
		end
	elseif spellId == 429176 then
		--No timer, it's basically spammed off spell lockout
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnAquablast:Show(args.sourceName)
			specWarnAquablast:Play("kickcast")
		end
	elseif spellId == 76820 then
		timerHexCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, 5) then
			warnHex:Show()
		end
	elseif spellId == 428542 then
		timerCrushingDepthsCD:Start(nil, args.sourceGUID)
	elseif spellId == 426741 then
		timerShellbreakerCD:Start(nil, args.sourceGUID)
		if self:IsTanking("player", nil, nil, true, args.sourceGUID) and self:AntiSpam(3, 5) then
			specWarnShellbreaker:Show()
			specWarnShellbreaker:Play("defensive")
		end
	elseif spellId == 426684 then
		timerVolatileBoltCD:Start(nil, args.sourceGUID)
		--If remaining time on acid barrage is less than 6 seconds when volatile bolt is cast, it'll be extended
		if timerAcidBarrageCD:GetRemaining(args.sourceGUID) < 4.8 then
			DBM:Debug("extending acid barrage to 4.8 seconds", 2)
			timerAcidBarrageCD:Stop(args.sourceGUID)
			timerAcidBarrageCD:Start(4.8, args.sourceGUID)
		end
		if self:AntiSpam(3, 2) then
			specWarnVolatileBolt:Show()
			specWarnVolatileBolt:Play("watchstep")
		end
	elseif spellId == 426645 then
		timerAcidBarrageCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, 6) then
			warnAcidBarrage:Show()
--			warnAcidBarrage:Play("shockwave")
		end
	elseif spellId == 428926 then--Clenching tentacles is the new 10.2 mechanic that now triggers before the old Shadow Smash
		timerClenchingTentaclesCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, 6) then
			warnClenchingTentacles:Show()
			specWarnClenchingTentacles:Show()
			specWarnClenchingTentacles:Play("pullin")
		end
	elseif spellId == 76590 and self:AntiSpam(3, 1) then
		specWarnShadowSmash:Show()
		specWarnShadowSmash:Play("justrun")
	elseif spellId == 429021 then
		timerCrushCD:Start(nil, args.sourceGUID)
		if self:IsTanking("player", nil, nil, true, args.sourceGUID) and self:AntiSpam(3, 5) then
			specWarnCrush:Show()
			specWarnCrush:Play("defensive")
		end
	elseif spellId == 426905 then
		timerPsionicPulseCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(5, 6) then--A lot of these exist in a single pack, so a larger 5 second antispam window used
			warnPsionicPulse:Show()
			warnPsionicPulse:Play("crowdcontrol")
		end
	elseif spellId == 426783 then
		timerMindFlayCD:Start(nil, args.sourceGUID)
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnMindFlay:Show(args.sourceName)
			specWarnMindFlay:Play("kickcast")
		end
	elseif spellId == 76634 then
		timerSwellCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(2, "Swell") then
			specWarnSwell:Show()
			specWarnSwell:Play("aesoon")
		end
	end
end

--[[
function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 88055 then

	end
end
--]]

function mod:SPELL_AURA_APPLIED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 76820 and args:IsDestTypePlayer() then
		if args:IsPlayer() then
			yellHex:Yell()
			yellHexFades:Countdown(spellId)
		elseif self:CheckDispelFilter("curse") and self:AntiSpam(3, 3) then
			specWarnHex:Show(args.destName)
			specWarnHex:Play("helpdispel")
		end
	elseif spellId == 428542 and args:IsDestTypePlayer() then
		warnCrushingDepths:CombinedShow(0.5, args.destName)
		if args:IsPlayer() then
			yellCrushingDepths:Yell()
		end
	elseif spellId == 426618 and self:AntiSpam(3, 5) then
		warnSlitheringAssault:Show(args.destName)
	elseif spellId == 426659 and args:IsDestTypePlayer() then
		local amount = args.amount or 1
		if self:AntiSpam(3, 5) then
			warnRazorJaws:Show(args.destName, amount)
		end
	elseif spellId == 75992 and args:IsDestTypePlayer() then
		warnLightningSurge:CombinedShow(0.5, args.destName)
		if args:IsPlayer() then
			specWarnLightningSurge:Show()
			specWarnLightningSurge:Play("runout")
			yellLightningSurge:Yell()
			yellLightningSurgeFades:Countdown(spellId)
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED


function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 76820 then
		if args:IsPlayer() then
			yellHexFades:Cancel()
		end
	elseif spellId == 75992 then
		if args:IsPlayer() then
			yellLightningSurgeFades:Cancel()
		end
	end
end


function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 41096 then--Naz'jar Oracle
		timerHealingWaveCD:Stop(args.destGUID)
		timerHexCD:Stop(args.destGUID)
	elseif cid == 40577 then--Naz'jar Sentinel
		timerCrushingDepthsCD:Stop(args.destGUID)
		timerShellbreakerCD:Stop(args.destGUID)
	elseif cid == 212673 then--Naj'jar Ravager
		timerVolatileBoltCD:Stop(args.destGUID)
		timerAcidBarrageCD:Stop(args.destGUID)
	elseif cid == 40936 then--Faceless watcher
		timerClenchingTentaclesCD:Stop(args.destGUID)
		timerCrushCD:Stop(args.destGUID)
	elseif cid == 212778 then--Minion of Ghur'sha
		timerPsionicPulseCD:Stop(args.destGUID)
	elseif cid == 212775 then--Faceless Seer
		timerMindFlayCD:Stop(args.destGUID)
	elseif cid == 40925 then --Опороченный часовой
		timerSwellCD:Stop(args.destGUID)
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 426688 and destGUID == UnitGUID("player") and self:AntiSpam(3, 8) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
