local mod	= DBM:NewMod(2473, "DBM-Party-Dragonflight", 1, 1196)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260630000000")
mod:SetCreatureID(186120)
mod:SetEncounterID(2568)
mod:SetUsedIcons(8, 7, 6, 5)
mod:SetHotfixNoticeRev(20260714000000)
--mod:SetMinSyncRevision(20260714000000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 376811 381770 377559 376934",
	"SPELL_CAST_SUCCESS 376811",
	"SPELL_SUMMON 376797",
	"SPELL_AURA_APPLIED 377222 378022 390968 383875",--377864
	"SPELL_AURA_REMOVED 377222 378022",
	"SPELL_PERIODIC_DAMAGE 378054",
	"SPELL_PERIODIC_MISSED 378054"
)

--TODO, proper phasing and timer updates
--TODO, better stack alert handling, maybe dispel special warning for RemoveDisease?
--[[
(ability.id = 376811 or ability.id = 377559 or ability.id = 376934) and type = "begincast"
 or ability.id = 377859 and type = "cast"
 or ability.id = 378022 and (type = "removebuff" or type = "applybuff")
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
 or ability.id = 381770 and type = "begincast"
--]]
local warnConsume								= mod:NewTargetNoFilterAnnounce(377222, 4) --Поглощение
local warnDecaySpray							= mod:NewSpellAnnounce(376811, 2) --Разлагающие брызги
--local warnInfectiousSpit						= mod:NewStackAnnounce(377864, 2, nil, "Healer|RemoveDisease")

local specWarnPartiallyDigested					= mod:NewSpecialWarningYou(383875, nil, nil, nil, 3, 8) --Частичное переваривание
local specWarnStarvingFrenzy					= mod:NewSpecialWarningSpell(390968, nil, 156861, nil, 3, 4) --Иссушающее бешенство (Бешенство)
local specWarnDecaySpray						= mod:NewSpecialWarningDodge(376811, nil, nil, nil, 2, 2) --Разлагающие брызги
local specWarnDecaySpray2						= mod:NewSpecialWarningSwitch(376811, "-Healer", nil, DBM_COMMON_L.ADDS, 1, 4) --Разлагающие брызги (Адды)
local specWarnGraspingVines						= mod:NewSpecialWarningRun(376933, nil, nil, DBM_COMMON_L.ATTRACTION, 4, 4) --Хваткие лозы (Притягивание)
local specWarnGraspingVines2					= mod:NewSpecialWarningMoveTo(376933, "Tank", nil, DBM_COMMON_L.ATTRACTION, 3, 4) --Хваткие лозы (Притягивание)
local specWarnGraspingVines3					= mod:NewSpecialWarningDefensive(376933, "Tank", 181295, nil, 3, 4) --Хваткие лозы (Переваривание)
local specWarnGushingOoze						= mod:NewSpecialWarningInterrupt(381770, "HasInterrupt", nil, nil, 1, 2) --Хлещущая слизь
local specWarnVineWhip							= mod:NewSpecialWarningDefensive(377559, nil, nil, DBM_COMMON_L.FRONTAL, 3, 4) --Хлещущая лоза
local specWarnVineWhip2							= mod:NewSpecialWarningDodge(377559, nil, nil, DBM_COMMON_L.FRONTAL, 2, 2) --Хлещущая лоза
local specWarnGTFO								= mod:NewSpecialWarningGTFO(378054, nil, nil, nil, 1, 8) --Увядание!

