local mod	= DBM:NewMod(2488, "DBM-Party-Dragonflight", 7, 1202)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240504141048")
mod:SetCreatureID(188252)
mod:SetEncounterID(2609)
mod:SetHotfixNoticeRev(20221126000000)
--mod:SetMinSyncRevision(20211203000000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 372851 396044 373046",
	"SPELL_AURA_APPLIED 372682 373022 372988 373680 385518",
	"SPELL_AURA_APPLIED_DOSE 372682",
	"SPELL_AURA_REMOVED 372682 372988 373680",
	"SPELL_AURA_REMOVED_DOSE 372682",
	"SPELL_PERIODIC_DAMAGE 372963",
	"SPELL_PERIODIC_MISSED 372963"
)

--TODO, target scan Chillstorm if boss looks at victim
--[[
(ability.id = 372851 or ability.id = 396044 or ability.id = 373046) and type = "begincast"
 or ability.id = 373680 and (type = "applybuff" or type = "removebuff")
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
 or ability.id = 385518
--]]
local warnFrozenSolid							= mod:NewTargetNoFilterAnnounce(373022, 4, nil, "Healer")
local warnChillstorm							= mod:NewTargetNoFilterAnnounce(372851, 3) --Ледяная буря
local warnIceBulwark							= mod:NewSpellAnnounce(372988, 4) --Ледяной бастион

local specWarnFrozenSolid						= mod:NewSpecialWarningDispel(373022, "RemoveMagic", nil, nil, 3, 4) --Полная заморозка
local specWarnPrimalChill						= mod:NewSpecialWarningStack(372682, nil, 4, nil, nil, 1, 6) --Древний холод
local specWarnHailbombs							= mod:NewSpecialWarningDodge(396044, nil, nil, nil, 2, 2)
local specWarnChillStorm						= mod:NewSpecialWarningMoveAway(372851, nil, nil, nil, 4, 4) --Ледяная буря
local specWarnFrostOverload						= mod:NewSpecialWarningInterrupt(373680, "HasInterrupt", nil, 2, 1, 3, 4) --Ледяная перегрузка
local specWarnAwakenWhelps						= mod:NewSpecialWarningSwitch(373046, "-Healer", nil, nil, 1, 2) --Пробуждение дракончиков
local specWarnGTFO								= mod:NewSpecialWarningGTFO(372851, nil, nil, nil, 1, 8) --Ледяная буря

local timerChillstormCD							= mod:NewCDTimer(20, 372851, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON, nil, 3, 3) --Ледяная буря
local timerHailbombsCD							= mod:NewCDTimer(20, 396044, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Взрывные градины
local timerFrostOverloadCD						= mod:NewCDTimer(10, 373680, nil, nil, nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Ледяная перегрузка

local yellFrozenSolid							= mod:NewShortYell(373022, nil, nil, nil, "YELL") --Полная заморозка
local yellChillstorm							= mod:NewYell(372851, nil, nil, nil, "YELL") --Ледяная буря
local yellChillstormFades						= mod:NewShortFadesYell(372851, nil, nil, nil, "YELL") --Ледяная буря

mod:AddInfoFrameOption(372682, true)

local chillStacks = {}

function mod:OnCombatStart(delay)
	table.wipe(chillStacks)
	timerHailbombsCD:Start(4-delay) --
	timerChillstormCD:Start(14.2-delay) --
	if self.Options.InfoFrame then
		DBM.InfoFrame:SetHeader(DBM:GetSpellName(372682))
		DBM.InfoFrame:Show(5, "table", chillStacks, 1)
	end
end

function mod:OnCombatEnd()
	table.wipe(chillStacks)
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 372851 then --Ледяная буря
		timerChillstormCD:Start()
	elseif spellId == 396044 then --Взрывные градины
		specWarnHailbombs:Show()
		specWarnHailbombs:Play("watchstep")
		timerHailbombsCD:Start()
	elseif spellId == 373046 then --Пробуждение дракончиков
		specWarnAwakenWhelps:Show()
		specWarnAwakenWhelps:Play("killmob")
		if self:IsMythic() then
			timerFrostOverloadCD:Start()
		end
		timerChillstormCD:Stop()
		timerHailbombsCD:Stop()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 372682 then
		local amount = args.amount or 1
		chillStacks[args.destName] = amount
		if self.Options.InfoFrame then
			DBM.InfoFrame:UpdateTable(chillStacks, 0.2)
		end
		if args:IsPlayer() and amount >= 4 then
			specWarnPrimalChill:Cancel()--Possible to get multiple applications at once so we throttle by scheduling
			specWarnPrimalChill:Schedule(0.2, amount)
			specWarnPrimalChill:ScheduleVoice(0.2, "stackhigh")
		end
	elseif spellId == 373022 then --Полная заморозка
		if args:IsPlayer() then
			yellFrozenSolid:Yell()
		else
			specWarnFrozenSolid:CombinedShow(0.5, args.destName)
			specWarnFrozenSolid:ScheduleVoice(0.5, "helpdispel")
		end
		warnFrozenSolid:CombinedShow(1, args.destName)--Slower aggregation to reduce spam
	elseif spellId == 373680 then
		if not self:IsMythic() then--Interruptable at any time on non mythic
			specWarnFrostOverload:Show(args.destName)
			specWarnFrostOverload:Play("kickcast")
		end
		timerHailbombsCD:Stop()
		timerChillstormCD:Stop()
	elseif spellId == 372988 then
		warnIceBulwark:Show()
	elseif spellId == 385518 then
		if args:IsPlayer() then
			specWarnChillStorm:Show()
			specWarnChillStorm:Play("runout")
			yellChillstorm:Yell()
			yellChillstormFades:Countdown(3.5, 2)--Debuff says 1sec but combat log shows 3.5 on M+ at least, not checked lower difficulties since harder to search on WCL
		else
			warnChillstorm:Show(args.destName)
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 372682 then
		chillStacks[args.destName] = nil
		if self.Options.InfoFrame then
			DBM.InfoFrame:UpdateTable(chillStacks, 0.2)
		end
	elseif spellId == 372988 then--Ice Bulwark Removed, now can interrupt on mythic and mythic+
		specWarnFrostOverload:Show(args.destName)
		specWarnFrostOverload:Play("kickcast")
	elseif spellId == 373680 then --Ледяная перегрузка (когда кикнули каст)
		--True, at least in M+
		timerHailbombsCD:Start(4)
		timerChillstormCD:Start(14.2)
	end
end

function mod:SPELL_AURA_REMOVED_DOSE(args)
	local spellId = args.spellId
	if spellId == 372682 then
		chillStacks[args.destName] = args.amount or 1
		if self.Options.InfoFrame then
			DBM.InfoFrame:UpdateTable(chillStacks, 0.2)
		end
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 372963 and destGUID == UnitGUID("player") and self:AntiSpam(2, 4) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
