local mod	= DBM:NewMod("DHTTrash", "DBM-Party-Legion", 2)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260630000000")
--mod:SetModelID(47785)
mod:SetZone(1466)

mod.isTrashMod = true
mod.isTrashModBossFightAllowed = true

mod:RegisterEvents(
	"SPELL_CAST_START 200630 200580 200642 200658 200768 198904 201226 201399 201839 225562",
	"SPELL_CAST_SUCCESS 218755 204243 201272 201129 201361 201399",
	"SPELL_SUMMON 198910",
	"SPELL_AURA_APPLIED 225484 198904 204246 201839 201365 200684 200642",
	"SPELL_AURA_APPLIED_DOSE 200642",
	"SPELL_AURA_REMOVED 201839 200684",
	"SPELL_PERIODIC_DAMAGE 198408 200822",
	"SPELL_PERIODIC_MISSED 198408 200822",
	"UNIT_DIED",
	"CHAT_MSG_MONSTER_YELL"
)

--[[
(ability.id = 225562 or ability.id = 200630 or ability.id = 200580 or ability.id = 200642 or ability.id = 200658 or ability.id = 200768 or ability.id = 198904 or ability.id = 201226 or ability.id = 201399 or ability.id = 201839) and type = "begincast"
 or (ability.id = 218755 or ability.id = 204243 or ability.id = 201272 or ability.id = 201129 or ability.id = 201361) and type = "cast"
 or ability.id = 198910
 or ability.id = 225484 and type = "applydebuff"
--]]
--TODO, Grievous Rip is lacking a cast event, probably needs UNIT_SPELLCAST
local warnNightmareToxin			= mod:NewTargetNoFilterAnnounce(200684, 4) --Ядовитый кошмар
local warnSpewCorruption			= mod:NewSpellAnnounce(218755, 2) --Выброс порчи + треш
local warnMaddeningRoar				= mod:NewSpellAnnounce(200580, 3) --Безумный рев (АоЕ)
local warnStarShower				= mod:NewCastAnnounce(200658, 3) --Звездный дождь
local warnBloodBomb					= mod:NewSpellAnnounce(201272, 4) --Кровавая бомба
local warnGrievousRip				= mod:NewTargetNoFilterAnnounce(225484, 4, nil, false) --Мучительный разрыв Packs of 3 exist taht cast it near at once but staggered, so can feel spammy but too spread to aggregate
local warnUnnervingScreech			= mod:NewCastAnnounce(200630, 4) --Ошеломляющий визг High prio off internet
local warnTormentingEye				= mod:NewCastAnnounce(204243, 4, 4.5) --Истязающий глаз High prio off internet
local warnBloodMeta					= mod:NewCastAnnounce(225562, 4) --Кровавая метаморфоза High prio off internet
local warnDreadInferno				= mod:NewCastAnnounce(201399, 4) --Жуткое пекло High prio off internet

