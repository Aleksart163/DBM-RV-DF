local mod	= DBM:NewMod(2472, "DBM-Party-Dragonflight", 1, 1196)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260630000000")
mod:SetCreatureID(186116)--194745 for Rotfang Hyena
mod:SetEncounterID(2567)
mod:SetHotfixNoticeRev(20260714000000)
--mod:SetMinSyncRevision(20260714000000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 384416 384827 385435 384633 384353",
	"SPELL_CAST_SUCCESS 383979",
	"SPELL_AURA_APPLIED 385356 384425 384764 384725 384638 384148 387889",
	"SPELL_AURA_REMOVED 384725 384638 387889 384148"
)

--TODO, worth target scanning Meat Toss?
--TODO, CD feeding frenzy if it's shared cd
--TODO, does bounding leap have some kind of detection of target?
--TODO, is masters call actually interrupted or an invalid journal icon flag?
--TODO, verify some cast spellids which were iffy tooltip wise. This fight was still work in progress in build mod was made in
--[[
(ability.id = 384416 or ability.id = 384827 or ability.id = 385435 or ability.id = 384633 or ability.id = 384353) and type = "begincast"
 or ability.id = 383979 and type = "cast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
local warnEnsnaringTrap							= mod:NewTargetNoFilterAnnounce(384148, 3) --Оплетающая ловушка
local warnSmellLikeMeat							= mod:NewTargetNoFilterAnnounce(384425, 3, nil, nil, 62374) --Пахнет мясом (Преследование)
local warnCallHyenas							= mod:NewSpellAnnounce(384827, 2) --Призыв гиен

local specWarnEnsnaringTrap						= mod:NewSpecialWarningMoveAway(384148, nil, nil, nil, 1, 2) --Оплетающая ловушка
local specWarnFeedingFrenzy						= mod:NewSpecialWarningDispel(384764, "RemoveEnrage", nil, nil, 1, 2) --Бешеный аппетит Buff on mob
local specWarnFeedingFrenzyYou					= mod:NewSpecialWarningRun(384725, nil, 96306, nil, 4, 2) --Бешеный аппетит (Преследование) Debuff on player
local specWarnMastersCall						= mod:NewSpecialWarningInterrupt(384638, "HasInterrupt", nil, nil, 1, 2) --Приказ хозяина
local specWarnGutShot							= mod:NewSpecialWarningDefensive(384343, nil, nil, nil, 3, 2) --Выстрел в живот

--mod:AddTimerLine(DBM:EJ_GetSectionInfo(24883))
local timerEnsnaringTrapCD						= mod:NewCDTimer(17, 384148, nil, nil, nil, 3) --Оплетающая ловушка
local timerMeatTossCD							= mod:NewCDTimer(21.8, 384416, nil, nil, nil, 3) --Бросок мяса
local timerCallHyenasCD							= mod:NewCDTimer(31.6, 384827, nil, nil, nil, 1, nil, DBM_COMMON_L.DAMAGE_ICON) --Призыв гиен
--local timerMastersCallCD						= mod:NewCDTimer(35, 384638, nil, nil, nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON)--Doesn't seem to have an actual CD?
local timerGutShotCD							= mod:NewCDTimer(16.7, 384343, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON) --Выстрел в живот

local yellEnsnaringTrap							= mod:NewYell(384148, nil, nil, nil, "YELL") --Оплетающая ловушка

mod:AddRangeFrameOption(4, 384558)
mod:AddNamePlateOption("NPAuraOnFixate", 384725)
mod:AddNamePlateOption("NPAuraOnMastersCall", 384638)
mod:AddNamePlateOption("NPAuraOnEnsnaringTrap", 384148)
mod:AddNamePlateOption("NPAuraOnHunterleadersTactics", 387889)

--mod:GroupSpells(384764, 384725)--Group the two frenzy IDs

function mod:OnCombatStart(delay)
	timerEnsnaringTrapCD:Start(8-delay) --
	timerGutShotCD:Start(14.8-delay) --
	timerMeatTossCD:Start(13-delay) --
	timerCallHyenasCD:Start(30-delay) --
--	timerMastersCallCD:Start(37-delay)--Not timer based?
	if self.Options.NPAuraOnFixate or self.Options.NPAuraOnMastersCall or self.Options.NPAuraOnEnsnaringTrap or self.Options.NPAuraOnHunterleadersTactics then
		DBM:FireEvent("BossMod_EnableHostileNameplates")
	end
	if self.Options.RangeFrame then
		DBM.RangeCheck:Show(4)
	end
	--20 12 46 139 пул босса
	--20 12 54 154 ловушка 1
	--20 12 59 459 бросок мяса 1
	--20 13 02 557 выстрел 1
	--20 13 13 169 ловушка 2
	--20 13 16 174 призыв гиен 1
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
	if self.Options.NPAuraOnFixate or self.Options.NPAuraOnMastersCall or self.Options.NPAuraOnEnsnaringTrap or self.Options.NPAuraOnHunterleadersTactics then
		DBM.Nameplate:Hide(true, nil, nil, nil, true, true)
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 384416 then
		timerMeatTossCD:Start()
	elseif spellId == 384827 or spellId == 385435 then
		warnCallHyenas:Show()
		timerCallHyenasCD:Start()
	elseif spellId == 384633 then
--		timerMastersCallCD:Start()
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnMastersCall:Show(args.sourceName)
			specWarnMastersCall:Play("kickcast")
		end
	elseif spellId == 384353 then
		if self:IsTanking("player", "boss1", nil, true) then
			specWarnGutShot:Show()
			specWarnGutShot:Play("carefly")
		end
		timerGutShotCD:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 383979 then
		timerEnsnaringTrapCD:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 385356 then
		warnEnsnaringTrap:CombinedShow(0.3, args.destName)
		if args:IsPlayer() then
			specWarnEnsnaringTrap:Show()
			specWarnEnsnaringTrap:Play("scatter")
			yellEnsnaringTrap:Yell()
		end
	elseif spellId == 384425 then
		warnSmellLikeMeat:Show(args.destName)
	elseif spellId == 384764 and self:AntiSpam(3, 1) then
		specWarnFeedingFrenzy:Show(args.destName)
		specWarnFeedingFrenzy:Play("enrage")
	elseif spellId == 384725 and args:IsPlayer() then
		if self:AntiSpam(3, 2) then
			specWarnFeedingFrenzyYou:Show()
			specWarnFeedingFrenzyYou:Play("justrun")
		end
		if self.Options.NPAuraOnFixate then
			DBM.Nameplate:Show(true, args.sourceGUID, spellId, nil, 10)
		end
	elseif spellId == 384638 then
		if self.Options.NPAuraOnMastersCall then
			DBM.Nameplate:Show(true, args.destGUID, spellId, nil, 5)
		end
	elseif spellId == 384148 then
		if args:IsDestTypeHostile() then--Nameplates used to show them being used on adds
			if self.Options.NPAuraOnEnsnaringTrap then
				DBM.Nameplate:Show(true, args.destGUID, spellId, nil, 6)
			end
		else--Alerts are shown for players fucking them up

		end
	elseif spellId == 387889 then
		if self.Options.NPAuraOnHunterleadersTactics then
			DBM.Nameplate:Show(true, args.destGUID, spellId)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 384725 and args:IsPlayer() then
		if self.Options.NPAuraOnFixate then
			DBM.Nameplate:Hide(true, args.sourceGUID, spellId)
		end
	elseif spellId == 384638 then
		if self.Options.NPAuraOnMastersCall then
			DBM.Nameplate:Hide(true, args.destGUID, spellId)
		end
	elseif spellId == 384148 and args:IsDestTypeHostile() then
		if self.Options.NPAuraOnEnsnaringTrap then
			DBM.Nameplate:Hide(true, args.destGUID, spellId)
		end
	elseif spellId == 387889 then
		if self.Options.NPAuraOnHunterleadersTactics then
			DBM.Nameplate:Hide(true, args.destGUID, spellId)
		end
	end
end
