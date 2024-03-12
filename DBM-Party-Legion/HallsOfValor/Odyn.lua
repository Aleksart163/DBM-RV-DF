local mod	= DBM:NewMod(1489, "DBM-Party-Legion", 4, 721)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20230504231118")
mod:SetCreatureID(95676)
mod:SetEncounterID(1809)
mod:SetHotfixNoticeRev(20230306000000)
mod:SetMinSyncRevision(20221228000000)
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 198263 198077 198750",
	"SPELL_CAST_SUCCESS 197961",
	"SPELL_AURA_APPLIED 197963 197964 197965 197966 197967",
	"SPELL_AURA_REMOVED 197963 197964 197965 197966 197967",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)
mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL"
)

--http://legion.wowhead.com/icons/name:boss_odunrunes_
--["198263-Radiant Tempest"] = "pull:8.0, 72.0, 40.0", huh?
--[[
(ability.id = 198072 or ability.id = 198263 or ability.id = 198077) and type = "begincast"
 or ability.id = 197961 and type = "cast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
 or ability.id = 198750 and type = "begincast"
--]]
--TODO, does boss still have old random tempest timers system from legion or are 10.0.2 changes universal?
local warnTempest					= mod:NewCastAnnounce(198263, 4)

local specWarnSpear					= mod:NewSpecialWarningDodge(198072, nil, nil, nil, 2, 2) --Копье света
local specWarnTempest				= mod:NewSpecialWarningRun(198263, nil, nil, nil, 4, 2) --Светозарная буря
local specWarnShatterSpears			= mod:NewSpecialWarningDodge(198077, nil, nil, nil, 2, 2)
local specWarnRunicBrand			= mod:NewSpecialWarningMoveTo(197963, nil, nil, nil, 4, 6)
local specWarnRunicBrand2			= mod:NewSpecialWarningMoveTo(197964, nil, nil, nil, 4, 6)
local specWarnRunicBrand3			= mod:NewSpecialWarningMoveTo(197965, nil, nil, nil, 4, 6)
local specWarnRunicBrand4			= mod:NewSpecialWarningMoveTo(197966, nil, nil, nil, 4, 6)
local specWarnRunicBrand5			= mod:NewSpecialWarningMoveTo(197967, nil, nil, nil, 4, 6)
local specWarnAdd					= mod:NewSpecialWarningSwitch(201215, "-Healer", 245546, nil, 1, 2) --Призыв закаленного бурей воина
local specWarnSurge					= mod:NewSpecialWarningInterrupt(198750, "HasInterrupt", nil, nil, 3, 2) --Импульс

