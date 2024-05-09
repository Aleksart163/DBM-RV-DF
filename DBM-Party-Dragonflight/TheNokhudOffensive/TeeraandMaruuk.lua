local mod	= DBM:NewMod(2478, "DBM-Party-Dragonflight", 3, 1198)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20231029212301")
mod:SetCreatureID(186339, 186338)
mod:SetEncounterID(2581)
mod:SetBossHPInfoToHighest()
mod:SetHotfixNoticeRev(20221127000000)
mod:SetMinSyncRevision(20221105000000)
--mod.respawnTime = 29

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 382670 386063 385339 386547 385434 382836",
	"SPELL_AURA_APPLIED 384808 392198 392151",
	"SPELL_AURA_REMOVED 392198",
	"UNIT_DIED"
)

--[[
(ability.id = 382670 or ability.id = 386063 or ability.id = 385339 or ability.id = 386547 or ability.id = 385434 or ability.id = 382836) and type = "begincast"
 or (target.id = 186339 or target.id = 186338) and type = "death"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
 or type = "interrupt"
--]]
--General
local timerRP									= mod:NewRPTimer(27.4)
--Teera
mod:AddTimerLine(DBM:EJ_GetSectionInfo(25552))
local warnRepel									= mod:NewCastAnnounce(386547, 3, nil, nil, nil, nil, nil, 2) --Отпор
local warnSpiritLeap							= mod:NewSpellAnnounce(385434, 3) --Прыжок духа
local warnGaleArrow								= mod:NewCountAnnounce(382670, 3) --Ураганная стрела

local specWarnGaleArrow							= mod:NewSpecialWarningDefensive(382670, nil, nil, nil, 3, 4) --Ураганная стрела
local specWarnGaleArrow2						= mod:NewSpecialWarningDodge(382670, nil, nil, nil, 2, 4) --Ураганная стрела
local specWarnGuardianWind						= mod:NewSpecialWarningInterrupt(384808, "HasInterrupt", nil, nil, 1, 2) --Оберегающий ветер

local timerGaleArrowCD							= mod:NewCDCountTimer(57.4, 382670, nil, nil, nil, 7) --Ураганная стрела
local timerRepelCD								= mod:NewCDCountTimer(60, 386547, nil, nil, nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON, nil, 3, 5) --Отпор
local timerSpiritLeapCD							= mod:NewCDTimer(20.4, 385434, nil, nil, nil, 3) --Прыжок духа 20-38.4 (if guardian wind isn't interrupted this can get delayed by repel recast)

--Maruuk
mod:AddTimerLine(DBM:EJ_GetSectionInfo(25546))

local specWarnEarthsplitter						= mod:NewSpecialWarningDodgeCount(385339, nil, nil, nil, 2, 2) --Раскол земли
local specWarnFrightfulRoar						= mod:NewSpecialWarningRun(386063, nil, nil, nil, 4, 2) --Отпугивающий рык
local specWarnFrightfulRoar2					= mod:NewSpecialWarningDodge(386063, nil, nil, nil, 2, 2) --Отпугивающий рык
local specWarnBrutalize							= mod:NewSpecialWarningDefensive(382836, nil, nil, nil, 3, 4) --Свирепый удар

local timerEarthSplitterCD						= mod:NewCDCountTimer(60, 385339, nil, nil, nil, 7) --Раскол земли Off by default since it should always be cast immediately after Repel)
local timerFrightfulRoarCD						= mod:NewCDTimer(30.4, 386063, nil, nil, nil, 2, nil, DBM_COMMON_L.MAGIC_ICON) --Отпугивающий рык New timer unknown
local timerBrutalizeCD							= mod:NewCDTimer(18.2, 382836, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON) --Свирепый удар Delayed a lot. Doesn't alternate or sequence leanly, it just spell queues in randomness

local yellBrutalize								= mod:NewYell(382836, nil, nil, nil, "YELL") --Свирепый удар

mod:AddNamePlateOption("NPAuraOnAncestralBond", 392198)
--Static Counts
mod.vb.galeCount = 0
mod.vb.repelCount = 0
mod.vb.splitterCount = 0
--Sequenced counts
mod.vb.leapCount = 0
mod.vb.roarCount = 0
mod.vb.brutalizeCount = 0