local specWarnDespair2				= mod:NewSpecialWarningStack(200642, nil, 4, nil, nil, 1, 2) --Отчаяние
local specWarnRottingEarth			= mod:NewSpecialWarningMove(200822, nil, nil, nil, 1, 2) --Гниющая земля
local specWarnNightfall				= mod:NewSpecialWarningMove(198408, nil, nil, nil, 1, 2) --Сумерки
local specWarnNightmareToxin		= mod:NewSpecialWarningMoveAway(200684, nil, nil, nil, 3, 4) --Ядовитый кошмар
local specWarnMaddeningRoar			= mod:NewSpecialWarningDefensive(200580, nil, nil, nil, 3, 4) --Безумный рев (АоЕ)
local specWarnCurseofIsolation2		= mod:NewSpecialWarningMoveAway(201839, nil, nil, nil, 4, 2) --Проклятие уединения
local specWarnPropellingCharge		= mod:NewSpecialWarningDodge(200768, nil, nil, nil, 2, 2) --Рывок вперед
local specWarnRootBurst				= mod:NewSpecialWarningDodge(201129, nil, nil, nil, 2, 2) --Рост корней
local specWarnVileMushroom			= mod:NewSpecialWarningDodge(198910, nil, nil, nil, 2, 2) --Злогриб
local specWarnDreadInfernoFailed	= mod:NewSpecialWarningMoveAway(201399, nil, nil, nil, 1, 2) --Жуткое пекло
local specWarnBloodAssault			= mod:NewSpecialWarningDefensive(201226, nil, nil, nil, 3, 2) --Кровавая атака (Отталкивание)
local specWarnStarShower			= mod:NewSpecialWarningInterrupt(200658, "HasInterrupt", nil, nil, 1, 2) --Звездный дождь
local specWarnUnnervingScreech		= mod:NewSpecialWarningInterrupt(200630, "HasInterrupt", nil, nil, 1, 2) --Ошеломляющий визг High Priority
local specWarnDespair				= mod:NewSpecialWarningInterrupt(200642, "HasInterrupt", nil, nil, 1, 2) --Отчаяние
local specWarnTormentingEye			= mod:NewSpecialWarningInterrupt(204243, "HasInterrupt", nil, nil, 1, 2) --Истязающий глаз High Priority
local specWarnBloodMeta				= mod:NewSpecialWarningInterrupt(225562, "HasInterrupt", nil, nil, 1, 2) --Кровавая метаморфоза High Priority
local specWarnDreadInferno			= mod:NewSpecialWarningInterrupt(201399, "HasInterrupt", nil, nil, 1, 2) --Жуткое пекло High Priority
local specWarnCurseofIsolation		= mod:NewSpecialWarningInterrupt(201839, "HasInterrupt", nil, nil, 1, 2) --Проклятие уединения
local specWarnPoisonSpear			= mod:NewSpecialWarningDispel(198904, "RemovePoison", nil, nil, 1, 2) --Отравленное копье
local specWarnTormentingFear		= mod:NewSpecialWarningDispel(204246, "RemoveMagic", nil, nil, 1, 2) --Истязающий страх Missed eye interrupt
local specWarnCurseofIsoDispel		= mod:NewSpecialWarningDispel(201839, "RemoveCurse", nil, nil, 1, 2) --Проклятие уединения Missed Taintheart interrupt
local specWarnDarksoulDrain			= mod:NewSpecialWarningDispel(201365, "RemoveDisease", nil, nil, 1, 2) --Опустошение темного духа

--local specWarnGTFO					= mod:NewSpecialWarningGTFO(201123, nil, nil, nil, 1, 8)

