local mod	= DBM:NewMod(1140, "DBM-Party-WoD", 6, 537)
local L		= mod:GetLocalizedStrings()

mod.statTypes = "normal,heroic,mythic,challenge,timewalker"

mod:SetRevision("20230504231118")
mod:SetCreatureID(75452)
mod:SetEncounterID(1679)
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 154175 165578",
	"SPELL_AURA_APPLIED 153804",
	"SPELL_AURA_REMOVED 153804",
	"SPELL_PERIODIC_DAMAGE 153692",
	"SPELL_ABSORBED 153692",
	"RAID_BOSS_EMOTE",
	"UNIT_SPELLCAST_SUCCEEDED boss1",
	"UNIT_DIED"
)

--Inhale and submerge timers iffy. Based on data, it's possible they share a CD and which one he uses is random of two.
--With that working theory, it's possible to add a 28-30 second timer for it maybe.
--However, being a 5 man boss. Plus not knowing for certain, not worth the time right now.
--[[
(ability.id = 154175 or ability.id = 165578) and type = "begincast"
 or ability.id = 153804
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
local warnBodySlam				= mod:NewTargetAnnounce(154175, 4) --Мощный удар
local warnCorpseBreath			= mod:NewSpellAnnounce(165578, 2) --Трупное дыхание
local warnSubmerge				= mod:NewSpellAnnounce(172190, 2) --Погружение
local warnInhaleEnd				= mod:NewEndAnnounce(153804, 1) --Вдох

local specWarnBodySlam			= mod:NewSpecialWarningDodge(154175, nil, nil, nil, 2, 2) --Мощный удар
local specWarnInhale			= mod:NewSpecialWarningMoveTo(153804, nil, nil, 2, 4, 13) --Вдох
local specWarnNecroticPitch		= mod:NewSpecialWarningMove(153692, nil, nil, nil, 1, 8) --Некротическая слизь

local timerSubmerge				= mod:NewBuffActiveTimer(6.5, 172190, nil, nil, nil, 7, nil, nil, nil, 3, 5) --Погружение
local timerSubmergeCD			= mod:NewCDTimer(43, 172190, nil, nil, nil, 6, nil, nil, nil, 3, 5) --Погружение
local timerBodySlamCD			= mod:NewCDTimer(23, 154175, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Мощный удар
local timerInhale				= mod:NewCastTimer(9, 153804, nil, nil, nil, 7, nil, nil, nil, 3, 3) --Вдох
local timerInhaleCD				= mod:NewCDTimer(22.1, 153804, nil, nil, nil, 7) --Вдох
local timerCorpseBreathCD		= mod:NewCDTimer(28, 165578, nil, nil, nil, 2, nil, DBM_COMMON_L.HEALER_ICON) --Трупное дыхание

mod.vb.inhaleActive = false

local Pitch = DBM:GetSpellInfo(153692) --Некротическая слизь
local MurchalProshlyap = nil

function mod:OnCombatStart(delay)
	self.vb.inhaleActive = false
	MurchalProshlyap = false
	timerBodySlamCD:Start(31.5-delay)
	timerCorpseBreathCD:Start(6.2-delay)
	timerInhaleCD:Start(13.3-delay)
	timerSubmergeCD:Start(65.5-delay) --Погружение
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 154175 then
		warnBodySlam:Show(args.sourceName)
		if self:AntiSpam(3) then--Throttle special warning when more than 1 slam at once happens.
			specWarnBodySlam:Show()
			specWarnBodySlam:Play("watchstep")
		end
	elseif spellId == 165578 then
		warnCorpseBreath:Show()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 153804 then
		timerInhale:Start()
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 153804 then
		self.vb.inhaleActive = false
		warnInhaleEnd:Show()
	end
end

function mod:RAID_BOSS_EMOTE(msg)
	if msg:find("spell:153804") then--Slightly faster than combat log (~2)
		self.vb.inhaleActive = true
		specWarnInhale:Show(Pitch)
		specWarnInhale:Play("inhalegetinpuddle")
		if not MurchalProshlyap then
			timerInhaleCD:Start(36.3)
		end
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, spellId)
	if spellId == 177694 then --Погружение
		MurchalProshlyap = true
		warnSubmerge:Show()
		timerSubmerge:Start()
		timerInhaleCD:Stop()
		timerBodySlamCD:Stop()
		timerBodySlamCD:Start(9)
		timerInhaleCD:Start(20.5)
		timerCorpseBreathCD:Start(13.5)
		timerSubmergeCD:Start()
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, destName, _, _, spellId)
	if spellId == 153692 and not self.vb.inhaleActive and destGUID == UnitGUID("player") and self:AntiSpam(3, 1) then
		specWarnNecroticPitch:Show()
		specWarnNecroticPitch:Play("watchfeet")
	end
end
mod.SPELL_ABSORBED = mod.SPELL_PERIODIC_DAMAGE