local timerSpearCD					= mod:NewCDTimer(8, 198072, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Копье света
local timerTempestCD				= mod:NewCDTimer(56, 198263, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON, nil, 3, 5) --Светозарная буря
local timerTempest					= mod:NewCastTimer(7, 198263, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON, nil, 3, 5) --Светозарная буря
local timerShatterSpearsCD			= mod:NewCDTimer(56, 198077, nil, nil, nil, 2)
local timerRunicBrandCD				= mod:NewCDCountTimer(56, 197961, nil, nil, nil, 7, nil, nil, nil, 3, 5)
local timerRunicBrand				= mod:NewCastTimer(12, 197961, nil, nil, nil, 7, nil, nil, nil, 3, 5)
local timerAddCD					= mod:NewCDTimer(54, 201215, 245546, nil, nil, 1, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DAMAGE_ICON) --Призыв закаленного бурей воина

mod:AddMiscLine(DBM_CORE_L.OPTION_CATEGORY_DROPDOWNS)
mod:AddDropdownOption("RuneBehavior", {"Icon", "Entrance", "Minimap", "Generic"}, "Generic", "misc")

local FirstProshlyap = nil
local MurchalProshlyapationTimers1 = {8, 8}
local MurchalProshlyapationTimers2 = {12, 28, 8}
--Boss has (at least) three timer modes, cannot determine which one on pull so on fly figuring out is used
local oldTempestTimers = {
	[1] = {8, 56, 72},
	[2] = {16, 48, 64},--If such a beast exists, it'll look like this based on theory. This sequence is COPMLETE guesswork
	[3] = {24, 40, 56},
	[4] = {32, 32, 48},--32 and 48 are guessed based on theory
}
--local oldbrandTimers = {44, 56}
mod.vb.temptestMode = 1
mod.vb.tempestCount = 0
mod.vb.brandCount = 0
mod.vb.ochkenShlyapenCount = 0

--Should run at 10, 18, 26, and 34
--[[
local function tempestDelayed(self)
	if self.vb.tempestCount == 0 then
		DBM:AddMsg(L.tempestModeMessage:format(self.vb.temptestMode))
		self.vb.temptestMode = self.vb.temptestMode + 1
		self:Schedule(8, tempestDelayed, self)
		timerTempestCD:Start(6, 1)
	else
		return
	end
end]]

local function startProshlyapationOfMurchal(self) -- Proshlyapation of Murchal
	self.vb.ochkenShlyapenCount = self.vb.ochkenShlyapenCount + 1
	specWarnSpear:Show()
	specWarnSpear:Play("watchstep")
	if FirstProshlyap then -- при первом прошляпе Мурчаля
		local proshlyap2 = MurchalProshlyapationTimers2[self.vb.ochkenShlyapenCount+1]
		if proshlyap2 then
			timerSpearCD:Start(proshlyap2, self.vb.ochkenShlyapenCount+1)
			self:Schedule(proshlyap2, startProshlyapationOfMurchal, self)
		end
	else --при пулле босса
		local proshlyap1 = MurchalProshlyapationTimers1[self.vb.ochkenShlyapenCount+1]
		if proshlyap1 then
			timerSpearCD:Start(proshlyap1, self.vb.ochkenShlyapenCount+1)
			self:Schedule(proshlyap1, startProshlyapationOfMurchal, self)
		end
	end
end

local function startProshlyapationOfMurchal2(self) -- Proshlyapation of Murchal2
	specWarnAdd:Show()
	specWarnSpear:Play("mobkill")
end

function mod:OnCombatStart(delay)
	self.vb.temptestMode = 1
	self.vb.tempestCount = 0
	self.vb.brandCount = 0
	self.vb.ochkenShlyapenCount = 0
	FirstProshlyap = false
	timerTempestCD:Start(24-delay) --Светозарная буря
	timerShatterSpearsCD:Start(40-delay)
	timerRunicBrandCD:Start(45.9-delay, 1)
--	specWarnAdd:Schedule(19-delay) --Призыв закаленного бурей воина
--	specWarnAdd:ScheduleVoice(19-delay, "mobkill") --Призыв закаленного бурей воина
	self:Schedule(8, startProshlyapationOfMurchal, self)
	timerSpearCD:Start(8-delay, 1)
	self:Schedule(19, startProshlyapationOfMurchal2, self)
	timerAddCD:Start(19-delay) --Призыв закаленного бурей воина
end

function mod:OnCombatEnd()
	self:Unschedule(startProshlyapationOfMurchal)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 198263 then --Светозарная буря
		self.vb.tempestCount = self.vb.tempestCount + 1
		self.vb.ochkenShlyapenCount = 0
		self:Unschedule(startProshlyapationOfMurchal)
		warnTempest:Show()
		if not FirstProshlyap then
			FirstProshlyap = true
		end
		specWarnTempest:Show()
		specWarnTempest:Play("runout")
		timerTempestCD:Start()
		timerTempest:Start()
--[[		if self:IsMythic() then
			timerAddCD:Start(51)
			specWarnAdd:Schedule(51)
			specWarnAdd:ScheduleVoice(51, "mobkill")
		end]]
		self:Schedule(12, startProshlyapationOfMurchal, self)
		timerSpearCD:Start(12, 1)
		self:Schedule(51, startProshlyapationOfMurchal2, self)
		timerAddCD:Start(51)
	elseif spellId == 198077 then
		specWarnShatterSpears:Show()
		specWarnShatterSpears:Play("watchorb")
		timerShatterSpearsCD:Start()
	elseif spellId == 198750 then
		specWarnSurge:Show(args.sourceName)
		specWarnSurge:Play("kickcast")
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 197961 then
		self.vb.brandCount = self.vb.brandCount + 1
--		timerSpearCD:Start(18)
		local nextCount = self.vb.brandCount+1
--		local timer = brandTimers[nextCount]
--		if timer then
			timerRunicBrandCD:Start(nil, nextCount)
--		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 197963 and args:IsPlayer() then--Purple K (NE)
		specWarnRunicBrand:Show("|TInterface\\Icons\\Boss_OdunRunes_Purple.blp:12:12|t")
		if self.Options.RuneBehavior == "Entrance" then
			specWarnRunicBrand:Play("frontleft")
		elseif self.Options.RuneBehavior == "Icon" then
			specWarnRunicBrand:Play("mm3")--Purple Diamond
		elseif self.Options.RuneBehavior == "Minimap" then
			specWarnRunicBrand:Play("frontright")
		else
			specWarnRunicBrand:Play("targetyou")
		end
		timerRunicBrand:Start()
	elseif spellId == 197964 and args:IsPlayer() then--Orange N (SE)
		specWarnRunicBrand2:Show("|TInterface\\Icons\\Boss_OdunRunes_Orange.blp:12:12|t")
		if self.Options.RuneBehavior == "Entrance" then
			specWarnRunicBrand2:Play("backleft")
		elseif self.Options.RuneBehavior == "Icon" then
			specWarnRunicBrand2:Play("mm2")--Orange Circle
		elseif self.Options.RuneBehavior == "Minimap" then
			specWarnRunicBrand2:Play("backright")
		else
			specWarnRunicBrand2:Play("targetyou")
		end
		timerRunicBrand:Start()
	elseif spellId == 197965 and args:IsPlayer() then--Yellow H (SW)
		specWarnRunicBrand3:Show("|TInterface\\Icons\\Boss_OdunRunes_Yellow.blp:12:12|t")
		if self.Options.RuneBehavior == "Entrance" then
			specWarnRunicBrand3:Play("backright")
		elseif self.Options.RuneBehavior == "Icon" then
			specWarnRunicBrand3:Play("mm1")--Yellow Star
		elseif self.Options.RuneBehavior == "Minimap" then
			specWarnRunicBrand3:Play("backleft")
		else
			specWarnRunicBrand3:Play("targetyou")
		end
		timerRunicBrand:Start()
	elseif spellId == 197966 and args:IsPlayer() then--Blue fishies (NW)
		specWarnRunicBrand4:Show("|TInterface\\Icons\\Boss_OdunRunes_Blue.blp:12:12|t")
		if self.Options.RuneBehavior == "Entrance" then
			specWarnRunicBrand4:Play("frontright")
		elseif self.Options.RuneBehavior == "Icon" then
			specWarnRunicBrand4:Play("mm6")--Blue Square
		elseif self.Options.RuneBehavior == "Minimap" then
			specWarnRunicBrand4:Play("frontleft")
		else
			specWarnRunicBrand4:Play("targetyou")
		end
		timerRunicBrand:Start()
	elseif spellId == 197967 and args:IsPlayer() then--Green box (N)
		specWarnRunicBrand5:Show("|TInterface\\Icons\\Boss_OdunRunes_Green.blp:12:12|t")
		if self.Options.RuneBehavior == "Entrance" then
			specWarnRunicBrand5:Play("frontcenter")
		elseif self.Options.RuneBehavior == "Icon" then
			specWarnRunicBrand5:Play("mm4")--Green Triangle
		elseif self.Options.RuneBehavior == "Minimap" then
			specWarnRunicBrand5:Play("frontcenter")
		else
			specWarnRunicBrand5:Play("targetyou")
		end
		timerRunicBrand:Start()
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 197963 and args:IsPlayer() then--Purple K (NE)
		timerRunicBrand:Cancel()
	elseif spellId == 197964 and args:IsPlayer() then--Orange N (SE)
		timerRunicBrand:Cancel()
	elseif spellId == 197965 and args:IsPlayer() then--Yellow H (SW)
		timerRunicBrand:Cancel()
	elseif spellId == 197966 and args:IsPlayer() then--Blue fishies (NW)
		timerRunicBrand:Cancel()
	elseif spellId == 197967 and args:IsPlayer() then--Green box (N)
		timerRunicBrand:Cancel()
	end
end

--[[
function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, spellId)
	if spellId == 201221 then--Summon Stormforged
		specWarnAdd:Show()
		specWarnAdd:Play("killmob")
		timerAddCD:Start()
	end
end]]

--"<1368.18 21:44:20> [CHAT_MSG_MONSTER_YELL] Most impressive! I never thought I would meet anyone who could match the Valarjar's strength... and yet here you stand.#Odyn###Odyn##0#0##0#1600#nil#0#false#false#false#false", -- [6314]
--About 3 seconds to trigger gossip, since RP is for when gossip becomes available
--"<1399.95 21:44:52> [DBM_Debug] StartCombat called by : ENCOUNTER_START. LastInstanceMapID is 1477#nil", -- [6329]
--[[
function mod:CHAT_MSG_MONSTER_YELL(msg)
	if (msg == L.OdynRP or msg:find(L.OdynRP)) then
		self:SendSync("OdynRP")--Syncing to help unlocalized clients
	end
end

function mod:OnSync(msg, targetname)
	if msg == "OdynRP" and self:AntiSpam(10, 2) then
	--	timerRP:Start()
	end
end
]]