local timerRP						= mod:NewRPTimer(68)
local timerGrievousRipCD			= mod:NewCDNPTimer(18, 225484, nil, nil, nil, 3) --Мучительный разрыв Kind of imprecise without an actual cast event, but should be a good approx
local timerUnnervingScreechCD		= mod:NewCDNPTimer(10.4, 200630, nil, nil, nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Ошеломляющий визг
local timerSpewCorruptionCD			= mod:NewCDNPTimer(30.3, 218755, nil, nil, nil, 3) --Выброс порчи + треш
local timerMaddeningRoarCD			= mod:NewCDNPTimer(22.6, 200580, nil, nil, nil, 2) --Безумный рев (АоЕ)
local timerStarShowerCD				= mod:NewCDNPTimer(20.7, 200658, nil, nil, nil, 2) --Звездный дождь
local timerPropellingChargeCD		= mod:NewCDNPTimer(18.2, 200768, nil, nil, nil, 3) --Рывок вперед
local timerPoisonSpearCD			= mod:NewCDNPTimer(18.2, 198904, nil, nil, nil, 3) --Отравленное копье 18.2-22
local timerTormentingEyeCD			= mod:NewCDNPTimer(5.2, 204243, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Истязающий глаз
local timerBloodBombCD				= mod:NewCDNPTimer(15.7, 201272, nil, nil, nil, 2) --Кровавая бомба
local timerBloodAssaultCD			= mod:NewCDNPTimer(22.6, 201226, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON) --Кровавая атака (Отталкивание)
local timerBloodMetaCD				= mod:NewCDNPTimer(10.9, 225562, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Кровавая метаморфоза
local timerDreadInfernoCD			= mod:NewCDNPTimer(15.8, 201399, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Жуткое пекло
local timerCurseofIsolationCD		= mod:NewCDNPTimer(15.8, 201839, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Проклятие уединения
local timerRootBurstCD				= mod:NewCDNPTimer(16.2, 201129, nil, nil, nil, 3) --Рост корней
local timerVileMushroomCD			= mod:NewCDNPTimer(17, 198910, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Злогриб
local timerDarksoulBiteCD			= mod:NewCDNPTimer(12.1, 201361, nil, nil, nil, 5) --Укус темного духа 12.1-18.2

local yellNightmareToxin			= mod:NewYell(200684, nil, nil, nil, "YELL") --Ядовитый кошмар
local yellNightmareToxin2			= mod:NewShortFadesYell(200684, nil, nil, nil, "YELL") --Ядовитый кошмар
local yellCurseofIsolation			= mod:NewYell(201839, nil, nil, nil, "YELL") --Проклятие уединения
local yellCurseofIsolation2			= mod:NewShortFadesYell(201839, nil, nil, nil, "YELL") --Проклятие уединения
local yellDreadInferno				= mod:NewYell(201399, nil, nil, nil, "YELL") --Жуткое пекло

mod.vb.trashRemaining = 5

--Antispam IDs for this mod: 1 run away, 2 dodge, 3 dispel, 4 incoming damage, 5 you/role, 6 misc, 7 off interrupt, 8 GTFO

function mod:ResetSecondBossRP()
	self.vb.trashRemaining = 5
end

function mod:SPELL_CAST_START(args)
	if not self.Options.Enabled then return end
	if not self:IsValidWarning(args.sourceGUID) then return end
	local spellId = args.spellId
	if spellId == 200630 then
		timerUnnervingScreechCD:Start(nil, args.sourceGUID)
		if self.Options.SpecWarn200630interrupt and self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnUnnervingScreech:Show(args.sourceName)
			specWarnUnnervingScreech:Play("kickcast")
		elseif self:AntiSpam(3, 7) then
			warnUnnervingScreech:Show()
		end
	elseif spellId == 225562 then
		timerBloodMetaCD:Start(nil, args.sourceGUID)
		if self.Options.SpecWarn225562interrupt and self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnBloodMeta:Show(args.sourceName)
			specWarnBloodMeta:Play("kickcast")
		elseif self:AntiSpam(3, 7) then
			warnBloodMeta:Show()
		end
	elseif spellId == 201399 then
		timerDreadInfernoCD:Start(nil, args.sourceGUID)
		if self.Options.SpecWarn201399interrupt and self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnDreadInferno:Show(args.sourceName)
			specWarnDreadInferno:Play("kickcast")
		elseif self:AntiSpam(3, 7) then
			warnDreadInferno:Show()
		end
	elseif spellId == 200580 then --Безумный рев
		timerMaddeningRoarCD:Start(nil, args.sourceGUID)
		local _, _, _, _, _, expireTime = DBM:UnitDebuff("player", spellId)
		local remaining
		if expireTime then
			remaining = expireTime-GetTime()
		end
		if not UnitIsDeadOrGhost("player") and (remaining and remaining < 5) then
			specWarnMaddeningRoar:Show()
			specWarnMaddeningRoar:Play("defensive")
		elseif self:AntiSpam(3, 4) then
			warnMaddeningRoar:Show()
		end
	elseif spellId == 200642 then
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnDespair:Show(args.sourceName)
			specWarnDespair:Play("kickcast")
		end
	elseif spellId == 200658 then
		timerStarShowerCD:Start(nil, args.sourceGUID)
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnStarShower:Show(args.sourceName)
			specWarnStarShower:Play("kickcast")
		elseif self:AntiSpam(3, 4) then
			warnStarShower:Show()
		end
	elseif spellId == 200768 then
		timerPropellingChargeCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, 2) then
			specWarnPropellingCharge:Show()
			specWarnPropellingCharge:Play("chargemove")
		end
	elseif spellId == 198904 then
		timerPoisonSpearCD:Start(nil, args.sourceGUID)
	elseif spellId == 201226 then
		timerBloodAssaultCD:Start(nil, args.sourceGUID)
		if self:IsTanking("player", nil, nil, true, args.sourceGUID) and self:AntiSpam(3, 5) then
			specWarnBloodAssault:Show()
			specWarnBloodAssault:Play("carefly")
		end
	elseif spellId == 201839 then
		timerCurseofIsolationCD:Start(nil, args.sourceGUID)
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnCurseofIsolation:Show(args.sourceName)
			specWarnCurseofIsolation:Play("kickcast")
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 218755 then
		timerSpewCorruptionCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, 6) then
			warnSpewCorruption:Show()
		end
	elseif spellId == 204243 then
		timerTormentingEyeCD:Start(nil, args.sourceGUID)
		if self.Options.SpecWarn204243interrupt and self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnTormentingEye:Show(args.sourceName)
			specWarnTormentingEye:Play("kickcast")
		elseif self:AntiSpam(3, 7) then
			warnTormentingEye:Show()
		end
	elseif spellId == 201272 then
		timerBloodBombCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, 4) then
			warnBloodBomb:Show()
		end
	elseif spellId == 201399 and args:IsPlayer() then
		specWarnDreadInfernoFailed:Show()
		specWarnDreadInfernoFailed:Play("runout")
		yellDreadInferno:Yell()
	elseif spellId == 201129 then
		timerRootBurstCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, 2) then
			specWarnRootBurst:Show()
			specWarnRootBurst:Play("watchstep")
		end
	elseif spellId == 201361 then
		timerDarksoulBiteCD:Start(nil, args.sourceGUID)
	end
end

function mod:SPELL_SUMMON(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 198910 then
		timerVileMushroomCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, 2) then
			specWarnVileMushroom:Show()
			specWarnVileMushroom:Play("watchstep")
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 225484 then
		warnGrievousRip:Show(args.destName)
		if self:AntiSpam(8, args.sourceGUID) then
			timerGrievousRipCD:Start(nil, args.sourceGUID)
		end
	elseif spellId == 198904 then
		if self:CheckDispelFilter("poison") and self:AntiSpam(3, 3) then
			specWarnPoisonSpear:Show(args.destName)
			specWarnPoisonSpear:Play("helpdispel")
		end
	elseif spellId == 204246 then
		if self:CheckDispelFilter("magic") and self:AntiSpam(3, 3) then
			specWarnTormentingFear:Show(args.destName)
			specWarnTormentingFear:Play("helpdispel")
		end
	elseif spellId == 201839 then
		if args:IsPlayer() then
			specWarnCurseofIsolation2:Show()
			specWarnCurseofIsolation2:Play("runout")
			yellCurseofIsolation:Yell()
			yellCurseofIsolation2:Countdown(spellId)
		elseif self:CheckDispelFilter("curse") and self:AntiSpam(2, "CurseofIsolation") then
			specWarnCurseofIsoDispel:Schedule(2, args.destName)
			specWarnCurseofIsoDispel:ScheduleVoice(2, "helpdispel")
		end
	elseif spellId == 201365 then
		if self:CheckDispelFilter("disease") and self:AntiSpam(3, 3) then
			specWarnDarksoulDrain:Show(args.destName)
			specWarnDarksoulDrain:Play("helpdispel")
		end
	elseif spellId == 200684 then
		if args:IsPlayer() then
			specWarnNightmareToxin:Show()
			specWarnNightmareToxin:Play("runout")
			yellNightmareToxin:Yell()
			yellNightmareToxin2:Countdown(spellId)
		else
			warnNightmareToxin:CombinedShow(0.5, args.destName)
		end
	elseif spellId == 200642 then --Отчаяние
		local amount = args.amount or 1
		if args:IsPlayer() and amount >= 4 and amount % 2 == 0 then
			specWarnDespair2:Show(amount)
			specWarnDespair2:Play("stackhigh")
		end
--	elseif spellId == 201123 and args:IsPlayer() and self:AntiSpam(3, 8) then
--		specWarnGTFO:Show(args.spellName)
--		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 201839 then
		if args:IsPlayer() then
			yellCurseofIsolation2:Cancel()
		end
	elseif spellId == 200684 then
		if args:IsPlayer() then
			yellNightmareToxin2:Cancel()
		end
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId)
	if spellId == 200822 and destGUID == UnitGUID("player") and self:AntiSpam(2, "rottingearth") then
		specWarnRottingEarth:Show()
		specWarnRottingEarth:Play("runout")
	elseif spellId == 198408 and destGUID == UnitGUID("player") and self:AntiSpam(2, "nightfall") then --Сумерки
		specWarnNightfall:Show()
		specWarnNightfall:Play("runout")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 95772 then--frenzied-nightclaw
		timerGrievousRipCD:Stop(args.destGUID)
	elseif cid == 95769 then--mindshattered-screecher
		timerUnnervingScreechCD:Stop(args.destGUID)
	elseif cid == 95779 then--festerhide-grizzly
		timerSpewCorruptionCD:Stop(args.destGUID)
		timerMaddeningRoarCD:Stop(args.destGUID)
	elseif cid == 95771 then--dreadsoul-ruiner
		timerStarShowerCD:Stop(args.destGUID)
	elseif cid == 95766 then--crazed-razorbeak
		timerPropellingChargeCD:Stop(args.destGUID)
	elseif cid == 99358 then--rotheart-dryad
		timerPoisonSpearCD:Stop(args.destGUID)
	elseif cid == 101991 then--nightmare-dweller
		timerTormentingEyeCD:Stop(args.destGUID)
		--Boss RP Timer Stuff
		--"<13.29 01:20:51> [CLEU] UNIT_DIED##nil#Creature-0-4223-1466-16781-101991-000203D8A6#Nightmare Dweller#-1#false#nil#nil", -- [65]
		--"<18.14 01:20:55> [UNIT_SPELLCAST_SUCCEEDED] Oakheart(100.0%-0.0%){Target:??} -Cancel Deep Roots- [[focus:Cast-3-4223-1466-16781-165953-000103D947:165953]]", -- [68]
		--"<21.41 01:20:59> [DBM_Debug] ENCOUNTER_START event fired: 1837 Oakheart 23 5#nil", -- [73]
		self.vb.trashRemaining = self.vb.trashRemaining - 1
		if self.vb.trashRemaining == 0 then
			timerRP:Start(8)
		end
	elseif cid == 100531 then--bloodtainted-fury
		timerBloodBombCD:Stop(args.destGUID)
		timerBloodAssaultCD:Stop(args.destGUID)
	elseif cid == 100532 then--bloodtainted-burster#
		timerBloodMetaCD:Stop(args.destGUID)
	elseif cid == 100527 then--dreadfire-imp
		timerDreadInfernoCD:Stop(args.destGUID)
	elseif cid == 99366 then--taintheart-summoner
		timerCurseofIsolationCD:Stop(args.destGUID)
	elseif cid == 99360 then--Vilethorn Blossom
		timerRootBurstCD:Stop(args.destGUID)
	elseif cid == 99359 then--rotheart-keeper
		timerVileMushroomCD:Stop(args.destGUID)
	elseif cid == 100526 then--tormented-bloodseeker
		timerDarksoulBiteCD:Stop(args.destGUID)
	end
end

--"<21.73 01:19:30> [CHAT_MSG_MONSTER_YELL] Defilers... I can smell the Nightmare in your blood. Be gone from these woods or suffer nature's wrath!#Archdruid Glaidalis###Omegal##0#0##0#1578#nil#0#false#false#false#false", -- [64]
--"<23.25 01:19:32> [CHAT_MSG_MONSTER_YELL] Kill him! Protect the grove!#Druidic Preserver###Omegal##0#0##0#1579#nil#0#false#false#false#false", -- [65]
--"<24.56 01:19:33> [CLEU] UNIT_DIED##nil#Creature-0-4223-1466-16781-100403-000183D8A6#Druidic Preserver#-1#false#nil#nil", -- [68]
--"<29.81 01:19:38> [DBM_Debug] ENCOUNTER_START event fired
function mod:CHAT_MSG_MONSTER_YELL(msg)
	if (msg == L.GlaidalisRP or msg:find(L.GlaidalisRP)) and self:LatencyCheck(1000) then
		self:SendSync("firstBossRP")
	end
end

function mod:OnSync(msg)
	if msg == "firstBossRP" and self:AntiSpam(10, 9) then
		timerRP:Start(8)
	end
end