local timerGraspingVinesCD						= mod:NewCDTimer(54, 376933, DBM_COMMON_L.ATTRACTION, nil, nil, 6, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Хваткие лозы (Притягивание)
local timerGraspingVinesCast					= mod:NewCastTimer(9, 376933, DBM_COMMON_L.ATTRACTION, nil, nil, 7, nil, nil, nil, 1, 5)
local timerConsume								= mod:NewTargetTimer(10, 377222, nil, nil, nil, 3, nil, DBM_COMMON_L.DAMAGE_ICON) --Поглощение
local timerDecaySprayCD							= mod:NewCDTimer(40, 376811, DBM_COMMON_L.ADDS, nil, nil, 1, nil, DBM_COMMON_L.DAMAGE_ICON) --Разлагающие брызги
--local timerInfectiousSpitCD					= mod:NewCDTimer(20.1, 377864, nil, nil, nil, 3, nil, DBM_COMMON_L.DISEASE_ICON)
local timerVineWhipCD							= mod:NewCDTimer(16, 377559, DBM_COMMON_L.FRONTAL, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON) --Хлещущая лоза (Фронталка)

local yellVineWhip								= mod:NewYell(377559, DBM_COMMON_L.FRONTAL, nil, nil, "YELL") --Хлещущая лоза (Фронталка)
--local yellInfusedStrikes						= mod:NewShortFadesYell(361966)

mod:AddInfoFrameOption(378022, true)
mod:AddSetIconOption("SetIconOnDecaySpray", 376811, true, 5, {8, 7, 6, 5})

--mod:GroupSpells(377222, 378022)--Consume with Consuming

local partiallyDigested = DBM:GetSpellName(383875) --Частичное переваривание
mod.vb.addIcon = 8
mod.vb.graspingVinesCount = 0

function mod:OnCombatStart(delay)
	self.vb.graspingVinesCount = 0
	timerVineWhipCD:Start(6-delay) --
	timerDecaySprayCD:Start(12-delay) --
	timerGraspingVinesCD:Start(23.5-delay) --
--	timerInfectiousSpitCD:Start(25.9-delay)--Restarted by vines anyways
end

function mod:OnCombatEnd()
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 376811 then --Разлагающие брызги
		self.vb.addIcon = 8
		specWarnDecaySpray:Show()
		specWarnDecaySpray:Play("watchstep")
		timerDecaySprayCD:Start(22.5) --
	elseif spellId == 381770 and self:CheckInterruptFilter(args.sourceGUID, false, true) then
		specWarnGushingOoze:Show(args.sourceName)
		specWarnGushingOoze:Play("kickcast")
	elseif spellId == 377559 then --Хлещущая лоза (Фронталка)
		self.vb.graspingVinesCount = self.vb.graspingVinesCount + 1
		if self:IsTanking("player", "boss1", nil, true) then
			specWarnVineWhip:Show()
			specWarnVineWhip:Play("defensive")
			yellVineWhip:Yell()
		else
			specWarnVineWhip2:Show()
			specWarnVineWhip2:Play("watchstep")
		end
		if self.vb.graspingVinesCount <= 2 then
			timerVineWhipCD:Start()--16-24 now thanks to worse spell queue than before
		else
			timerVineWhipCD:Start(21.9)
		end
	elseif spellId == 376934 then --Хваткие лозы (Притягивание)
		self.vb.graspingVinesCount = 0
		if self:IsMythic() then
			if self:IsTank() and not DBM:UnitDebuff("player", partiallyDigested) then
				specWarnGraspingVines2:Show(DBM_COMMON_L.BOSS)
				specWarnGraspingVines2:Play("movetoboss")
				specWarnGraspingVines3:Schedule(3.5)
				specWarnGraspingVines3:ScheduleVoice(3.5, "defensive")
			else
				specWarnGraspingVines:Show()
				specWarnGraspingVines:Play("justrun")
			end
		else
			specWarnGraspingVines:Show()
			specWarnGraspingVines:Play("justrun")
		end
		timerVineWhipCD:Stop()
		timerDecaySprayCD:Stop()
		timerGraspingVinesCD:Start()
		timerGraspingVinesCast:Start() --Точно под миф
		--Timer restarts
--		timerInfectiousSpitCD:Start(10.2)--No longer exists at all?
--		timerDecaySprayCD:Start(33.2)--No longer restarts here
	elseif spellId == 383875 then --Частичное переваривание
		if args:IsPlayer() then
			specWarnPartiallyDigested:Show()
			specWarnPartiallyDigested:Play("targetyou")
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 376811 then
		specWarnDecaySpray2:Schedule(2)
		specWarnDecaySpray2:ScheduleVoice(2, "changetarget")
	end
end

function mod:SPELL_SUMMON(args)
	local spellId = args.spellId
	if spellId == 376797 then
		if self.Options.SetIconOnDecaySpray then
			self:ScanForMobs(args.destGUID, 2, self.vb.addIcon, 1, nil, 12, "SetIconOnDecaySpray")
		end
		self.vb.addIcon = self.vb.addIcon - 1
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 377222 then--On Player
		warnConsume:CombinedShow(0.3, args.destName)
		timerConsume:Start(args.destName)
	elseif spellId == 378022 then--On Boss
		if self.Options.InfoFrame then
			DBM.InfoFrame:SetHeader(args.spellName)
			DBM.InfoFrame:Show(2, "enemyabsorb", nil, args.amount, "boss1")
		end
	elseif spellId == 390968 then --Иссушающее бешенство
		specWarnStarvingFrenzy:Show()
		specWarnStarvingFrenzy:Play("enrage")
--	elseif spellId == 377864 then
--		local amount = args.amount or 1
--		if amount % 2 == 0 then
--			warnInfectiousSpit:Show(args.destName, amount)
--		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 377222 then
		timerConsume:Stop(args.destName)
		timerDecaySprayCD:Start(7.5)
	elseif spellId == 378022 then--On Boss
		if self.Options.InfoFrame then
			DBM.InfoFrame:Hide()
		end
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 378054 and destGUID == UnitGUID("player") and self:AntiSpam(2, 2) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
