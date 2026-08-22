local mod	= DBM:NewMod(1518, "DBM-Party-Legion", 1, 740)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260630000000")
mod:SetCreatureID(98542)
mod:SetEncounterID(1832)
mod:SetHotfixNoticeRev(20260714000000)
mod:SetMinSyncRevision(20260714000000)
mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 195254 194966 194956 196078 196587",
	"SPELL_CAST_SUCCESS 196587 194956",
	"SPELL_AURA_APPLIED 194966 196930",
	"SPELL_AURA_APPLIED_DOSE 196930",
	"SPELL_AURA_REMOVED 194966"
)

--[[
(ability.id = 195254 or ability.id = 194966 or ability.id = 194956 or ability.id = 196078 or ability.id = 196587) and type = "begincast"
 or ability.id = 196587 and type = "cast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
--NOTE, trash uses 194966 just like boss, the expression will pick up both
--local warnCallSouls					= mod:NewSpellAnnounce(196078, 2) --Вызов душ Change to important warning if it becomes more relevant.
local warnPhase						= mod:NewPhaseChangeAnnounce(2, 2, nil, nil, nil, nil, nil, 2)
local warnSwirlingScythe			= mod:NewTargetNoFilterAnnounce(195254, 2) --Вращающаяся коса
local warnSoulEchoes				= mod:NewTargetNoFilterAnnounce(194966, 2) --Эхо души
local warnSoulgorge					= mod:NewStackAnnounce(196930, 4)

local specWarnCallSouls				= mod:NewSpecialWarningSwitch(196078, nil, nil, nil, 1, 2) --Вызов душ
local specWarnSoulBurst				= mod:NewSpecialWarningDefensive(196587, nil, nil, nil, 3, 4) --Взрыв души
local specWarnReapSoul				= mod:NewSpecialWarningDodge(194956, nil, nil, DBM_COMMON_L.FRONTAL, 2, 2) --Жатва душ (Фронталка)
local specWarnSoulEchos				= mod:NewSpecialWarningRun(194966, nil, nil, nil, 4, 2) --Эхо души
local specWarnSwirlingScythe		= mod:NewSpecialWarningDodge(195254, nil, nil, nil, 2, 2) --Вращающаяся коса

local timerSwirlingScytheCD			= mod:NewCDTimer(20, 195254, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Вращающаяся коса 20-27
local timerSoulEchoesCD				= mod:NewNextTimer(27.5, 194966, nil, nil, nil, 3) --Эхо души
local timerReapSoulCD				= mod:NewNextTimer(10, 194956, DBM_COMMON_L.FRONTAL, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON) --Жатва душ (Фронталка) 13-3 because started in success

local yellSwirlingScythe			= mod:NewYell(195254, nil, nil, nil, "YELL") --Вращающаяся коса
local yellSoulEchoes				= mod:NewYell(194966, nil, nil, nil, "YELL") --Эхо души
local yellSoulEchoesFades			= mod:NewShortFadesYell(194966, nil, nil, nil, "YELL") --Эхо души

mod.vb.scytheCount = 0
mod.vb.echoesCount = 0
mod.vb.reapCount = 0
mod.vb.burstCounnt = 0

function mod:ScytheTarget(targetname, uId)
	if not targetname then
		warnSwirlingScythe:Show(DBM_COMMON_L.UNKNOWN)
		return
	end
	if targetname == UnitName("player") then
		specWarnSwirlingScythe:Show()
		specWarnSwirlingScythe:Play("runaway")
		yellSwirlingScythe:Yell()
	else
		warnSwirlingScythe:Show(targetname)
	end
end

function mod:SoulTarget(targetname, uId)
	if not targetname then
		return
	end
	if self:AntiSpam(3, targetname) then
		if targetname == UnitName("player") then
			specWarnSoulEchos:Show()
			specWarnSoulEchos:Play("runaway")
			specWarnSoulEchos:ScheduleVoice(1, "keepmove")
			yellSoulEchoes:Yell()
		else
			warnSoulEchoes:Show(targetname)
		end
	end
end

function mod:OnCombatStart(delay)
	self.vb.scytheCount = 0
	self.vb.echoesCount = 0
	self.vb.reapCount = 0
	self.vb.burstCount = 0
	self:SetStage(1)
	timerSwirlingScytheCD:Start(8-delay, 1)
	timerSoulEchoesCD:Start(15.5-delay, 1)
	timerReapSoulCD:Start(20-delay, 1)
end
--[[function mod:OnCombatEnd(wipe, secondRun)
	if not wipe and not secondRun then
		local BRHTrash = DBM:GetModByName("BRHTrash")
		BRHTrash:StartFirstRP()
	end
--	if self.Options.RangeFrame then
--		DBM.RangeCheck:Hide()
--	end
end]]

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 195254 then
		self.vb.scytheCount = self.vb.scytheCount + 1
		timerSwirlingScytheCD:Start(nil, self.vb.scytheCount+1)
		self:BossTargetScanner(args.sourceGUID, "ScytheTarget", 0.05, 12, true)--Can target tank if no one else is left, but if this causes probelm add tank filter back
	elseif spellId == 194966 then
		self.vb.echoesCount = self.vb.echoesCount + 1
		timerSoulEchoesCD:Start(nil, self.vb.echoesCount+1)
		self:BossTargetScanner(args.sourceGUID, "SoulTarget", 0.1, 20, true, nil, nil, nil, true)--Always filter tank, because if scan fails debuff will be used.
	elseif spellId == 194956 then
		specWarnReapSoul:Show()
		specWarnReapSoul:Play("shockwave")
	elseif spellId == 196078 then
		self:SetStage(2)
		warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(2))
		warnPhase:Play("phasechange")
		specWarnCallSouls:Schedule(1.5)
		specWarnCallSouls:ScheduleVoice(1.5, "mobkill")
		timerReapSoulCD:Stop()
		timerSwirlingScytheCD:Stop()
		timerSoulEchoesCD:Stop()
	elseif spellId == 196587 then
		self.vb.burstCount = self.vb.burstCount + 1
		specWarnSoulBurst:Show()
		specWarnSoulBurst:Play("defensive")
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 196587 then--SoulBurst Ending
		self:SetStage(1)
		warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(1))
		warnPhase:Play("phasechange")
		--Reset Count?
		--self.vb.scytheCount = 0
		--self.vb.echoesCount = 0
		--self.vb.reapCount = 0
		timerSwirlingScytheCD:Start(5.5, self.vb.scytheCount+1) --
		timerSoulEchoesCD:Start(11.6, self.vb.echoesCount+1) --
		timerReapSoulCD:Start(17.4, self.vb.reapCount+1) --
	elseif spellId == 194956 then
		self.vb.reapCount = self.vb.reapCount + 1
		timerReapSoulCD:Start(nil, self.vb.reapCount+1)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 194966 and self:AntiSpam(3, args.destName) then--Backup Soul echos warning that's 2 seconds slower than target scan
		if args:IsPlayer() then
			specWarnSoulEchos:Show()
			specWarnSoulEchos:Play("runaway")
			specWarnSoulEchos:ScheduleVoice(1, "keepmove")
			yellSoulEchoesFades:Countdown(spellId)
		else
			warnSoulEchoes:Show(args.destName)
		end
	elseif spellId == 196930 then
		warnSoulgorge:Show(args.destName, args.amount or 1)
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 194966 then
		if args:IsPlayer() then
			yellSoulEchoesFades:Cancel()
		end
	end
end
--mod.SPELL_AURA_REMOVED_DOSE = mod.SPELL_AURA_REMOVED
