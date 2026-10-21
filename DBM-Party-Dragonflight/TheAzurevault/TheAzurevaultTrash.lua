local mod	= DBM:NewMod("TheAzurevaultTrash", "DBM-Party-Dragonflight", 6)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260930000000")
--mod:SetModelID(47785)
mod:SetZone(2515)

mod.isTrashMod = true
mod.isTrashModBossFightAllowed = true

mod:RegisterEvents(
	"SPELL_CAST_START 391136 370764 386526 387564 377105 370766 386546 387067 377488 396991 389804 374885 375652 391118",
	"SPELL_CAST_SUCCESS 374885 371358 375652 375596 391136",
	"SPELL_AURA_APPLIED 371007 395492 375596 374778 386549 389686",
--	"SPELL_AURA_APPLIED_DOSE 339528",
--	"SPELL_AURA_REMOVED 339525",
	"UNIT_DIED",
	"GOSSIP_SHOW"
)

--TODO, I don't think shoulder slam target scan worked, maybe try again though.
--TODO, add erratic growth interrupt?
--[[
(ability.id = 391136 or ability.id = 370764 or ability.id = 386526 or ability.id = 387564 or ability.id = 377105 or ability.id = 370766 or ability.id = 386546 or ability.id = 387067 or ability.id = 377488 or ability.id = 396991 or ability.id = 389804) and type = "begincast"
 or (ability.id = 374885 or ability.id = 371358 or ability.id = 375652 or ability.id = 375596 or ability.id = 391136) and type = "cast"
--]]
local warnNullStomp							= mod:NewCastAnnounce(386526, 2) --Нейтрализующий топот
local warnPiercingShards					= mod:NewCastAnnounce(370764, 4) --Острые осколки
local warnIceCutter							= mod:NewCastAnnounce(377105, 4, nil, nil, "Tank|Healer") --Ледокол
local warnIcyBindings						= mod:NewCastAnnounce(377488, 3) --Ледяные путы
local warnWakingBane						= mod:NewCastAnnounce(386546, 3) --Изгнание в сон
local warnShoulderSlam						= mod:NewCastAnnounce(391136, 2) --Удар плечом
--local warnBestialRoar						= mod:NewCastAnnounce(396991, 3) --Звериный рык
local warnSplinteringShards					= mod:NewTargetAnnounce(371007, 2) --Крошащиеся осколки
local warScornfulHaste						= mod:NewTargetNoFilterAnnounce(395492, 2)
local warnErraticGrowth						= mod:NewTargetNoFilterAnnounce(375596, 2, nil, nil, 118) --Беспорядочный рост (Превращение)
local warnArcaneBash						= mod:NewCastAnnounce(387067, 3) --Оглушение тайной магией
local warnMysticVapors						= mod:NewCastAnnounce(387564, 4) --Таинственные испарения
local warnSpellfrostBreath					= mod:NewTargetNoFilterAnnounce(391118, 4) --Дыхание магического льда
local warnWakingBane2						= mod:NewTargetNoFilterAnnounce(386549, 4) --Изгнание в сон

