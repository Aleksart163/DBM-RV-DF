local mod	= DBM:NewMod(2482, "DBM-Raids-Dragonflight", 3, 1200)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240426070000")
mod:SetCreatureID(187967)
mod:SetEncounterID(2592)
mod:SetUsedIcons(1, 2, 3)
mod:SetHotfixNoticeRev(20240426070000)
mod:SetMinSyncRevision(20240426070000)
mod.respawnTime = 29

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 371976 372082 373405 374112 373027 371983 372539",
	"SPELL_CAST_SUCCESS 372238 181113",
	"SPELL_SUMMON 372242 372843",
	"SPELL_AURA_APPLIED 371976 372082 372030 372044 385083 373048 374104",
	"SPELL_AURA_APPLIED_DOSE 372030 385083",
	"SPELL_AURA_REMOVED 371976 372082 372030 373048",
	"SPELL_AURA_REMOVED_DOSE 372030",
	"SPELL_INTERRUPT",
--	"SPELL_PERIODIC_DAMAGE 372055",
--	"SPELL_PERIODIC_MISSED 372055",
	"UNIT_DIED",
	"CHAT_MSG_RAID_BOSS_EMOTE"
)

--[[
(ability.id = 371976 or ability.id = 372082 or ability.id = 373405 or ability.id = 373027 or ability.id = 371983) and type = "begincast"
 or (ability.id = 372238 or ability.id = 372648) and type = "cast"
 or ability.id = 181113 and source.id = 189234
 or ability.id = 372539 or type = "interrupt"
 or ability.id = 181089 and type = "cast"
--]]
--General
--local specWarnGTFO							= mod:NewSpecialWarningGTFO(340324, nil, nil, nil, 1, 8)

--local berserkTimer							= mod:NewBerserkTimer(600)
--Stage One: Ice Climbers
mod:AddTimerLine(DBM:EJ_GetSectionInfo(24883))
local warnPhase									= mod:NewPhaseChangeAnnounce(2, 2, nil, nil, nil, nil, nil, 2)
local warnChillingBlast							= mod:NewTargetAnnounce(371976, 2)
local warnEnvelopingWebs						= mod:NewTargetNoFilterAnnounce(372082, 2) --Опутывающие сети
local warnWrappedInWebs							= mod:NewTargetNoFilterAnnounce(372044, 4)
local warnCallSpiderlings						= mod:NewCountAnnounce(372238, 2)
local warnFrostbreathArachnid					= mod:NewSpellAnnounce(-24899, 2) --Хладодыщащий арахнид

local specWarnChillingBlast						= mod:NewSpecialWarningMoveAway(371976, nil, nil, nil, 1, 2)
local specWarnEnvelopingWebs					= mod:NewSpecialWarningYou(372082, nil, nil, nil, 1, 6) --Опутывающие сети
local specWarnStickyWebbing						= mod:NewSpecialWarningStack(372030, nil, 2, nil, nil, 1, 6)
local specWarnGossamerBurst						= mod:NewSpecialWarningSpell(139496, nil, 373405, nil, 4, 12) --Взрыв паутины
local specWarnWebBlast							= mod:NewSpecialWarningTaunt(385083, nil, nil, nil, 1, 2)
local specWarnFreezingBreath					= mod:NewSpecialWarningDodge(374112, nil, nil, nil, 1, 2)

