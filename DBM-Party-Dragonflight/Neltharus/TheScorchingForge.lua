local mod	= DBM:NewMod(2489, "DBM-Party-Dragonflight", 4, 1199)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260630000000")
mod:SetCreatureID(189478)--Forgemaster Gorek
mod:SetEncounterID(2612)
--mod:SetUsedIcons(1, 2, 3)
mod:SetHotfixNoticeRev(20260714000000)
--mod:SetMinSyncRevision(20260714000000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 374969 374839",
	"SPELL_CAST_SUCCESS 374635 374534",
	"SPELL_AURA_APPLIED 374842 374534",
	"SPELL_AURA_REMOVED 374534 374842"
)

--[[
(ability.id = 374969 or ability.id = 374839) and type = "begincast"
 or (ability.id = 374635 or ability.id = 374534) and type = "cast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
local warnBlazinAegis							= mod:NewTargetNoFilterAnnounce(374842, 3) --Пылающая эгида
local warnHeatedSwings							= mod:NewTargetNoFilterAnnounce(374534, 4) --Разгоряченные удары

local specWarnMightoftheForge					= mod:NewSpecialWarningCount(374635, nil, nil, DBM_COMMON_L.AOEDAMAGE, 2, 2) --Сила кузни
local specWarnBlazinAegis						= mod:NewSpecialWarningMoveAway(374842, nil, nil, nil, 1, 2) --Пылающая эгида
local specWarnHeatedSwings						= mod:NewSpecialWarningDefensive(374534, nil, nil, nil, 3, 2) --Разгоряченные удары
local specWarnHeatedSwings2						= mod:NewSpecialWarningRun(374534, nil, 47482, nil, 4, 4) --Разгоряченные удары (Прыжок)
local specWarnForgestorm						= mod:NewSpecialWarningDodge(374969, nil, nil, DBM_COMMON_L.BOMBING, 2, 2) --Огонь кузни (Обстрел)

--All timers are 30-31 ish
local timerMightoftheForgeCD					= mod:NewNextCountTimer(30, 374635, DBM_COMMON_L.AOEDAMAGE.." (%s)", nil, nil, 2, nil, DBM_COMMON_L.HEALER_ICON, nil, 1, 5) --Сила кузни (АоЕ) Technically Blazing Hammer is healer icon, but it's passive of this stage
local timerBlazinAegisCD						= mod:NewNextCountTimer(30, 374842, nil, nil, nil, 7, nil, nil, nil, 2, 5) --Пылающая эгида
local timerHeatedSwingsCD						= mod:NewNextCountTimer(30.3, 374534, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON) --Разгоряченные удары Tracked by all since it has 8 yard splash damage
local timerForgestormCD							= mod:NewNextCountTimer(28, 374969, DBM_COMMON_L.BOMBING.." (%s)", nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON) --Огонь кузни (Обстрел)

local yellBlazinAegis							= mod:NewYell(374842, nil, nil, nil, "YELL") --Пылающая эгида
local yellBlazinAegisFades						= mod:NewShortFadesYell(374842, nil, nil, nil, "YELL") --Пылающая эгида
local yellHeatedSwings							= mod:NewYell(374534, nil, nil, nil, "YELL") --Разгоряченные удары
local yellHeatedSwingsFades						= mod:NewShortFadesYell(374534, nil, nil, nil, "YELL") --Разгоряченные удары

mod.vb.mightoftheForgeCount = 0
mod.vb.forgestormCount = 0
mod.vb.setCount = 0
mod.vb.heatedSwingsCount = 0

local askShown = false
local allTimers = {
	--Огонь кузни (Обстрел)
	[374969] = {28.9, 28, 28.9},
	--Сила кузни (АоЕ)
	[374635] = {3.4, 30, 32.4, 30},
	--Разгоряченные удары
	[374534] = {19.9, 40.9, 20, 42.4},
}

function mod:OnCombatStart(delay)
	askShown = false
	self.vb.setCount = 0--All timers are 30, so only need one variable that'll increment after each set of all 4 casts
	self.vb.heatedSwingsCount = 0
	self.vb.forgestormCount = 0
	self.vb.mightoftheForgeCount = 0
	timerMightoftheForgeCD:Start(3.4-delay, 1) --
	timerBlazinAegisCD:Start(11.8-delay, 1) --
	timerHeatedSwingsCD:Start(19.9-delay, 1) --
	timerForgestormCD:Start(28.9-delay, 1) --
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 374969 then --Огонь кузни (Обстрел)
		self.vb.forgestormCount = self.vb.forgestormCount + 1
		specWarnForgestorm:Show()
		specWarnForgestorm:Play("watchstep")
		local timer = self:GetFromTimersTable(allTimers, false, false, spellId, self.vb.forgestormCount+1) or 28 --но неточно
		if timer then
			timerForgestormCD:Start(timer, self.vb.forgestormCount+1)
		end
	elseif spellId == 374839 then --Пылающая эгида
		self.vb.setCount = self.vb.setCount + 1
		timerBlazinAegisCD:Start(nil, self.vb.setCount+1)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 374635 then --Сила кузни (АоЕ)
		self.vb.mightoftheForgeCount = self.vb.mightoftheForgeCount + 1
		specWarnMightoftheForge:Show(self.vb.mightoftheForgeCount)
		specWarnMightoftheForge:Play("aesoon")
		local timer = self:GetFromTimersTable(allTimers, false, false, spellId, self.vb.mightoftheForgeCount+1) or 30 --но неточно
		if timer then
			timerMightoftheForgeCD:Start(timer, self.vb.mightoftheForgeCount+1)
		end
--[[	elseif spellId == 374534 then --Сломано и не работает
		timerHeatedSwingsCD:Start(nil, self.vb.setCount+1)]]
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 374842 then
		warnBlazinAegis:CombinedShow(0.3, args.destName)
		if args:IsPlayer() then
			specWarnBlazinAegis:Show()
			specWarnBlazinAegis:Play("scatter")
			yellBlazinAegis:Yell()
			yellBlazinAegisFades:Countdown(spellId)
		end
	elseif spellId == 374534 then --Разгоряченные удары
		self.vb.heatedSwingsCount = self.vb.heatedSwingsCount + 1
		if args:IsPlayer() then
			specWarnHeatedSwings:Show()
			specWarnHeatedSwings:Play("specialsoon")
			specWarnHeatedSwings2:Schedule(3)
			specWarnHeatedSwings2:ScheduleVoice(3, "justrun")
			yellHeatedSwings:Yell()
			yellHeatedSwingsFades:Countdown(spellId)
		else
			warnHeatedSwings:Show(args.destName)
		end
		local timer = self:GetFromTimersTable(allTimers, false, false, spellId, self.vb.heatedSwingsCount+1)
		if timer then
			timerHeatedSwingsCD:Start(timer, self.vb.heatedSwingsCount+1)
		else
			if not askShown then
				askShown = true
				DBM:AddMsg("Данный спелл не имеет таймера, т.к. бой не предусматривался быть настолько долгим.")
			end
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 374534 then
		if args:IsPlayer() then
			yellHeatedSwingsFades:Cancel()
		end
	elseif spellId == 374842 then
		if args:IsPlayer() then
			yellBlazinAegisFades:Cancel()
		end
	end
end
