local mod	= DBM:NewMod(2507, "DBM-Party-Dragonflight", 8, 1204)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240429063816")
mod:SetCreatureID(189722)
mod:SetEncounterID(2616)
mod:SetHotfixNoticeRev(20230507000000)
--mod:SetMinSyncRevision(20211203000000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 385551 385181 385531 385442",
	"SPELL_AURA_APPLIED 385743 374389 374610",
	"SPELL_AURA_APPLIED_DOSE 385743 374389",
	"SPELL_AURA_REMOVED 374389",
	"SPELL_AURA_REMOVED_DOSE 374389",
	"UNIT_AURA player"
)

--[[
(ability.id = 385551 or ability.id = 385181 or ability.id = 385531 or ability.id = 385442) and type = "begincast"
 or ability.id = 385743
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
 or (source.type = "NPC" and source.firstSeen = timestamp) or (target.type = "NPC" and target.firstSeen = timestamp)
--]]
--TODO, actually detect gulp target or is it no one specific?
local warnHangry								= mod:NewSpellAnnounce(385743, 2, nil, "Tank|Healer") --Золоден
--local warnBodySlam								= mod:NewTargetNoFilterAnnounce(385531, 3) --Удар пузом
local warnBodySlam								= mod:NewCastAnnounce(385531, 4) --Удар пузом
local warnToxicEff								= mod:NewCountAnnounce(385442, 3) --Токсичные испарения

local specWarnFixate							= mod:NewSpecialWarningRun(374610, nil, 96306, nil, 4, 2) --Преследование
local specWarnGulpSwogToxin						= mod:NewSpecialWarningStack(374389, nil, 2, nil, nil, 1, 6)
local specWarnGulp								= mod:NewSpecialWarningDodgeCount(385551, nil, nil, nil, 2, 2) --Заглатывание
local specWarnGulp2								= mod:NewSpecialWarningMoveTo(385551, "Tank", nil, nil, 3, 4) --Заглатывание
local specWarnHangry							= mod:NewSpecialWarningDispel(385743, "RemoveEnrage", nil, nil, 1, 2) --Золоден
local specWarnOverpoweringCroak					= mod:NewSpecialWarningDodgeCount(385187, nil, nil, nil, 2, 2)--385181 is cast but lacks tooltip, so damage Id used for tooltip/option
--local specWarnBodySlam							= mod:NewSpecialWarningMoveAway(385531, nil, nil, nil, 1, 2) --Удар пузом
local specWarnBodySlam							= mod:NewSpecialWarningDodge(385531, nil, nil, nil, 2, 2) --Удар пузом