local timerChillingBlastCD						= mod:NewCDCountTimer(18.5, 371976, nil, nil, nil, 3) --Леденящий взрыв
local timerEnvelopingWebsCD						= mod:NewCDCountTimer(24, 372082, nil, nil, nil, 3) --Опутывающие сети
local timerGossamerBurstCD						= mod:NewCDCountTimer(36.9, 139496, 373405, nil, nil, 7, nil, nil, nil, 1, 5) --Взрыв паутины 36.9-67.6
local timerGossamerBurst						= mod:NewCastTimer(4, 139496, 373405, nil, nil, 7, nil, nil, nil, 1, 3) --Взрыв паутины 
local timerCallSpiderlingsCD					= mod:NewCDCountTimer(25.1, 372238, nil, nil, nil, 1) --Призыв паучков
local timerFrostbreathArachnidCD				= mod:NewCDTimer(98.9, 332313, -24899, nil, nil, 1, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DAMAGE_ICON, nil, 3, 5) --Хладодыщащий арахнид
local timerFreezingBreathCD						= mod:NewCDTimer(16, 374112, nil, "Tank", nil, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerPhaseCD								= mod:NewPhaseTimer(30)

local yellChillingBlast							= mod:NewShortYell(371976, nil, nil, nil, "YELL") --Леденящий взрыв
local yellChillingBlastFades					= mod:NewShortFadesYell(371976, nil, nil, nil, "YELL") --Леденящий взрыв
local yellEnvelopingWebs						= mod:NewShortPosYell(372082, nil, nil, nil, "YELL") --Опутывающие сети
local yellEnvelopingWebsFades					= mod:NewIconFadesYell(372082, nil, nil, nil, "YELL") --Опутывающие сети

mod:AddInfoFrameOption(372030, false)--Useful raid leader tool, but not needed by everyone
mod:GroupSpells(372082, 372030, 372044)--Wrapped in webs and sticking webbing with enveloping Webs

--Stage Two: Cold Peak
mod:AddTimerLine(DBM:EJ_GetSectionInfo(24885))
local warnSuffocatinWebs							= mod:NewTargetNoFilterAnnounce(373048, 3) --Удушающие тенета

local specWarnSuffocatingWebs						= mod:NewSpecialWarningYouPos(373048, nil, nil, nil, 1, 6) --Удушающие тенета
local specWarnRepellingBurst						= mod:NewSpecialWarningSpell(371983, nil, nil, nil, 2, 12) --Отталкивающий взрыв

local timerSuffocatingWebsCD						= mod:NewCDCountTimer(38.8, 373048, nil, nil, nil, 3) --Удушающие тенета 38-46
local timerRepellingBurstCD							= mod:NewCDCountTimer(33.9, 371983, nil, nil, nil, 7, nil, nil, nil, 1, 5) --Отталкивающий взрыв

local yellSuffocatingWebs							= mod:NewShortPosYell(373048, nil, nil, nil, "YELL") --Удушающие тенета
local yellSuffocatingWebsFades						= mod:NewIconFadesYell(373048, nil, nil, nil, "YELL") --Удушающие тенета

mod:AddSetIconOption("SetIconOnSufWeb", 373048, true, false, {1, 2, 3}) --Удушающие тенета

local stickyStacks = {}
mod.vb.webIcon = 1
mod.vb.blastCount = 0
mod.vb.webCount = 0
mod.vb.burstCount = 0--Both bursts
mod.vb.spiderlingsCount = 0
mod.vb.bigAddCount = 0
--P1 being one giant sequenced table is more of a lazy solution vs trying to create timer tables for EACH movement (which is how fight is actually scripted)
--The timers would be more accurate with a new table every movement, but the amount of work involved isnt worth it.
local difficultyName = "lfr"
local allTimers = {
	["mythic"] = {--Very close to heroic so won't alter til transcriptor to make it lower work load
		[1] = {
			--Chilling Blast
			[371976] = {15.5, 37.6, 37.4, 29.1, 37.2, 37.5, 21.9, 36.5, 37.3},
			--Enveloping Webs
			[372082] = {18.1, 26.7, 30.5, 44.8, 26.7, 30.4, 38.9, 26.4, 30.4},
			--Взрыв паутины
			[373405] = {31.4, 37.7, 66.3, 36.7, 59.8, 37.8},
			--Call Spiderlings
			[372238] = {0, 25.5, 25.5, 26.7, 38.8, 25.5, 25.5, 25.5, 20.7, 26.7, 26.7},--5th has largest variance, 14-23 because sequencing isn't right way to do this, just the lazy way
		},
		--[2] = {
		--	--Chilling Blast
		--	[371976] = {15.7, 17.0, 32.8, 32.8, 34.1, 34, 34.0, 35.2, 34.0},--Unused for now
		--	--Call Spiderlings
		--	[372238] = {12.8, 30.4, 30.5, 32.8, 35.2},--Unused for now
		--},
	},
	["heroic"] = {
		[1] = {
			--Chilling Blast
			[371976] = {15.5, 37.6, 37.4, 26.7, 37.2, 36.4, 21.9, 36.5, 37.3},--likely 36 sec cd that resets on encounter events
			--Enveloping Webs
			[372082] = {18.1, 26.7, 30.5, 43.8, 24.3, 26.6, 38.9, 26.4, 30.4},--likely 26sec cd that rests on encounter events
			--Взрыв паутины
			[373405] = {31.4, 37.7, 64.3, 36.5, 59.6, 39.1},--likely 36 sec cd that resets on encounter events
			--Call Spiderlings
			[372238] = {0, 25.5, 25.5, 26.7, 38.8, 25.5, 25.5, 25.5, 19.4, 26.7, 26.7},--likely 25 sec cd that resets on encounter events
		},
		--[2] = {
		--	--Chilling Blast
		--	[371976] = {15.7, 17.0, 32.8, 32.8, 34.1, 34, 34.0, 35.2, 34.0},--Unused for now
		--	--Call Spiderlings
		--	[372238] = {12.8, 30.4, 30.5, 32.8, 35.2},--Unused for now
		--},
	},
	["normal"] = {--LFR and normal are NOT the same, especially abilities queued by chilling blast on normal vs LFR
		[1] = {
			--Chilling Blast (only normal, not cast in LFR)
			[371976] = {16.1, 36.5, 37.7, 26.7, 36.4, 36.5, 23.1, 37.7, 36.4},--likely 36 sec cd that resets on encounter events
			--Enveloping Webs
			[372082] = {17.2, 26.7, 32.8, 43.8, 27.9, 31.5, 38.9, 28, 30.3},--likely 26sec cd that rests on encounter events
			--Gossamer Burst
			[373405] = {31.4, 36.5, 65.3, 34, 64.3, 34},--likely 34sec cd that resets on encounter events
			--Call Spiderlings
			[372238] = {2.7, 20.6, 20.7, 21.8, 20.6, 29.2, 20.7, 20.8, 20.7, 27.9, 20.6, 20.6, 20.6},--likely 20 sec cd that resets on encounter events
		},
		--[2] = {
		--	--Chilling Blast
		--	[371976] = {16.6, 32.8},--Unused for now
		--	--Call Spiderlings
		--	[372238] = {14.2, 25.5, 25.5},--Unused for now
		--},
	},
	["lfr"] = {--LFR and normal are NOT the same, especially abilities queued by chilling blast on normal vs LFR and lower spiderlings CD
		[1] = {
			--Enveloping Webs
			[372082] = {17.2, 26.7, 29.1, 43.4, 27, 27.9, 43.7, 26.7, 27.9},--likely 26sec cd that rests on encounter events
			--Gossamer Burst
			[373405] = {31.4, 36.5, 65.3, 34, 64.3, 34},--likely 34sec cd that resets on encounter events
			--Call Spiderlings
			[372238] = {2.7, 36, 30.7, 31.2, 15.8, 30.4, 30.3, 37.6, 30.3, 30.4},--likely 30 sec cd that resets on encounter events
		},
		--[2] = {
		--	--Chilling Blast
		--	[371976] = {16.6, 32.8},--Unused for now
		--	--Call Spiderlings
		--	[372238] = {14.2, 25.5, 25.5},--Unused for now
		--},
	},
}

local function startAnnounceArachnid(self)
	warnFrostbreathArachnid:Show()
end

function mod:OnCombatStart(delay)
	self:SetStage(1)
	table.wipe(stickyStacks)
	self.vb.webIcon = 1
	self.vb.blastCount = 0
	self.vb.webCount = 0
	self.vb.burstCount = 0
	self.vb.spiderlingsCount = 0
	self.vb.bigAddCount = 1--Starts at 1 because 1 is up with boss on pull
	if not self:IsLFR() then
		timerChillingBlastCD:Start(15.2-delay, 1)
	end
	timerEnvelopingWebsCD:Start(17.2-delay, 1)
	timerGossamerBurstCD:Start(31.4-delay, 1)
	timerPhaseCD:Start(42.4-delay)
	if self:IsMythic() then
		difficultyName = "mythic"
	elseif self:IsHeroic() then
		difficultyName = "heroic"
	elseif self:IsNormal() then
		difficultyName = "normal"
	else
		difficultyName = "lfr"
	end
	if self.Options.InfoFrame then
		DBM.InfoFrame:SetHeader(DBM:GetSpellName(372030))
		DBM.InfoFrame:Show(20, "table", stickyStacks, 1)
	end
end

function mod:OnCombatEnd()
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end

function mod:OnTimerRecovery()
	if self:IsMythic() then
		difficultyName = "mythic"
	elseif self:IsHeroic() then
		difficultyName = "heroic"
	elseif self:IsNormal() then
		difficultyName = "normal"
	else
		difficultyName = "lfr"
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 371976 then
		self.vb.blastCount = self.vb.blastCount + 1
		--Seems to be cast 3 casts per movement, minus first, first started at movement, 2nd after first with longer cd then 3rd cast shorter cd after 2nd
		--Repeats on next movement
		--More consistent in stage 2
		if self:GetStage(2) then
			timerChillingBlastCD:Start(32, self.vb.blastCount+1)
		else
			local timer = self:GetFromTimersTable(allTimers, difficultyName, 1, spellId, self.vb.blastCount+1)
			if timer then
				timerChillingBlastCD:Start(timer, self.vb.blastCount+1)
			end
		end
	elseif spellId == 372082 then
		self.vb.webIcon = 1
		self.vb.webCount = self.vb.webCount + 1
		local timer = self:GetFromTimersTable(allTimers, difficultyName, 1, spellId, self.vb.webCount+1)
		if timer then
			timerEnvelopingWebsCD:Start(timer, self.vb.webCount+1)
		end
	elseif spellId == 373405 then
		self.vb.burstCount = self.vb.burstCount + 1
		specWarnGossamerBurst:Show(self.vb.burstCount)
		specWarnGossamerBurst:Play("pullin")
		local timer = self:GetFromTimersTable(allTimers, difficultyName, 1, spellId, self.vb.burstCount+1)
		if timer then
			timerGossamerBurstCD:Start(timer, self.vb.burstCount+1)
		end
		timerGossamerBurst:Start()
	elseif spellId == 374112 then --Мерзлое дыхание
		if self:IsTanking("player", nil, nil, true, args.sourceGUID) then
			specWarnFreezingBreath:Show()
			specWarnFreezingBreath:Play("shockwave")
		end
		timerFreezingBreathCD:Start(nil, args.sourceGUID)
	elseif spellId == 372539 then --Вершина льда
		self.vb.blastCount = 0
		self.vb.burstCount = 0
		self.vb.webCount = 0
		self.vb.spiderlingsCount = 0
		self:SetStage(2)
		warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(2))
		warnPhase:Play("ptwo")
		timerChillingBlastCD:Stop()
		timerEnvelopingWebsCD:Stop()
		timerGossamerBurstCD:Stop()
		timerCallSpiderlingsCD:Stop()
		timerFrostbreathArachnidCD:Stop()
		timerPhaseCD:Stop()
		self:Unschedule(startAnnounceArachnid)
	elseif spellId == 373027 then
		self.vb.webIcon = 1
		self.vb.webCount = self.vb.webCount + 1
		timerSuffocatingWebsCD:Start(nil, self.vb.webCount+1)
	elseif spellId == 371983 then
		self.vb.burstCount = self.vb.burstCount + 1
		specWarnRepellingBurst:Show(self.vb.burstCount)
		specWarnRepellingBurst:Play("carefly")
		timerRepellingBurstCD:Start(nil, self.vb.burstCount+1)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 372238 then
		self.vb.spiderlingsCount = self.vb.spiderlingsCount + 1
		warnCallSpiderlings:Show(self.vb.spiderlingsCount)
		if self:GetStage(2) then
			--Mythic sequenced, 44, 30, 35?
			timerCallSpiderlingsCD:Start(self:IsNormal() and 25 or 30, self.vb.spiderlingsCount+1)
		else
			local timer = self:GetFromTimersTable(allTimers, difficultyName, 1, spellId, self.vb.spiderlingsCount+1)
			if timer then
				timerCallSpiderlingsCD:Start(timer, self.vb.spiderlingsCount+1)
			end
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 371976 then
		if args:IsPlayer() then
			specWarnChillingBlast:Show()
			specWarnChillingBlast:Play("scatter")
			yellChillingBlast:Yell()
			yellChillingBlastFades:Countdown(spellId)
		end
		warnChillingBlast:CombinedShow(0.3, args.destName)
	elseif spellId == 372082 then
		local icon = self.vb.webIcon
		if self.Options.SetIconOnWeb then
			self:SetIcon(args.destName, icon)
		end
		if args:IsPlayer() then
			specWarnEnvelopingWebs:Show(self:IconNumToTexture(icon))
			specWarnEnvelopingWebs:Play("mm"..icon)
			yellEnvelopingWebs:Yell(icon, icon)
			yellEnvelopingWebsFades:Countdown(spellId, nil, icon)
		end
		warnEnvelopingWebs:CombinedShow(1, args.destName)
		self.vb.webIcon = self.vb.webIcon + 1
	elseif spellId == 373048 then
		local icon = self.vb.webIcon
		if self.Options.SetIconOnSufWeb then
			self:SetIcon(args.destName, icon)
		end
		if args:IsPlayer() then
			specWarnSuffocatingWebs:Show(self:IconNumToTexture(icon))
			specWarnSuffocatingWebs:Play("mm"..icon)
			yellSuffocatingWebs:Yell(icon, icon)
			yellSuffocatingWebsFades:Countdown(spellId, nil, icon)
		end
		warnSuffocatinWebs:CombinedShow(0.5, args.destName)
		self.vb.webIcon = self.vb.webIcon + 1
	elseif spellId == 372030 then
		local amount = args.amount or 1
		stickyStacks[args.destName] = amount
		if self.Options.InfoFrame then
			DBM.InfoFrame:UpdateTable(stickyStacks, 0.2)
		end
		if args:IsPlayer() and amount >= 2 and amount % 2 == 0 then
			specWarnStickyWebbing:Show(amount)
			specWarnStickyWebbing:Play("stackhigh")
		end
	elseif spellId == 372044 or spellId == 374104 then--Hard version, Easy version
		warnWrappedInWebs:CombinedShow(0.5, args.destName)
	elseif spellId == 385083 and not args:IsPlayer() and (args.amount or 1) > 4 and not DBM:UnitDebuff("player", spellId) then
		specWarnWebBlast:Show(args.destName)
		specWarnWebBlast:Play("tauntboss")
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 371976 then
		if args:IsPlayer() then
			yellChillingBlastFades:Cancel()
		end
	elseif spellId == 372082 then
		if self.Options.SetIconOnWeb then
			self:SetIcon(args.destName, 0)
		end
		if args:IsPlayer() then
			yellEnvelopingWebsFades:Cancel()
		end
	elseif spellId == 373048 then
		if self.Options.SetIconOnSufWeb then
			self:SetIcon(args.destName, 0)
		end
		if args:IsPlayer() then
			yellSuffocatingWebsFades:Cancel()
		end
	elseif spellId == 372030 then
		stickyStacks[args.destName] = nil
		if self.Options.InfoFrame then
			DBM.InfoFrame:UpdateTable(stickyStacks, 0.2)
		end
	end
