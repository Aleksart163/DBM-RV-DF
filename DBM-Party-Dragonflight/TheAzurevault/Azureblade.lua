local mod	= DBM:NewMod(2505, "DBM-Party-Dragonflight", 6, 1203)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20231029212301")
mod:SetCreatureID(186739)
mod:SetEncounterID(2585)
mod:SetUsedIcons(8)
mod:SetHotfixNoticeRev(20230103000000)
--mod:SetMinSyncRevision(20211203000000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 372222 385578 384223 373932 384132",
	"SPELL_AURA_REMOVED 384132",
	"UNIT_DIED"
)

--TODO, change arcane orb to personal alert if target scanner works or remove yell if it doesn't
--TODO, verify post hotfix timers for new mana drain rate 03-13-23
--[[
(ability.id = 372222 or ability.id = 385578 or ability.id = 384223 or ability.id = 384132) and type = "begincast"
 or ability.id = 384132 and type = "removebuff"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
--https://www.warcraftlogs.com/reports/1fvXGDK69nmq3MA7#fight=1&pins=2%24Off%24%23244F4B%24expression%24(ability.id%20%3D%20372222%20or%20ability.id%20%3D%20385578%20or%20ability.id%20%3D%20384223%20or%20ability.id%20%3D%20384132)%20and%20type%20%3D%20%22begincast%22%0A%20or%20ability.id%20%3D%20384132%20and%20type%20%3D%20%22removebuff%22%0A%20or%20type%20%3D%20%22dungeonencounterstart%22%20or%20type%20%3D%20%22dungeonencounterend%22&view=events
local warnSummonDraconicImage					= mod:NewSpellAnnounce(384223, 4) --Призыв драконьей иллюзии
local warnOverwhelmingEnergy					= mod:NewEndAnnounce(384132, 1) --Переполняющая энергия
local warnDraconicImageLeft						= mod:NewAnnounce("warnDraconicImage", 2, 384223)

local specWarnUnstableMagic						= mod:NewSpecialWarningDodge(389855, nil, 37859, nil, 2, 4) --Нестабильная магия (Бомбардировка)
local specWarnArcaneCleave						= mod:NewSpecialWarningDefensive(372222, nil, nil, nil, 3, 4) --Удар тайной магии
local specWarnArcaneCleave2						= mod:NewSpecialWarningDodge(372222, "MeleeDps", nil, nil, 2, 2) --Удар тайной магии
local specWarnAncientOrb						= mod:NewSpecialWarningDodge(385578, nil, nil, nil, 2, 2) --Древняя сфера
local specWarnOverwhelmingEnergy				= mod:NewSpecialWarningSpell(384132, nil, nil, nil, 2, 2) --Переполняющая энергия
local specWarnIllusionaryBolt					= mod:NewSpecialWarningInterrupt(373932, "HasInterrupt", nil, nil, 1, 2)

local timerArcaneCleaveCD						= mod:NewCDTimer(13, 372222, nil, "Melee", nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON) --Удар тайной магии
local timerAncientOrbCD							= mod:NewCDTimer(15, 385578, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Древняя сфера
local timerSummonDraconicImageCD				= mod:NewCDTimer(15, 384223, nil, nil, nil, 1, nil, DBM_COMMON_L.DAMAGE_ICON..DBM_COMMON_L.DEADLY_ICON) --Призыв драконьей иллюзии
local timerOverwhelmingenergyCD					= mod:NewCDTimer(35, 384132, nil, nil, nil, 6) --Переполняющая энергия

local yellArcaneCleave							= mod:NewYell(372222, nil, nil, nil, "YELL") --Удар тайной магии

mod:AddSetIconOption("SetIconOnArcaneCleave", 372222, true, 0, {8}) --Удар тайной магии

mod.vb.proshlyapsMurchalCount = 0
mod.vb.proshlyapsMurchalCount2 = 0
mod.vb.ancientOrbCount = 0
mod.vb.wardens = 4

local Proshlyap = nil
local Perephase = nil
local allProshlyapationsOfMurchal = {
	--Удар тайной магии
	[372222] = {8, 13, 15, 15},
	--Призыв драконьей иллюзии
	[384223] = {5, 15, 15, 15},
}

function mod:ArcaneCleaveTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnArcaneCleave:Show()
		specWarnArcaneCleave:Play("defensive")
		yellArcaneCleave:Yell()
	else
		specWarnArcaneCleave2:Show()
		specWarnArcaneCleave2:Play("watchstep")
	end
	if self.Options.SetIconOnArcaneCleave then
		self:SetIcon(targetname, 8, 3)
	end
end

function mod:OnCombatStart(delay)
	self.vb.proshlyapsMurchalCount = 0
	self.vb.proshlyapsMurchalCount2 = 0
	self.vb.ancientOrbCount = 0
	self.vb.wardens = 0
	Proshlyap = false
	Perephase = false
	timerAncientOrbCD:Start(11.5-delay)
	timerOverwhelmingenergyCD:Start(32-delay)
	timerArcaneCleaveCD:Start(6-delay)
	timerSummonDraconicImageCD:Start(3-delay)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 372222 then --Удар тайной магии
		self.vb.proshlyapsMurchalCount = self.vb.proshlyapsMurchalCount + 1
		if not Proshlyap and self.vb.proshlyapsMurchalCount < 2 then
			timerArcaneCleaveCD:Start(nil, self.vb.proshlyapsMurchalCount+1)
		elseif Proshlyap then
			local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.proshlyapsMurchalCount+1)
			if timer then
				timerArcaneCleaveCD:Start(timer, self.vb.proshlyapsMurchalCount+1)
			end
		end
		self:BossTargetScanner(args.sourceGUID, "ArcaneCleaveTarget", 0.1, 2)
	elseif spellId == 385578 then --Древняя сфера
		self.vb.ancientOrbCount = self.vb.ancientOrbCount + 1
		if not Proshlyap and self.vb.ancientOrbCount < 2 then
			timerAncientOrbCD:Start()
		elseif Proshlyap and self.vb.ancientOrbCount < 4 then
			timerAncientOrbCD:Start()
		end
		specWarnAncientOrb:Show()
		specWarnAncientOrb:Play("watchorb")
	elseif spellId == 384223 then --Призыв драконьей иллюзии
		self.vb.proshlyapsMurchalCount2 = self.vb.proshlyapsMurchalCount2 + 1
		if not Proshlyap and self.vb.proshlyapsMurchalCount2 < 2 then
			timerSummonDraconicImageCD:Start(nil, self.vb.proshlyapsMurchalCount2+1)
		elseif Proshlyap then
			local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.proshlyapsMurchalCount2+1)
			if timer then
				timerSummonDraconicImageCD:Start(timer, self.vb.proshlyapsMurchalCount2+1)
			end
		end
		warnSummonDraconicImage:Show()
	elseif spellId == 373932 and self:CheckInterruptFilter(args.sourceGUID, false, true) then
		specWarnIllusionaryBolt:Show(args.sourceName)
		specWarnIllusionaryBolt:Play("kickcast")
	elseif spellId == 384132 then --Переполняющая энергия
		Perephase = true
		if not Proshlyap then
			Proshlyap = true
		end
		specWarnOverwhelmingEnergy:Show()
		specWarnOverwhelmingEnergy:Play("phasechange")
		self.vb.proshlyapsMurchalCount = 0
		self.vb.proshlyapsMurchalCount2 = 0
		self.vb.ancientOrbCount = 0
		self.vb.wardens = 4
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 384132 then --Переполняющая энергия
		self.vb.wardens = 0
		Perephase = false
		warnOverwhelmingEnergy:Show()
		timerAncientOrbCD:Start(13.5)--12-13
		timerOverwhelmingenergyCD:Start(64)
		timerArcaneCleaveCD:Start(8)
		timerSummonDraconicImageCD:Start(5)
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 192955 then
		self.vb.wardens = self.vb.wardens - 1
		if Perephase then
			if self:AntiSpam(2, "UnstableMagic") then
				specWarnUnstableMagic:Show()
				specWarnUnstableMagic:Play("watchstep")
			end
			warnDraconicImageLeft:Schedule(2, self.vb.wardens)
		end
	end
end
