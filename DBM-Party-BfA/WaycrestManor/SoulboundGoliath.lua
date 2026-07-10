local mod	= DBM:NewMod(2126, "DBM-Party-BfA", 10, 1021)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260630000000")
mod:SetCreatureID(260551)
mod:SetEncounterID(2114)
mod:SetHotfixNoticeRev(20260715000000)
mod:SetMinSyncRevision(20260715000000)
mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 260508",
	"SPELL_CAST_SUCCESS 260551 260508",
	"SPELL_AURA_APPLIED 267907 260541 260569 260512",
	"SPELL_AURA_APPLIED_DOSE 260512",
	"SPELL_SUMMON 267907",
	"RAID_BOSS_WHISPER"
)

--[[
ability.id = 260508 and type = "begincast"
 or ability.id = 260551 and type = "cast"
 or ability.id = 260541
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
 --]]
--TODO, maybe readd stack counting instead of relying on blizzards emote for moving boss into fire
local warnSoulHarvestStack			= mod:NewCountAnnounce(260512, 3, nil, nil, DBM_CORE_L.AUTO_ANNOUNCE_OPTIONS.stack:format(260512)) --Жатва душ

local specWarnBurningBush			= mod:NewSpecialWarningCount(260541, nil, nil, DBM_COMMON_L.AOEDAMAGE, 3, 2) --Горящий хворост
local specWarnCrush					= mod:NewSpecialWarningDefensive(260508, nil, nil, nil, 3, 2) --Сокрушение
local specWarnThorns				= mod:NewSpecialWarningSwitch(267907, "Dps", nil, nil, 3, 2) --Шипы души
local specWarnSoulHarvest			= mod:NewSpecialWarningMoveTo(260512, "Tank", nil, nil, 3, 2) --Жатва душ
local specWarnGTFO					= mod:NewSpecialWarningGTFO(260569, nil, nil, nil, 1, 8) --Дикий огонь

local yellThorns					= mod:NewYell(267907, nil, nil, nil, "YELL") --Шипы души

--Timers subject to delays if boss gets stunned by fire
local timerCrushCD					= mod:NewCDCountTimer(15, 260508, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON) --Сокрушение 15 after last cast FINISHES
local timerThornsCD					= mod:NewCDCountTimer(21.8, 267907, nil, nil, nil, 3, nil, DBM_COMMON_L.DAMAGE_ICON..DBM_COMMON_L.HEALER_ICON) --Шипы души

mod:AddSetIconOption("SetIconOnThorns", 267907, true, 5, {8}) --Шипы души

mod.vb.burningBushCount = 0
mod.vb.crushCount = 0
mod.vb.thornsCount = 0

local wildfire = DBM:GetSpellName(260569) --Дикий огонь
local hightStacks = false

function mod:OnCombatStart(delay)
	hightStacks = false
	self.vb.burningBushCount = 0
	self.vb.crushCount = 0
	self.vb.thornsCount = 0
	timerCrushCD:Start(5.7-delay, 1)
	timerThornsCD:Start(8.1-delay, 1)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 260508 then
		if self:IsTanking("player", "boss1", nil, true) and hightStacks then
			specWarnCrush:Show()
			specWarnCrush:Play("defensive")
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 260551 then
		self.vb.thornsCount = self.vb.thornsCount + 1
		timerThornsCD:Start(nil, self.vb.thornsCount+1)
	elseif spellId == 260508 then--Can stutter cast, so we only want to increment count and start timer on a successful one
		self.vb.crushCount = self.vb.crushCount + 1
		timerCrushCD:Start(15, self.vb.crushCount+1)
	end
end

function mod:SPELL_SUMMON(args)
	local spellId = args.spellId
	if spellId == 267907 then
		if self.Options.SetIconOnThorns then
			self:ScanForMobs(args.destGUID, 2, 8, 1, nil, 12, "SetIconOnThorns")
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 267907 then
		if args:IsPlayer() then
			yellThorns:Yell()
		else
			specWarnThorns:Show()--+1 because event is lagged behind timer event
			specWarnThorns:Play("targetchange")
		end
	elseif spellId == 260541 and not args:IsDestTypePlayer() then --Горящий хворост
		self.vb.burningBushCount = self.vb.burningBushCount + 1
		specWarnBurningBush:Show(self.vb.burningBushCount)
		specWarnBurningBush:Play("defensive")
	elseif spellId == 260569 and args:IsPlayer() and self:AntiSpam(3, 1) then
		specWarnGTFO:Show(args.spellName)
		specWarnGTFO:Play("watchfeet")
	elseif spellId == 260512 then --Жатва душ
		local amount = args.amount or 1
		if amount > 10 then
			if not hightStacks then
				hightStacks = true
			end
		elseif amount < 10 then
			if hightStacks then
				hightStacks = false
			end
		elseif amount >= 5 and amount % 5 == 0 then
			warnSoulHarvestStack:Show(amount)
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:RAID_BOSS_WHISPER(msg)
	if msg:find("260512") then
		specWarnSoulHarvest:Show(wildfire)
		specWarnSoulHarvest:Play("moveboss")
	end
end