local timerGulpCD								= mod:NewCDCountTimer(38.8, 385551, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Заглатывание
local timerOverpoweringCroakCD					= mod:NewCDCountTimer(37.7, 385187, nil, nil, nil, 2, nil, DBM_COMMON_L.DAMAGE_ICON..DBM_COMMON_L.HEALER_ICON) --Подавляющее кваканье
local timerBellySlamCD							= mod:NewCDTimer(37.7, 385531, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Удар пузом
local timerToxicEffluviaaCD						= mod:NewCDCountTimer(26.7, 385442, nil, nil, nil, 5, nil, DBM_COMMON_L.HEALER_ICON) --Токсичные испарения

local yellBodySlam								= mod:NewYell(385531, nil, nil, nil, "YELL") --Удар пузом

mod:AddRangeFrameOption(12, 385531)
mod:AddInfoFrameOption(374389, "RemovePoison")

local Proshlyap = false
local toxinStacks = {}

mod.vb.gulpCount = 0
mod.vb.croakCount = 0
mod.vb.toxicCount = 0

--[[
function mod:BodySlamTarget(targetname)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnBodySlam:Show()
		specWarnBodySlam:Play("runout")
		yellBodySlam:Yell()
	else
		warnBodySlam:Show(targetname)
	end
end]]

function mod:OnCombatStart(delay)
	table.wipe(toxinStacks)
	self.vb.gulpCount = 0
	self.vb.croakCount = 0
	self.vb.toxicCount = 0
	Proshlyap = false
	timerOverpoweringCroakCD:Start(8-delay, 1)
	timerGulpCD:Start(17.8-delay, 1)
	timerToxicEffluviaaCD:Start(29.9-delay, 1)
	timerBellySlamCD:Start(38.4-delay)
	if self.Options.InfoFrame then
		DBM.InfoFrame:SetHeader(DBM:GetSpellName(374389))
		DBM.InfoFrame:Show(5, "table", toxinStacks, 1)
	end
	if self.Options.RangeFrame then
		DBM.RangeCheck:Show(12)
	end
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 385551 then --Заглатывание
		self.vb.gulpCount = self.vb.gulpCount + 1
		if self:IsTank() then
			if not Proshlyap then
				specWarnGulp2:Show(CL.BOSS)
				specWarnGulp2:Play("movetoboss")
			else
				specWarnGulp:Show(self.vb.gulpCount)
				specWarnGulp:Play("watchstep")
			end
		else
			specWarnGulp:Show(self.vb.gulpCount)
			specWarnGulp:Play("watchstep")
		end
		timerGulpCD:Start(self.vb.gulpCount == 1 and 47.1 or 37.6, self.vb.gulpCount+1)
	elseif spellId == 385181 then
		self.vb.croakCount = self.vb.croakCount + 1
		specWarnOverpoweringCroak:Show(self.vb.croakCount)
		specWarnOverpoweringCroak:Play("aesoon")
		specWarnOverpoweringCroak:ScheduleVoice(2, "watchstep")
		timerOverpoweringCroakCD:Start(nil, self.vb.croakCount+1)
	elseif spellId == 385531 then --Удар пузом
	--	self:ScheduleMethod(0.1, "BossTargetScanner", args.sourceGUID, "BodySlamTarget", 0.1, 6, true)
		warnBodySlam:Show()
		specWarnBodySlam:Show()
		specWarnBodySlam:Play("watchstep")
		timerBellySlamCD:Start()
	elseif spellId == 385442 then
		self.vb.toxicCount = self.vb.toxicCount + 1
		warnToxicEff:Show(self.vb.toxicCount)
		timerToxicEffluviaaCD:Start(nil, self.vb.toxicCount+1)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 385743 then
		if self.Options.SpecWarn385743dispel then
			specWarnHangry:Show(args.destName)
			specWarnHangry:Play("enrage")
		else
			warnHangry:Show()
		end
	elseif spellId == 374389 then --Токсин рогоплава
		local amount = args.amount or 1
		toxinStacks[args.destName] = amount
		if self.Options.InfoFrame then
			DBM.InfoFrame:UpdateTable(toxinStacks)
		end
		if args:IsPlayer() and amount >= 2 and amount % 2 == 0 then
			specWarnGulpSwogToxin:Show(amount)
			specWarnGulpSwogToxin:Play("stackhigh")
		elseif args:IsPlayer() and amount >= 6 then
			Proshlyap = true
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 374389 then --Токсин рогоплава
		if args:IsPlayer() then
			Proshlyap = false
		end
		toxinStacks[args.destName] = nil
		if self.Options.InfoFrame then
			DBM.InfoFrame:UpdateTable(toxinStacks)
		end
	end
end

function mod:SPELL_AURA_REMOVED_DOSE(args)
	local spellId = args.spellId
	if spellId == 374389 then
		toxinStacks[args.destName] = args.amount or 1
		if self.Options.InfoFrame then
			DBM.InfoFrame:UpdateTable(toxinStacks)
		end
	end
end

do
	local warnedFixate = false
	function mod:UNIT_AURA(uId)
		local hasFixate = DBM:UnitDebuff("player", 374610)
		if hasFixate and not warnedFixate and self:AntiSpam(2, "Fixate") then
			warnedFixate = true
			specWarnFixate:Show()
			specWarnFixate:Play("justrun")
		elseif not hasFixate and warnedFixate then
			warnedFixate = false
		end
	end
end