local specWarnPiercingShards				= mod:NewSpecialWarningDodge(370764, nil, nil, DBM_COMMON_L.FRONTAL, 2, 2) --Острые осколки (Фронталка)
local specWarnPiercingShards2				= mod:NewSpecialWarningYou(370764, nil, nil, DBM_COMMON_L.FRONTAL, 1, 2) --Острые осколки (Фронталка)
local specWarnBestialRoar					= mod:NewSpecialWarningDodge(396991, nil, nil, DBM_COMMON_L.AOEDAMAGE, 2, 4) --Звериный рык (АоЕ)
local specWarnSpellfrostBreath				= mod:NewSpecialWarningDefensive(391118, nil, nil, DBM_COMMON_L.FRONTAL, 3, 4) --Дыхание магического льда (Фронталка)
local specWarnSpellfrostBreath2				= mod:NewSpecialWarningDodge(391118, nil, nil, DBM_COMMON_L.FRONTAL, 2, 4) --Дыхание магического льда (Фронталка)
local specWarnUnstablePower					= mod:NewSpecialWarningDodge(374885, nil, nil, DBM_COMMON_L.BOMBING, 2, 2) --Изменчивая сила (Обстрел)
local specWarnForbiddenKnowledge			= mod:NewSpecialWarningDodge(371358, nil, nil, DBM_COMMON_L.BOMBING, 2, 2) --Запретное знание (Обстрел)
local specWarnNullStomp						= mod:NewSpecialWarningDodge(386526, false, nil, 2, 2, 2) --Нейтрализующий топот
local specWarnShoulderSlam					= mod:NewSpecialWarningYou(391136, nil, 100, nil, 1, 2) --Удар плечом (Рывок)
local specWarnCrystallineRupture			= mod:NewSpecialWarningDodge(370766, nil, nil, nil, 2, 2)
local specWarnWildEruption					= mod:NewSpecialWarningDodge(375652, nil, nil, nil, 2, 2)
local specWarnArcaneBash					= mod:NewSpecialWarningDodge(387067, nil, nil, nil, 2, 2) --Оглушение тайной магией
local specWarnSplinteringShards				= mod:NewSpecialWarningMoveAway(371007, nil, nil, nil, 4, 2) --Крошащиеся осколки
local specWarnErraticGrowth					= mod:NewSpecialWarningInterrupt(375596, "HasInterrupt", nil, nil, 1, 2) --Беспорядочный рост (Превращение)
local specWarnIcyBindings					= mod:NewSpecialWarningInterrupt(377488, "HasInterrupt", nil, nil, 1, 2) --Ледяные путы
local specWarnMysticVapors					= mod:NewSpecialWarningInterrupt(387564, "HasInterrupt", nil, nil, 1, 2) --Таинственные испарения
local specWarnWakingBane					= mod:NewSpecialWarningInterrupt(386546, "HasInterrupt", nil, nil, 1, 2) --Изгнание в сон
local specWarnHeavyTome						= mod:NewSpecialWarningInterrupt(389804, "HasInterrupt", nil, nil, 1, 2) --Тяжелый фолиант
local specWarnBrilliantScales				= mod:NewSpecialWarningDispel(374778, "MagicDispeller", nil, nil, 1, 2) --Сверкающая чешуя
local specWarnArcaneFury					= mod:NewSpecialWarningDispel(389686, "MagicDispeller", nil, nil, 3, 2) --Чародейское неистовство