end

function mod:SPELL_AURA_REMOVED_DOSE(args)
	local spellId = args.spellId
	if spellId == 372030 then
		stickyStacks[args.destName] = args.amount or 1
		if self.Options.InfoFrame then
			DBM.InfoFrame:UpdateTable(stickyStacks, 0.2)
		end
	end
end

--[[
function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 372055 and destGUID == UnitGUID("player") and self:AntiSpam(2, 4) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
--]]

function mod:SPELL_INTERRUPT(args)
	if type(args.extraSpellId) == "number" and args.extraSpellId == 372539 then
		--These timers can still variate due to bugs I won't document here or code around (even though I know how to)
		--needless to say I hope they get fixed
		timerCallSpiderlingsCD:Start(8.4, 1)
		if not self:IsLFR() then
			timerChillingBlastCD:Start(10.8, 1)
		end
		timerSuffocatingWebsCD:Start(18.1, 1)
		timerRepellingBurstCD:Start(27.8, 1)
	end
end


function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 189234 then--Frostbreath Arachnid
		timerFreezingBreathCD:Stop(args.destGUID)
	end
end

--"<2.19 23:28:07> [ENCOUNTER_START] 2592#Sennarth, The Cold Breath#15#20", -- [26]
--"<45.37 23:28:50> [CHAT_MSG_RAID_BOSS_EMOTE] |TInterface\\ICONS\\INV_MineSpider2_Crystal.blp:20|t %s begins to ascend!
--"<146.08 23:30:31> [CHAT_MSG_RAID_BOSS_EMOTE] |TInterface\\ICONS\\INV_MineSpider2_Crystal.blp:20|t %s begins to ascend!
--"<245.88 23:32:10> [CHAT_MSG_RAID_BOSS_EMOTE] |TInterface\\ICONS\\INV_MineSpider2_Crystal.blp:20|t %s begins to ascend!
--"<300.23 23:33:05> [CLEU] SPELL_CAST_START#Creature-0-2085-2522-14007-187967-000040998B#Sennarth<12.0%-3.0%>##nil#372539#Apex of Ice#nil#nil", -- [23406]
function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if msg:find("INV_MineSpider2_Crystal.blp") then
		if self.vb.stageTotality == 1 then --1 движение босса
			self:SetStage(1.25)--Arbritrary phase numbers since journal classifies movements as intermissions and top as true stage 2
			warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(1.25))
			warnPhase:Play("phasechange")
			--проверить ещё раз таймеры, а потом сделать прошляп Мурчалю--
			timerFrostbreathArachnidCD:Start(63)
			self:Schedule(63, startAnnounceArachnid, self)
			timerPhaseCD:Start(99.8) -- под гер и обычку норм (ещё раз проверить миф)
		elseif self.vb.stageTotality == 2 then --2 движение босса
			self:SetStage(1.5)--Arbritrary phase numbers since journal classifies movements as intermissions and top as true stage 2
			warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(1.5))
			warnPhase:Play("phasechange")
			--проверить ещё раз таймеры, а потом сделать прошляп Мурчалю--
			if self:IsEasy() then
				timerFrostbreathArachnidCD:Start(62.5) --точно под обычку
				self:Schedule(62.5, startAnnounceArachnid, self)
				timerPhaseCD:Start(98.5) --точно под обычку
			elseif self:IsHeroic() then
				timerFrostbreathArachnidCD:Start(62) --точно под гер
				self:Schedule(62, startAnnounceArachnid, self) --точно под гер
				timerPhaseCD:Start(99.5) --точно под гер
			else
				timerFrostbreathArachnidCD:Start(62) --точно под гер
				self:Schedule(62, startAnnounceArachnid, self) --точно под гер
				timerPhaseCD:Start(98.5)
			end
		else --последнее движение
			self:SetStage(1.75)--Arbritrary phase numbers since journal classifies movements as intermissions and top as true stage 2
			warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(1.75))
			warnPhase:Play("phasechange")
			timerPhaseCD:Start(57.5)--Til Stage 2 (2nd movement has ended)
		end
	end
end
