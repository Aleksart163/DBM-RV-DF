local mod	= DBM:NewMod(1673, "DBM-Party-Legion", 5, 767)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20230829081105")
mod:SetCreatureID(91005)
mod:SetEncounterID(1792)
mod.sendMainBossGUID = true
mod.respawnTime = 15--10-15, trying 15 for now, def not 30

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 199176 210150 205549",
	"SPELL_AURA_APPLIED 209906 199775",
	"SPELL_AURA_REMOVED 199178",
	"SPELL_PERIODIC_DAMAGE 188494",
	"SPELL_PERIODIC_MISSED 188494",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

--[[
(ability.id = 199176 or ability.id = 210150 or ability.id = 205549) and type = "begincast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
local warnFixate					= mod:NewTargetNoFilterAnnounce(209906, 2, nil, false) --Самопожертвование фанатика Could be spammy, optional
local warnSpikedTongueOver			= mod:NewEndAnnounce(199176, 1) --Шипастый язык
local warnFrenzy					= mod:NewTargetNoFilterAnnounce(199775, 4) --Бешенство

local specWarnAdds					= mod:NewSpecialWarningSwitch(199817, "Dps", nil, 2, 2, 2) --Призыв прислужников
local specWarnFixate				= mod:NewSpecialWarningYou(209906, nil, nil, nil, 1, 2) --Самопожертвование фанатика
local specWarnSpikedTongue			= mod:NewSpecialWarningRun(199176, nil, nil, nil, 4, 2) --Шипастый язык
local specWarnRancidMaw				= mod:NewSpecialWarningGTFO(188494, nil, nil, nil, 1, 8) --Зловонная пасть

local timerSpikedTongueCD			= mod:NewCDTimer(60, 199176, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Шипастый язык
local timerSpikedTongue				= mod:NewCastTimer(16, 199176, nil, "Tank|Healer", nil, 7, nil, nil, nil, 1, 5) --Шипастый язык
local timerAddsCD					= mod:NewCDTimer(120, 199817, nil, nil, nil, 1, 226361, DBM_COMMON_L.DAMAGE_ICON..DBM_COMMON_L.DEADLY_ICON, nil, mod:IsDps() and 1 or nil, 5) --Призыв прислужников
local timerRancidMawCD				= mod:NewCDTimer(18, 205549, nil, nil, nil, 2) --Зловонная пасть
local timerToxicRetchCD				= mod:NewCDTimer(14.3, 210150, nil, nil, nil, 3) --Токсичная желчь

local yellSpikedTongue				= mod:NewShortYell(199176, nil, nil, nil, "YELL") --Шипастый язык

mod.vb.retchCount = 0
mod.vb.addsCount = 0
mod.vb.spikeCount = 0
mod.vb.mawCount = 0

local allProshlyapationsOfMurchal = {
	--Шипастый язык
	[199176] = {49.9, 55.9, 55, 55, 55, 55, 56.3},
	--Призыв прислужников
	[199817] = {5, 80, 96, 80.4, 96},
}

function mod:OnCombatStart(delay)
	self.vb.retchCount = 0
	self.vb.addsCount = 0
	self.vb.spikeCount = 0
	self.vb.mawCount = 0
	timerAddsCD:Start(5-delay) --
	timerRancidMawCD:Start(6.9-delay) --
	timerToxicRetchCD:Start(12.2-delay) --
	timerSpikedTongueCD:Start(49.9-delay) --
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 209906 then
		if args:IsPlayer() and self:AntiSpam(4, 1) then
			specWarnFixate:Show()
			specWarnFixate:Play("targetyou")
		else
			warnFixate:Show(args.destName)
		end
	elseif spellId == 199775 then --Бешенство
		warnFrenzy:Show(args.destName)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 199178 and self:AntiSpam(4, 2) then --Шипастый язык (притяжка)
		warnSpikedTongueOver:Show()
		timerSpikedTongue:Stop()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 199176 then --Шипастый язык
		self.vb.spikeCount = self.vb.spikeCount + 1
		if self:IsTanking("player", "boss1", nil, true) then
			specWarnSpikedTongue:Show()
			specWarnSpikedTongue:Play("justrun")
			specWarnSpikedTongue:ScheduleVoice(1.5, "keepmove")
			yellSpikedTongue:Yell()
		end
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.spikeCount+1)
		if timer then
			timerSpikedTongueCD:Start(timer, self.vb.spikeCount+1)
		end
		timerSpikedTongue:Start()
		timerRancidMawCD:Stop()
		timerToxicRetchCD:Stop()
	elseif spellId == 205549 then
		self.vb.mawCount = self.vb.mawCount + 1
		timerRancidMawCD:Start(nil, self.vb.mawCount+1)
	elseif spellId == 210150 then
		self.vb.retchCount = self.vb.retchCount + 1
		timerToxicRetchCD:Start(nil, self.vb.retchCount+1)
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 188494 and destGUID == UnitGUID("player") and self:AntiSpam(3, 3) then
		specWarnRancidMaw:Show(spellName)
		specWarnRancidMaw:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE

function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, spellId)
	if spellId == 199817 then--Call Minions
		self.vb.addsCount = self.vb.addsCount + 1
		if self:IsMelee() then
			specWarnAdds:Schedule(5.5)
			specWarnAdds:ScheduleVoice(5.5, "mobkill")
		else
			specWarnAdds:Show()
			specWarnAdds:Play("mobkill")
		end
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.addsCount+1)
		if timer then
			timerAddsCD:Start(timer, self.vb.addsCount+1)
		end
	end
end