local allProshlyapationsOfMurchalTimers = {
	--Прыжок духа
	[385434] = {5.4, 22.4, 21.1, 20.3, 18.5, 21.1, 20.3, 19.2, 21, 20.7, 17.7, 21.1, 21.4, 17.8, 21.3, 20.5},
	--Ураганная стрела
	[382670] = {16.1, 60.6, 60.8, 59.9},
	--Отпор
	[386547] = {56.7, 60.8, 60.8},
	--Отпугивающий рык
	[386063] = {4.5, 19, 19, 26, 19.1, 19, 22.6, 19, 19, 22.8, 19, 19.1, 22.8, 19, 19, 22.6},
	--Свирепый удар
	[382836] = {12.5, 7.5, 7.7, 7.6, 11.3, 7.5, 22.3, 7.5, 7.7, 7.6, 11.3, 7.6, 18.9, 7.5, 7.7, 7.6, 11.3, 6.5, 19.2, 7.6, 7.6, 7.5, 11.4, 7.5, 19.3, 7.6, 7.5, 7.6, 11.3, 7.5},
	--Раскол земли
	[385339] = {59, 60.8, 60.8},
}

function mod:BrutalizeTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnBrutalize:Show()
		specWarnBrutalize:Play("defensive")
		yellBrutalize:Yell()
	end
end

local function scanBosses(self, delay)
	for i = 1, 2 do
		local unitID = "boss"..i
		if UnitExists(unitID) then
			local cid = self:GetUnitCreatureId(unitID)
			local bossGUID = UnitGUID(unitID)
			if cid == 186339 then--Terra
				timerSpiritLeapCD:Start(5.4-delay, 1, bossGUID) --
				timerGaleArrowCD:Start(16.1-delay, 1, bossGUID) --
				timerRepelCD:Start(56.7-delay, 1, bossGUID) --
			else--Maruuk
				timerFrightfulRoarCD:Start(4.5-delay, 1, bossGUID) --
				timerBrutalizeCD:Start(12.5-delay, 1, bossGUID) --
				timerEarthSplitterCD:Start(59-delay, 1, bossGUID) --
			end
		end
	end
end

function mod:OnCombatStart(delay)
	--Static Counts
	self.vb.galeCount = 0
	self.vb.repelCount = 0
	self.vb.splitterCount = 0
	--Sequenced counts
	self.vb.leapCount = 0
	self.vb.roarCount = 0
	self.vb.brutalizeCount = 0
	self:Schedule(1, scanBosses, self, delay)--1 second delay to give IEEU time to populate boss guids
	if self.Options.NPAuraOnAncestralBond then
		DBM:FireEvent("BossMod_EnableHostileNameplates")
	end
end

