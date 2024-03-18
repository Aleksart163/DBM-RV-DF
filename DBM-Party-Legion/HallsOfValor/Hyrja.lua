local mod	= DBM:NewMod(1486, "DBM-Party-Legion", 4, 721)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20230504231118")
mod:SetCreatureID(95833)
mod:SetEncounterID(1806)
mod:SetUsedIcons(8)
mod:SetHotfixNoticeRev(20230308000000)

mod:RegisterCombat("combat")
--mod:SetWipeTime(120)--Restore in classic legion, if that ever happens
--mod.sendMainBossGUID = true--Boss does lots of on fly timer adjustments, lets not overwhelm external handlers just yet

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 192018 192307 200901",
	"SPELL_CAST_SUCCESS 192044 200901",
	"SPELL_AURA_APPLIED 192048 192133 192132 192133 192132",
	"SPELL_AURA_APPLIED_DOSE 192133 192132",
	"SPELL_AURA_REMOVED 192048"
--	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

--Notes: expel light could be supported with AGGRESSIVE timer correction around spell queuing and ability turning on and off, it's just not worth effort
--LW does some hacky things with it but not even their hack checks out with all logs. They're missing the shield of light spell queue which sets min time to 6sec
--Again though, too much effort, blizzard should just fix the bad design instead
--["192044-Expel Light"] = "pull:79.7, 26.6, 30.3, 24.3, 30.3",
--Maybe add a searing light interrupt helper if it matters enough on mythic+
--[[
(ability.id = 192158 or ability.id = 192307 or ability.id = 192018 or ability.id = 200901 or ability.id = 192288) and type = "begincast"
 or (ability.id = 192132 or ability.id = 192133) and (type = "applydebuff" or type = "removedebuff")
 or ability.id = 192044 and type = "cast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
local warnMysticEmpowermentHoly		= mod:NewStackAnnounce(192133, 4, nil, nil, 2) --Мистическое усиление: Свет
local warnMysticEmpowermentThunder	= mod:NewStackAnnounce(192132, 4, nil, nil, 2) --Мистическое усиление: гром
local warnExpelLight				= mod:NewTargetAnnounce(192048, 3)

local specWarnShieldOfLight			= mod:NewSpecialWarningDefensive(192018, nil, nil, nil, 3, 4) --Щит света
local specWarnShieldOfLight2		= mod:NewSpecialWarningTarget(192018, nil, nil, nil, 2, 2) --Щит света
local specWarnSanctify				= mod:NewSpecialWarningDodge(192307, nil, nil, nil, 2, 5)
local specWarnEyeofStorm			= mod:NewSpecialWarningMoveTo(200901, nil, nil, nil, 2, 2)
local specWarnEyeofStorm2			= mod:NewSpecialWarningDefensive(200901, nil, nil, nil, 3, 2)
local specWarnExpelLight			= mod:NewSpecialWarningMoveAway(192048, nil, nil, nil, 2, 2)

local timerShieldOfLightCD			= mod:NewCDTimer(26.6, 192018, nil, nil, nil, 3, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON, nil, 3, 5)--26.6-34
local timerSpecialCD				= mod:NewNextTimer(30, 200736, nil, nil, nil, 7, 143497, DBM_COMMON_L.DEADLY_ICON, nil, 3, 5)--Shared timer by eye of storm and Sanctify
local timerExpelLightCD				= mod:NewCDTimer(23, 192048, nil, nil, nil, 3)--May be lower but almost always delayed by spell queue ICDs

local yellShieldOfLight				= mod:NewShortYell(192018, nil, nil, nil, "YELL") --Щит света
local yellExpelLight				= mod:NewShortYell(192048, nil, nil, nil, "YELL")

mod:AddSetIconOption("SetIconOnShieldOfLight", 192018, true, 0, {8})

mod:AddRangeFrameOption(8, 192048)

local eyeShortName = DBM:GetSpellInfo(91320)--Inner Eye

function mod:ShieldOfLightTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnShieldOfLight:Show()
		specWarnShieldOfLight:Play("defensive")
		yellShieldOfLight:Yell()
	else
		specWarnShieldOfLight2:Show(targetname)
		specWarnShieldOfLight2:Play("watchfeet")
	end
	if self.Options.SetIconOnShieldOfLight then
		self:SetIcon(targetname, 8, 5)
	end
end

local function updateExpelLightTimers(self, ICD)
	DBM:Debug("updateExpelLightTimers running", 3)
	if timerExpelLightCD:GetRemaining() < ICD then
		local elapsed, total = timerExpelLightCD:GetTime()
		local extend = ICD - (total-elapsed)
		DBM:Debug("timerExpelLightCD extended by: "..extend, 2)
		timerExpelLightCD:Update(elapsed, total+extend)
	end
end

local function updateMurchalProshlyapsTimers(self, ICD)
	DBM:Debug("updateMurchalProshlyapsTimers running", 3)
	if timerShieldOfLightCD:GetRemaining() < ICD then
		local elapsed, total = timerShieldOfLightCD:GetTime()
		local extend = ICD - (total-elapsed)
		DBM:Debug("timerShieldOfLightCD extended by: "..extend, 2)
		timerShieldOfLightCD:Update(elapsed, total+extend)
	end
end

function mod:OnCombatStart(delay)
	timerSpecialCD:Start(8.5)
	timerShieldOfLightCD:Start(24)
	timerExpelLightCD:Start(32.5)
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 192307 then --Освящение
		specWarnSanctify:Show()
		specWarnSanctify:Play("watchorb")
		timerSpecialCD:Start()
		updateMurchalProshlyapsTimers(self, 12.8)
		updateExpelLightTimers(self, 15.5)
	elseif spellId == 192018 then --Щит света
		self:BossTargetScanner(args.sourceGUID, "ShieldOfLightTarget", 0.1, 2)
		timerShieldOfLightCD:Start()
		updateMurchalProshlyapsTimers(self, 6)
	elseif spellId == 200901 and args:GetSrcCreatureID() == 95833 then --Око шторма
		if self:AntiSpam(2, "EyeofStorm") then
			specWarnEyeofStorm:Show(eyeShortName)
			specWarnEyeofStorm:Play("findshelter")
		end
		timerSpecialCD:Start()
		updateMurchalProshlyapsTimers(self, 13)
		updateExpelLightTimers(self, 15.5)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 192044 then
		timerExpelLightCD:Start()
		updateExpelLightTimers(self, 3.6)
	elseif spellId == 200901 then
		specWarnEyeofStorm2:Show()
		specWarnEyeofStorm2:Play("defensive")
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 192048 then
		if args:IsPlayer() then
			specWarnExpelLight:Show()
			specWarnExpelLight:Play("runout")
			yellExpelLight:Yell()
			if self.Options.RangeFrame then
				DBM.RangeCheck:Hide()
			end
		else
			warnExpelLight:Show(args.destName)
		end
	elseif spellId == 192133 then --Мистическое усиление: Свет
		local amount = args.amount or 1
		if amount >= 4 and amount % 2 == 0 then
			warnMysticEmpowermentHoly:Show(args.destName, amount)
		end
	elseif spellId == 192132 then --Мистическое усиление: гром
		local amount = args.amount or 1
		if amount >= 4 and amount % 2 == 0 then
			warnMysticEmpowermentThunder:Show(args.destName, amount)
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 192048 and args:IsPlayer() and self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end