local timerIcyBindingsCD					= mod:NewCDNPTimer(14, 377488, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON..DBM_COMMON_L.DEADLY_ICON) --Ледяные путы
local timerWakingBaneCD						= mod:NewCDNPTimer(18.2, 386546, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Изгнание в сон
local timerMysticVaporsCD					= mod:NewCDNPTimer(12.3, 387564, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON) --Таинственные испарения
local timerHeavyTomeCD						= mod:NewCDNPTimer(10.1, 389804, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Тяжелый фолиант
local timerErraticGrowthCD					= mod:NewCDNPTimer(21.5, 375596, 118, nil, nil, 3, nil, DBM_COMMON_L.MAGIC_ICON) --Беспорядочный рост (Превращение)
local timerShoulderSlamCD					= mod:NewCDNPTimer(10.9, 391136, 100, nil, nil, 3) --Удар плечом (Рывок)
local timerArcaneBashCD						= mod:NewCDNPTimer(17.5, 387067, nil, "Melee", nil, 5, nil, DBM_COMMON_L.TANK_ICON) --Оглушение тайной магией
local timerNullStompCD						= mod:NewCDNPTimer(8.1, 386526, nil, nil, nil, 3)
local timerPiercingShardsCD					= mod:NewCDNPTimer(15.4, 370764, nil, nil, 2, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerBestialRoarCD					= mod:NewCDNPTimer(17, 396991, nil, nil, nil, 2)
local timerUnstablePowerCD					= mod:NewCDNPTimer(7.3, 374885, DBM_COMMON_L.BOMBING, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Изменчивая сила (Обстрел)
local timerWildEruptionCD					= mod:NewCDNPTimer(12.1, 375652, nil, nil, nil, 3)

local yellSpellfrostBreath					= mod:NewYell(391118, DBM_COMMON_L.FRONTAL, nil, nil, "YELL") --Дыхание магического льда (Фронталка)
local yellSplinteringShards					= mod:NewYell(371007, nil, nil, nil, "YELL") --Крошащиеся осколки
local yellErraticGrowth						= mod:NewYell(375596, 118, nil, nil, "YELL") --Беспорядочный рост (Превращение)
local yellWakingBane						= mod:NewYell(386549, nil, nil, nil, "YELL") --Изгнание в сон
local yellShoulderSlam						= mod:NewYell(391136, 100, nil, nil, "YELL") --Удар плечом (Рывок)
local yellPiercingShards					= mod:NewYell(370764, DBM_COMMON_L.FRONTAL, nil, nil, "YELL") --Острые осколки (Фронталка)

mod:AddBoolOption("AGBook", true)

function mod:SpellfrostBreathTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnSpellfrostBreath:Show()
		specWarnSpellfrostBreath:Play("defensive")
		yellSpellfrostBreath:Yell()
	else
		specWarnSpellfrostBreath2:Show()
		specWarnSpellfrostBreath2:Play("watchstep")
		warnSpellfrostBreath:Show(targetname)
	end
end

function mod:ShoulderSlamTarget(targetname, uId)
	if not targetname then return end
	if self:AntiSpam(3, targetname) then
		if targetname == UnitName("player") then
			specWarnShoulderSlam:Show()
			specWarnShoulderSlam:Play("targetyou")
			yellShoulderSlam:Yell()
		end
	end
end

function mod:PiercingShardsTarget(targetname, uId)
	if not targetname then return end
	if self:AntiSpam(3, targetname) then
		if targetname == UnitName("player") then
			specWarnPiercingShards2:Show()
			specWarnPiercingShards2:Play("targetyou")
			yellPiercingShards:Yell()
		else
			specWarnPiercingShards:Show()
			specWarnPiercingShards:Play("watchstep")
		end
	end
end

--local playerName = UnitName("player")

--Antispam IDs for this mod: 1 run away, 2 dodge, 3 dispel, 4 incoming damage, 5 you/role, 6 misc

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if not self:IsValidWarning(args.sourceGUID) then return end
	if spellId == 391136 then
		if self:AntiSpam(3, 2) then
			warnShoulderSlam:Show()
		end
		self:BossTargetScanner(args.sourceGUID, "ShoulderSlamTarget", 0.1, 2)
	elseif spellId == 370764 then
		timerPiercingShardsCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(5, 4) then
			warnPiercingShards:Show()
		end
		self:BossTargetScanner(args.sourceGUID, "PiercingShardsTarget", 0.1, 2)
	elseif spellId == 396991 then
		timerBestialRoarCD:Start(nil, args.sourceGUID)
		if  self:AntiSpam(4, 3) then
			specWarnBestialRoar:Show()
			specWarnBestialRoar:Play("aesoon")
		end
	elseif spellId == 377105 and self:AntiSpam(3, 4) then
		warnIceCutter:Show()
	elseif spellId == 386526 then
		timerNullStompCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, 2) then
			if self.Options.SpecWarn386526dodge then
				specWarnNullStomp:Show()
				specWarnNullStomp:Play("watchstep")
			else
				warnNullStomp:Show()
			end
		end
	elseif spellId == 370766 and self:AntiSpam(3, 2) then
		specWarnCrystallineRupture:Show()
		specWarnCrystallineRupture:Play("watchstep")
	elseif spellId == 387564 then --Таинственные испарения
		timerMysticVaporsCD:Start(nil, args.sourceGUID)
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnMysticVapors:Show(args.sourceName)
			specWarnMysticVapors:Play("kickcast")
		elseif self:AntiSpam(3, 5) then
			warnMysticVapors:Show()
		end
	elseif spellId == 389804 then
		timerHeavyTomeCD:Start(nil, args.sourceGUID)
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnHeavyTome:Show(args.sourceName)
			specWarnHeavyTome:Play("kickcast")
		end
	elseif spellId == 386546 then
		timerWakingBaneCD:Start(nil, args.sourceGUID)
		if self.Options.SpecWarn386546interrupt and self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnWakingBane:Show(args.sourceName)
			specWarnWakingBane:Play("kickcast")
		elseif self:AntiSpam(3, 5) then
			warnWakingBane:Show()
		end
	elseif spellId == 377488 then
		timerIcyBindingsCD:Start(nil, args.sourceGUID)
		if self.Options.SpecWarn386546interrupt and self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnIcyBindings:Show(args.sourceName)
			specWarnIcyBindings:Play("kickcast")
		elseif self:AntiSpam(3, 5) then
			warnIcyBindings:Show()
		end
	elseif spellId == 387067 then
		timerArcaneBashCD:Start(nil, args.sourceGUID)
		if self:IsTanking("player", nil, nil, true, args.sourceGUID) and self:AntiSpam(2, 5) then
			specWarnArcaneBash:Show()
			specWarnArcaneBash:Play("shockwave")
		elseif self:AntiSpam(2, spellId) then
			warnArcaneBash:Show()
		end
	elseif spellId == 374885 then
		timerUnstablePowerCD:Start(nil, args.sourceGUID)
	elseif spellId == 375652 then
		timerWildEruptionCD:Start(nil, args.sourceGUID)
	elseif spellId == 391118 then --Дыхание магического льда
		self:BossTargetScanner(args.sourceGUID, "SpellfrostBreathTarget", 0.1, 2)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 374885 and self:AntiSpam(3, 2) then
		specWarnUnstablePower:Show()
		specWarnUnstablePower:Play("watchstep")
	elseif spellId == 371358 and self:AntiSpam(3, 2) then
		specWarnForbiddenKnowledge:Show()
		specWarnForbiddenKnowledge:Play("watchstep")
	elseif spellId == 375652 and self:AntiSpam(3, 2) then
		specWarnWildEruption:Show()
		specWarnWildEruption:Play("watchstep")
	elseif spellId == 375596 then
		timerErraticGrowthCD:Start(21.5, args.sourceGUID)
		if self:CheckInterruptFilter(args.sourceGUID, false, true) and self:AntiSpam(2, spellId) then
			specWarnErraticGrowth:Show(args.sourceName)
			specWarnErraticGrowth:Play("kickcast")
		end
	elseif spellId == 391136 then
		timerShoulderSlamCD:Start(8.9, args.sourceGUID)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 371007 then
		warnSplinteringShards:CombinedShow(0.5, args.destName)
		if args:IsPlayer() then
			specWarnSplinteringShards:Show()
			specWarnSplinteringShards:Play("runout")
			yellSplinteringShards:Yell()
		end
	elseif spellId == 395492 then --Скорость насмешника
		warScornfulHaste:CombinedShow(0.3, args.destName)
	elseif spellId == 375596 then --Беспорядочный рост
		if args:IsPlayer() then
			yellErraticGrowth:Yell()
		else
			warnErraticGrowth:CombinedShow(0.3, args.destName)
		end
	elseif spellId == 374778 and not args:IsDestTypePlayer() and self:AntiSpam(3, 3) then --Сверкающая чешуя
		specWarnBrilliantScales:Show(args.destName)
		specWarnBrilliantScales:Play("helpdispel")
	elseif spellId == 389686 and not args:IsDestTypePlayer() and self:AntiSpam(7, 3) then
		specWarnArcaneFury:Show(DBM_COMMON_L.ADDS)
		specWarnArcaneFury:Play("helpdispel")
	elseif spellId == 386549 then --Изгнание в сон
		if args:IsPlayer() then
			yellWakingBane:Yell()
		else
			warnWakingBane2:CombinedShow(0.7, args.destName)
		end
	end
end
--mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

--[[
function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 339525 and args:IsPlayer() then

	end
end
--]]

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 186740 then--Arcane Construct
		timerArcaneBashCD:Stop(args.destGUID)
	elseif cid == 187240 then--Drakonid Breaker
		timerShoulderSlamCD:Stop(args.destGUID)
		timerBestialRoarCD:Stop(args.destGUID)
	elseif cid == 186741 then--Drakonid Breaker
		timerWakingBaneCD:Stop(args.destGUID)
	elseif cid == 196115 or cid == 191164 then--Arcane Tender (one by entrance is diff id than ones before boss)
		timerErraticGrowthCD:Stop(args.destGUID)
		timerWildEruptionCD:Stop(args.destGUID)
	elseif cid == 187155 then--Rune Seal Keeper
		timerIcyBindingsCD:Stop(args.destGUID)
	elseif cid == 196102 then--Murchal Ochk Shlyaper
		timerMysticVaporsCD:Stop(args.destGUID)
	elseif cid == 187154 then--Unstable Curator
		timerHeavyTomeCD:Stop(args.destGUID)
	elseif cid == 187246 then--The frogs (too lazy to look up mob name)
		timerNullStompCD:Stop(args.destGUID)
	elseif cid == 196116 then--Another mob name I didn't look up
		timerPiercingShardsCD:Stop(args.destGUID)
	elseif cid == 187160 then
		timerPiercingShardsCD:Stop(args.destGUID)
	elseif cid == 189555 then--Yet another i didn't look up
		timerUnstablePowerCD:Stop(args.destGUID)
	end
end

function mod:GOSSIP_SHOW()
	local gossipOptionID = self:GetGossipID()
	if gossipOptionID then
		if self.Options.AGBook and (gossipOptionID == 56056 or gossipOptionID == 56057 or gossipOptionID == 56247 or gossipOptionID == 56379 or gossipOptionID == 56248 or gossipOptionID == 56378 or gossipOptionID == 56250 or gossipOptionID == 107756 or gossipOptionID == 56251) then -- Books
			self:SelectGossip(gossipOptionID)
		end
	end
end