function mod:OnCombatEnd()
	if self.Options.NPAuraOnAncestralBond then
		DBM.Nameplate:Hide(true, nil, nil, nil, true, true)
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 382670 then --Ураганная стрела
		self.vb.galeCount = self.vb.galeCount + 1
		warnGaleArrow:Show(self.vb.galeCount)
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchalTimers, false, false, spellId, self.vb.galeCount+1) or 60.5
		if timer then
			timerGaleArrowCD:Start(timer, self.vb.galeCount+1, args.sourceGUID)
		end
	elseif spellId == 386063 then --Отпугивающий рык
		self.vb.roarCount = self.vb.roarCount + 1
		if self:IsRanged() then
			specWarnFrightfulRoar2:Show()
			specWarnFrightfulRoar2:Play("watchstep")
		else
			specWarnFrightfulRoar:Show()
			specWarnFrightfulRoar:Play("justrun")
			specWarnFrightfulRoar:ScheduleVoice(1, "fearsoon")
		end
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchalTimers, false, false, spellId, self.vb.roarCount+1) or 19
		if timer then
			timerFrightfulRoarCD:Start(timer, self.vb.roarCount+1, args.sourceGUID)
		end
	elseif spellId == 385339 then --Раскол земли
		self.vb.splitterCount = self.vb.splitterCount + 1
		specWarnEarthsplitter:Show(self.vb.splitterCount)
		specWarnEarthsplitter:Play("watchstep")
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchalTimers, false, false, spellId, self.vb.splitterCount+1) or 60.5
		if timer then
			timerEarthSplitterCD:Start(timer, self.vb.splitterCount+1, args.sourceGUID)
		end
	elseif spellId == 386547 then --Отпор
		self.vb.repelCount = self.vb.repelCount + 1
		warnRepel:Show(self.vb.repelCount)
		warnRepel:Play("carefly")
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchalTimers, false, false, spellId, self.vb.repelCount+1) or 60.5
		if timer then
			timerRepelCD:Start(timer, self.vb.repelCount+1, args.sourceGUID)
		end
	elseif spellId == 385434 then --Прыжок духа
		self.vb.leapCount = self.vb.leapCount + 1
		warnSpiritLeap:Show()
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchalTimers, false, false, spellId, self.vb.leapCount+1) or 17.5
		if timer then
			timerSpiritLeapCD:Start(timer, self.vb.leapCount+1, args.sourceGUID)
		end
	elseif spellId == 382836 then --Свирепый удар
		self.vb.brutalizeCount = self.vb.brutalizeCount + 1
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchalTimers, false, false, spellId, self.vb.brutalizeCount+1) or 7.5
		if timer then
			timerBrutalizeCD:Start(timer, self.vb.brutalizeCount+1, args.sourceGUID)
		end
		self:BossTargetScanner(args.sourceGUID, "BrutalizeTarget", 0.1, 2)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 384808 then
		specWarnGuardianWind:Show(args.sourceName)
		specWarnGuardianWind:Play("kickcast")
	elseif spellId == 392198 then
		if self.Options.NPAuraOnAncestralBond then
			DBM.Nameplate:Show(true, args.destGUID, spellId)
		end
	elseif spellId == 392151 then --Ураганная стрела
		if args:IsPlayer() then
			specWarnGaleArrow:Show()
			specWarnGaleArrow:Play("defensive")
		elseif self:AntiSpam(2, "GaleArrow") then
			specWarnGaleArrow2:Show()
			specWarnGaleArrow2:Play("watchstep")
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 392198 then
		if self.Options.NPAuraOnAncestralBond then
			DBM.Nameplate:Hide(true, args.destGUID, spellId)
		end
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 186339 then--Teera
		timerGaleArrowCD:Stop()
		timerRepelCD:Stop()
		timerSpiritLeapCD:Stop()
	elseif cid == 186338 then--Maruuk
		timerEarthSplitterCD:Stop()
		timerFrightfulRoarCD:Stop()
		timerBrutalizeCD:Stop()
	end
end

--"<67.75 20:59:56> [CLEU] SPELL_AURA_APPLIED#Creature-0-3019-2516-29682-186338-00007D601C#Maruuk#Creature-0-3019-2516-29682-186339-00007D601C#Teera#345561#Life Link#DEBUFF#nil", -- [445]
--"<67.75 20:59:56> [CLEU] SPELL_AURA_APPLIED#Creature-0-3019-2516-29682-186339-00007D601C#Teera#Creature-0-3019-2516-29682-186338-00007D601C#Maruuk#345561#Life Link#DEBUFF#nil", -- [446]
--"<67.90 20:59:56> [CHAT_MSG_MONSTER_YELL] Why has our rest been disturbed?#Teera###Omegal##0#0##0#1387#nil#0#false#false#false#false", -- [447]
--"<88.73 21:00:17> [CHAT_MSG_MONSTER_YELL] Necromancers? On our sacred grounds?#Teera###Gravelord Monkh##0#0##0#1388#nil#0#false#false#false#false", -- [468]
--"<94.47 21:00:23> [CHAT_MSG_MONSTER_YELL] This is what has become of our legacy?#Maruuk###Gravelord Monkh##0#0##0#1389#nil#0#false#false#false#false", -- [473]
--"<95.30 21:00:24> [DBM_Debug] ENCOUNTER_START event fired: 2581 Teera and Maruuk 1 5#nil", -- [474]
function mod:OnSync(msg)
	if msg == "TeeraRP" and self:AntiSpam(10, 9) then--Sync sent from trash mod since trash mod is already monitoring out of combat CLEU events
		timerRP:Start()
	end
end
