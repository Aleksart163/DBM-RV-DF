local mod	= DBM:NewMod(2129, "DBM-Party-BfA", 10, 1021)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260630000000")
mod:SetCreatureID(131864)
mod:SetEncounterID(2117)
mod:SetHotfixNoticeRev(20260714000000)
mod:SetMinSyncRevision(20260714000000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 266225 266266 266181 268202",--266266
	"SPELL_CAST_SUCCESS 266198 266266",
	"SPELL_AURA_APPLIED 268202"
)

--[[
(ability.id = 266225 or ability.id = 266181) and type = "begincast"
 or (ability.id = 266266 or ability.id = 266198) and type = "cast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
 or ability.id = 268202 and type = "begincast"
--]]
--NOTE, death lens is cast 5.2-5.7 seconds after add spawns, but sadly grabbing add GUID to attach a nameplate Id isn't very easy
local warnDeathlens					= mod:NewCastAnnounce(268202, 2) --Линза смерти
local warnDeathlensTarget			= mod:NewTargetNoFilterAnnounce(268202, 4) --Линза смерти
local warnFire						= mod:NewSpellAnnounce(266198, 1) --Алхимический огонь

local specWarnDeathlens				= mod:NewSpecialWarningYou(268202, nil, nil, nil, 1, 2) --Линза смерти
local specWarnSummonSlaver			= mod:NewSpecialWarningSwitchCount(266266, "-Healer", nil, DBM_COMMON_L.ADD, 1, 2) --Призыв меченного смертью поработителя (Адд)
local specWarnDreadEssence			= mod:NewSpecialWarningCount(266181, nil, nil, nil, 2, 2) --Сущность ужаса
local specWarnDarkenedLightning		= mod:NewSpecialWarningInterruptCount(266225, "HasInterrupt", nil, nil, 1, 2) --Темная молния

local timerDarkenedLightningCD		= mod:NewCDCountTimer(14.1, 266225, nil, nil, nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Темная молния 14-20
local timerSummonSlaverCD			= mod:NewCDCountTimer(16, 266266, DBM_COMMON_L.ADD.." (%s)", nil, nil, 1, nil, DBM_COMMON_L.DAMAGE_ICON) --Призыв меченного смертью поработителя (Адд) 16-22
local timerDreadEssenceCD			= mod:NewCDCountTimer(27.5, 266181, nil, nil, nil, 2, nil, nil, nil, 1, 5) --Сущность ужаса

local yellDeathlens					= mod:NewYell(268202, nil, nil, nil, "YELL") --Линза смерти

mod:AddRangeFrameOption(6, 266225)--Range guessed, can't find spell data for it

mod.vb.darkenCount = 0
mod.vb.slaverCount = 0
mod.vb.dreadCount = 0

function mod:OnCombatStart(delay)
	self.vb.darkenCount = 0
	self.vb.slaverCount = 0
	self.vb.dreadCount = 0
	timerSummonSlaverCD:Start(4.1-delay, 1)--4-6
	timerDarkenedLightningCD:Start(6.1-delay, 1)--6-8
	timerDreadEssenceCD:Start(25-delay, 1)--25-27
	if self.Options.RangeFrame then
		DBM.RangeCheck:Show(6)
	end
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 266225 then
		self.vb.darkenCount = self.vb.darkenCount + 1
		timerDarkenedLightningCD:Start(nil, self.vb.darkenCount+1)
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnDarkenedLightning:Show(args.sourceName, self.vb.darkenCount)
			specWarnDarkenedLightning:Play("kickcast")
		end
	elseif spellId == 266181 then --Сущность ужаса
		self.vb.dreadCount = self.vb.dreadCount + 1
		specWarnDreadEssence:Show(self.vb.dreadCount)
		specWarnDreadEssence:Play("aesoon")
		timerDreadEssenceCD:Start(nil, self.vb.dreadCount+1)
	elseif spellId == 268202 then --Линза смерти
		warnDeathlens:Show()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 266198 then
		warnFire:Show()
	elseif spellId == 266266 then--Success is used cause you can't swap to it til it spawns, can't pick it up til it spawns
		self.vb.slaverCount = self.vb.slaverCount + 1
		specWarnSummonSlaver:Show(self.vb.slaverCount)
		specWarnSummonSlaver:Play("killmob")
		timerSummonSlaverCD:Start(nil, self.vb.slaverCount+1)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 268202 then --Линза смерти
		if args:IsPlayer() then
            specWarnDeathlens:Show()
            specWarnDeathlens:Play("targetyou")
            yellDeathlens:Yell()
        else
            warnDeathlensTarget:CombinedShow(0.3, args.destName)
        end
	end
end

--[[
function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 135552 then--Slaver

	end
end
--]]
