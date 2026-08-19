local mod	= DBM:NewMod(104, "DBM-Party-Cataclysm", 9, 65)
local L		= mod:GetLocalizedStrings()
local wowToc = DBM:GetTOC()

if (wowToc >= 100200) then
	mod.statTypes = "normal,heroic,challenge,timewalker"
	mod.upgradedMPlus = true
	mod:SetCreatureID(213770, 42172)--P1 Ink, P2 Ozumat
	mod:SetBossHPInfoToHighest()
else
	mod.statTypes = "normal,heroic"
	mod:SetCreatureID(40792)
	mod:SetMainBossID(42172)--42172 is Ozumat, but we need Neptulon for engage trigger.
end

mod:SetRevision("20260630000000")
mod:SetEncounterID(1047)
mod:SetHotfixNoticeRev(20260714000000)
--mod:SetMinSyncRevision(20260714000000)

mod:RegisterCombat("combat")

if (wowToc >= 100200) then
	--Patch 10.2 or later
	mod:RegisterEventsInCombat(
		"SPELL_CAST_START 428401 428868 428530 428889 428526",
		"SPELL_CAST_SUCCESS 428674 428594 428668",
		"SPELL_AURA_APPLIED 428407 428668 431368",
		"UNIT_DIED"
	)
	mod:RegisterEvents(
		"CHAT_MSG_MONSTER_SAY"
	)

	--[[
(ability.id 428401 or ability.id 428868 or ability.id 428530 or ability.id 428889) and type = "begincast"
 or target.id = 213770 and type = "death"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
 or ability.id = 428526 and type = "begincast"
	--]]
	--NOTE: "Foul Bolt now has an 8 second initial cool up"
	local warnPhase2									= mod:NewPhaseAnnounce(2, 2, nil, nil, nil, nil, nil, 2)
	--Ink of Ozumat
	mod:AddTimerLine(DBM:EJ_GetSectionInfo(28235))
	local warnBlottingBarrage							= mod:NewTargetAnnounce(428407, 3) --Обстрел чернилами
	local warnFoulBolt									= mod:NewSpellAnnounce(428889, 3, nil, "Tank") --Мерзкая стрела


	local specWarnBlottingBarrage						= mod:NewSpecialWarningYou(428407, nil, nil, nil, 1, 2) --Обстрел чернилами
	local specWarnPutridRoar							= mod:NewSpecialWarningCount(428868, nil, nil, DBM_COMMON_L.AOEDAMAGE, 2, 2) --Смрадный рык (АоЕ)
	local specWarnMurkSpew								= mod:NewSpecialWarningDefensive(428530, nil, nil, DBM_COMMON_L.FRONTAL, 3, 2) --Мутный поток (Фронталка)
	local specWarnMurkSpew2								= mod:NewSpecialWarningDodge(428530, "-Tank", nil, DBM_COMMON_L.FRONTAL, 2, 2) --Мутный поток (Фронталка)
	--local specWarnGTFO								= mod:NewSpecialWarningGTFO(409058, nil, nil, nil, 1, 8)

	local timerRP										= mod:NewRPTimer(68)
	local timerBlottingBarrageCD						= mod:NewCDCountTimer(30.3, 428407, nil, nil, nil, 3) --Обстрел чернилами
	local timerPutridRoarCD								= mod:NewCDCountTimer(30.3, 428868, DBM_COMMON_L.AOEDAMAGE.." (%s)", nil, nil, 2, nil, DBM_COMMON_L.MAGIC_ICON) --Смрадный рык
	local timerMurkSpewCD								= mod:NewCDCountTimer(32.7, 428530, DBM_COMMON_L.FRONTAL.." (%s)", nil, nil, 3, nil, DBM_COMMON_L.TANK_ICON) --Мутный поток (Фронталка)
	--Neptulon
	mod:AddTimerLine(DBM:EJ_GetSectionInfo(28246))
	local warnCleansingFlux								= mod:NewTargetNoFilterAnnounce(428668, 1) --Очищающее течение

	local specWarnCleansingFlux							= mod:NewSpecialWarningMoveTo(428668, nil, nil, nil, 1, 15) --Очищающее течение

	local timerCleansingFluxCD							= mod:NewNextTimer(30.3, 428668, nil, nil, nil, 5) --Очищающее течение
	--Ozumat
	mod:AddTimerLine(DBM:EJ_GetSectionInfo(28238))
	local specWarnDelugeofFilth							= mod:NewSpecialWarningSwitch(428594, "-Healer", nil, DBM_COMMON_L.ADDS, 1, 2) --Поток грязи (Адды)
	local specWarnInkBlast								= mod:NewSpecialWarningInterrupt(428526, "HasInterrupt", nil, nil, 1, 2) --Чернильный взрыв

	local timerDelugeofFilthCD							= mod:NewCDCountTimer(30.3, 428594, DBM_COMMON_L.ADDS.." (%s)", nil, nil, 1) --Поток грязи (Адды) 30-31.5
	local timerInkBlastCD								= mod:NewCDNPTimer(3.9, 428526, nil, nil, nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Чернильный взрыв 4.2-4.9 CD, nameplate only bar

	local yellMurkSpew									= mod:NewYell(428530, DBM_COMMON_L.FRONTAL, nil, nil, "YELL") --Мутный поток (Фронталка)
	local yellBlottingBarrage							= mod:NewYell(428407, nil, nil, nil, "YELL") --Обстрел чернилами
	local yellCleansingFlux								= mod:NewYell(428668, nil, nil, nil, "YELL") --Очищающее течение
		
	mod.vb.barrageCount = 0
	mod.vb.putridCount = 0
	mod.vb.murkCount = 0
	mod.vb.delugeCount = 0

	local proshlyapationPutridRoarTimers = {18.2, 35.2, 36.2, 36.3} --Первые 4 таймеров точные
	local proshlyapationBlottingBarrageTimers = {5.6, 34.2, 35.2, 35.2} --Первые 4 таймеров точные
	local proshlyapationDelugeofFilthTimers = {20.6, 35.2, 34.2} --Первые 3 таймеров точные
	
	function mod:OnCombatStart(delay)
		self:SetStage(1)
		self.vb.barrageCount = 0
		self.vb.putridCount = 0
		self.vb.murkCount = 0
		self.vb.delugeCount = 0
		timerBlottingBarrageCD:Start(5.6-delay, 1)
		timerMurkSpewCD:Start(10.5-delay, 1)
		timerCleansingFluxCD:Start(15.2-delay)--SUCCESS, no reason to warn when it starts, it's 14 second cast
		timerPutridRoarCD:Start(18.2-delay, 1)
		timerDelugeofFilthCD:Start(20.6-delay, 1)
	end

	function mod:SPELL_CAST_START(args)
		local spellId = args.spellId
		if spellId == 428401 then
			self.vb.barrageCount = self.vb.barrageCount + 1
			local timer
			timer = proshlyapationBlottingBarrageTimers[self.vb.barrageCount+1] or 35.2
			timerBlottingBarrageCD:Start(timer, self.vb.barrageCount+1)
		elseif spellId == 428868 then
			self.vb.putridCount = self.vb.putridCount + 1
			specWarnPutridRoar:Show(self.vb.putridCount)
			specWarnPutridRoar:Play("aesoon")
			local timer
			timer = proshlyapationPutridRoarTimers[self.vb.putridCount+1] or 36.3
			timerPutridRoarCD:Start(timer, self.vb.putridCount+1)
		elseif spellId == 428530 then
			self.vb.murkCount = self.vb.murkCount + 1
			if self:IsTanking("player", nil, nil, true, args.sourceGUID) then--GUID used to scan all potential boss unitids
				specWarnMurkSpew:Show()
				specWarnMurkSpew:Play("defensive")
				yellMurkSpew:Yell()
			else
				specWarnMurkSpew2:Show()
				specWarnMurkSpew2:Play("watchstep")
			end
			timerMurkSpewCD:Start(nil, self.vb.murkCount+1)
		elseif spellId == 428889 then
			warnFoulBolt:Show()
		elseif spellId == 428526 then
			timerInkBlastCD:Start(nil, args.sourceGUID)
			if self:CheckInterruptFilter(args.sourceGUID, false, true) then
				specWarnInkBlast:Show(args.sourceName)
				specWarnInkBlast:Play("kickcast")
			end
		end
	end

	function mod:SPELL_CAST_SUCCESS(args)
		local spellId = args.spellId
		if spellId == 428668 then --428674
			timerCleansingFluxCD:Start()
		elseif spellId == 428594 then
			self.vb.delugeCount = self.vb.delugeCount + 1
			specWarnDelugeofFilth:Show()
			specWarnDelugeofFilth:Play("changetarget")
			local timer
			timer = proshlyapationDelugeofFilthTimers[self.vb.delugeCount+1] or 35.2
			timerDelugeofFilthCD:Start(timer, self.vb.delugeCount+1)
		end
	end

	function mod:SPELL_AURA_APPLIED(args)
		local spellId = args.spellId
		if spellId == 428407 then
			warnBlottingBarrage:CombinedShow(0.3, args.destName)
			if args:IsPlayer() then
				specWarnBlottingBarrage:Show()
				specWarnBlottingBarrage:Play("targetyou")
				yellBlottingBarrage:Yell()
			end
		elseif spellId == 431368 or spellId == 428668 then --428668
		--	warnCleansingFlux:PreciseShow(2, args.destName)
			warnCleansingFlux:CombinedShow(0.3, args.destName)
			if args:IsPlayer() then
				specWarnCleansingFlux:Show(DBM_COMMON_L.POOL)
				specWarnCleansingFlux:Play("movetopool")
				yellCleansingFlux:Yell()
			end
		end
	end

	function mod:UNIT_DIED(args)
		local cid = self:GetCIDFromGUID(args.destGUID)
		if cid == 213770 then--Ink of Ozumat
			self:SetStage(2)
			warnPhase2:Show()
			warnPhase2:Play("ptwo")
			timerBlottingBarrageCD:Stop()
			timerPutridRoarCD:Stop()
			timerMurkSpewCD:Stop()
			timerCleansingFluxCD:Stop()
			timerDelugeofFilthCD:Stop()
		elseif cid == 213806 then--Add
			timerMurkSpewCD:Stop(args.destGUID)
		end
	end

	--"<2039.92 19:31:50> [CHAT_MSG_MONSTER_SAY] The beast has returned! It must not pollute my waters!#Neptulon###Priestatsu##0#0##0#555#nil#0#false#false#false#false", -- [23573]
	--"<2051.75 19:32:02> [NAME_PLATE_UNIT_ADDED] Ink of Ozumat#Creature-0-5770-643-10350-213770-000021960F", -- [23600]
	--"<2057.58 19:32:08> [ENCOUNTER_START] 1047#Ozumat#8#5", -- [23605]
	function mod:CHAT_MSG_MONSTER_SAY(msg)
		if (msg == L.RolePlay or msg:find(L.RolePlay)) and self:LatencyCheck() then
			self:SendSync("openingRP")
		end
	end

	function mod:OnSync(msg)
		if msg == "openingRP" and self:AntiSpam(10, 1) then
			timerRP:Start(11.8)
		end
	end
else
	--10.1.7 on retail, and Cataclysm classic if it happens (if it doesn't happen old version of mod will be retired)
	mod:RegisterEventsInCombat(
		"SPELL_AURA_APPLIED 83463 76133",
		"SPELL_CAST_SUCCESS 83985 83986",
		"UNIT_SPELLCAST_SUCCEEDED"
	)

	local warnPhase			= mod:NewPhaseChangeAnnounce(2, nil, nil, nil, nil, nil, nil, 2)
	local warnBlightSpray	= mod:NewSpellAnnounce(83985, 2)

	local timerPhase		= mod:NewTimer(95, "TimerPhase", nil, nil, nil, 6)
	local timerBlightSpray	= mod:NewBuffActiveTimer(4, 83985, nil, nil, nil, 3)

	mod.vb.warnedPhase2 = false
	mod.vb.warnedPhase3 = false

	function mod:OnCombatStart(delay)
		self:SetStage(1)
		self.vb.warnedPhase2 = false
		self.vb.warnedPhase3 = false
		timerPhase:Start()--Can be done right later once consistency is confirmed.
	end

	function mod:SPELL_AURA_APPLIED(args)
		if args.spellId == 83463 and not self.vb.warnedPhase2 then
			self:SetStage(2)
			warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(2))
			warnPhase:Play("ptwo")
			self.vb.warnedPhase2 = true
		elseif args.spellId == 76133 and not self.vb.warnedPhase3 then
			self:SetStage(3)
			warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(3))
			warnPhase:Play("pthree")
			self.vb.warnedPhase3 = true
		end
	end

	function mod:SPELL_CAST_SUCCESS(args)
		if args:IsSpellID(83985, 83986) then
			warnBlightSpray:Show()
			timerBlightSpray:Start()
		end
	end

	function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, spellId)
		if spellId == 83909 then --Clear Tidal Surge
			self:SendSync("bossdown")
		end
	end

	function mod:OnSync(msg)
		if not self:IsInCombat() then return end
		if msg == "bossdown" then
			DBM:EndCombat(self)
		end
	end
end
