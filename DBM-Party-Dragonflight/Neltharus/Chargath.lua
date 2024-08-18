local mod	= DBM:NewMod(2490, "DBM-Party-Dragonflight", 4, 1199)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240817070000")
mod:SetCreatureID(189340)
mod:SetEncounterID(2613)
mod:SetUsedIcons(8)
mod:SetHotfixNoticeRev(20230703000000)
--mod:SetMinSyncRevision(20211203000000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 373733 373742 375056",
	"SPELL_AURA_APPLIED 374655 375057 388523 373735",
	"SPELL_AURA_APPLIED_DOSE 374655",
	"SPELL_AURA_REFRESH 374655",
	"SPELL_AURA_REMOVED 374655 388523 375055 373735",
	"SPELL_PERIODIC_DAMAGE 374854",
	"SPELL_PERIODIC_MISSED 374854"
)

--TODO, verify dragon strike target scan
--[[
(ability.id = 373733 or ability.id = 373742 or ability.id = 373424 or ability.id = 375056) and type = "begincast"
 or ability.id = 374655 or (ability.id = 388523 or ability.id = 375055) and (type = "applybuff" or type = "removebuff" or type = "applydebuff" or type = "removedebuff")
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
local warnDragonStrike							= mod:NewTargetNoFilterAnnounce(373733, 3) --Удар дракона
local warnGroundingSpear						= mod:NewTargetNoFilterAnnounce(373424, 4) --Сбивающее копье
local warnFetterStack							= mod:NewStackAnnounce(374655, 2) --Кандалы
local warnFetter								= mod:NewTargetNoFilterAnnounce(374655, 2) --Кандалы Boss Only

local specWarnDragonStrike						= mod:NewSpecialWarningDefensive(373733, nil, nil, nil, 3, 4) --Удар дракона
local specWarnDragonStrike2						= mod:NewSpecialWarningTarget(373733, "Healer", nil, nil, 3, 4) --Удар дракона
local specWarnMagmaWave							= mod:NewSpecialWarningDodge(373742, nil, nil, nil, 2, 2) --Магматическая волна
local specWarnGroundingSpear					= mod:NewSpecialWarningYou(373424, nil, nil, nil, 1, 2) --Сбивающее копье
local specWarnFieryFocus						= mod:NewSpecialWarningInterrupt(375056, nil, nil, nil, 1, 13) --Огненное преследование
local specWarnGTFO								= mod:NewSpecialWarningGTFO(374854, nil, nil, nil, 1, 8) --Взорванная земля

local timerDragonStrikeCD						= mod:NewCDTimer(12.1, 373733, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON..DBM_COMMON_L.BLEED_ICON, nil, 2, 5) --Удар дракона
local timerMagmaWaveCD							= mod:NewCDTimer(12.1, 373742, nil, nil, nil, 3) --Магматическая волна Actual CD still not known, since you'd never fully see it unhindered by blade lock or reset by fetter
local timerGroundingSpearCD						= mod:NewCDTimer(8.9, 373424, nil, nil, nil, 3) --Сбивающее копье
local timerFetter								= mod:NewBuffActiveTimer(12, 374655, nil, nil, nil, 5, nil, DBM_COMMON_L.DAMAGE_ICON, nil, 1, 5) --Кандалы
local timerFieryFocusCD							= mod:NewCDTimer(30, 375056, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Огненное преследование

local yellGroundingSpear						= mod:NewShortYell(373424, nil, nil, nil, "YELL") --Сбивающее копье
local yellDragonStrike							= mod:NewShortYell(373733, nil, nil, nil, "YELL") --Удар дракона

mod:AddSetIconOption("SetIconOnDragonStrike", 373733, true, 0, {8}) --Удар дракона

mod.vb.magmawaveCount = 0
mod.vb.dragonCount = 0
mod.vb.focusCount = 0
mod.vb.focusInProgress = false
mod.vb.bossFettered = false

function mod:DragonStrikeTarget(targetname)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnDragonStrike:Show()
		specWarnDragonStrike:Play("defensive")
		yellDragonStrike:Yell()
	else
		warnDragonStrike:Show(targetname)
	end
end

function mod:OnCombatStart(delay)
	self.vb.magmawaveCount = 0
	self.vb.dragonCount = 0
	self.vb.focusCount = 0
	self.vb.focusInProgress = false
	self.vb.bossFettered = false
	timerMagmaWaveCD:Start(4.9-delay) --
	timerDragonStrikeCD:Start(12-delay)
	timerGroundingSpearCD:Start(24.5-delay)
	timerFieryFocusCD:Start(29.2-delay)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 373733 then
		self.vb.dragonCount = self.vb.dragonCount + 1
		self:ScheduleMethod(0.2, "BossTargetScanner", args.sourceGUID, "DragonStrikeTarget", 0.1, 8, true)
--		timerDragonStrikeCD:Start()
	elseif spellId == 373742 then --Магматическая волна
		self.vb.magmawaveCount = self.vb.magmawaveCount + 1
		specWarnMagmaWave:Show()
		specWarnMagmaWave:Play("watchwave")
		if self.vb.magmawaveCount < 2 then
			timerMagmaWaveCD:Start(nil, self.vb.magmawaveCount+1)
		end
--	elseif spellId == 373424 then
--		timerGroundingSpearCD:Start()
	elseif spellId == 375056 then
		self.vb.focusCount = self.vb.focusCount + 1
		self.vb.focusInProgress = true
		specWarnFieryFocus:Show(args.sourceName)
		specWarnFieryFocus:Play("chainboss")
		--Blade lock does NOT reset existing CD timers
		--they'll queue up and cast one after another when blade lock ends
		--^Old info. CDs now do reset?
		--timerGroundingSpearCD:Stop()
		--timerMagmaWaveCD:Stop()
		--timerDragonStrikeCD:Stop()
		--timerFieryFocusCD:Stop()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 388523 or spellId == 374655 then
		if spellId == 388523 then--12 second stun
			self.vb.magmawaveCount = 0
			self.vb.bossFettered = true
			warnFetter:Show(args.destName)
			timerFetter:Start(args.destName)
			--Stop timers, since they'll reset on fetter ending, most of the time anyways
			timerGroundingSpearCD:Stop()
			timerMagmaWaveCD:Stop()
			timerDragonStrikeCD:Stop()
			timerFieryFocusCD:Stop()
		else
			if self:IsMythic() then
				local amount = args.amount or 1
				if amount < 3 then
					warnFetterStack:Show(args.destName, amount)
				end
			end
		end
	elseif spellId == 375057 then
		if args:IsPlayer() then
			specWarnGroundingSpear:Show()
			specWarnGroundingSpear:Play("targetyou")
			yellGroundingSpear:Yell()
		elseif not self:IsMythic() then--On non mythic only one target, else everyone gets it so no need to target announce
			warnGroundingSpear:Show(args.destName)
		end
	elseif spellId == 373735 then --Удар дракона
		--Новые прошляпы--
		if args:IsPlayer() then
			DBM:Debug("Здесь прошляпил своё очко Мурчаль Прошляпенко и его подсос на Illisone", 2)
		else
			specWarnDragonStrike2:Show(args.destName)
			specWarnDragonStrike2:Play("healall")
		end
		if self.Options.SetIconOnDragonStrike then
			self:SetIcon(args.destName, 8, 14)
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED
mod.SPELL_AURA_REFRESH = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 388523 then
		self.vb.bossFettered = false
		timerFetter:Stop(args.destName)
		--Fetter on other hand does seem to hard reset things, to an extent
		if not self.vb.focusInProgress then
			timerMagmaWaveCD:Start(8.7, self.vb.magmawaveCount+1)
			timerDragonStrikeCD:Start(15.1, self.vb.dragonCount+1)
			timerGroundingSpearCD:Start(27.2)
			timerFieryFocusCD:Start(30.9, self.vb.focusCount+1)
		else
			--GG, boss bugged for you and he's gonna come out of this phase and recast Fiery Focus Immediately
			DBM:Debug("Bugged Boss Detected, Good Luck (and also review this log later)")
		end
	elseif spellId == 374655 and not self:IsMythic() then
		timerFieryFocusCD:AddTime(2)
	elseif spellId == 375055 then--Fiery Focus Removed
		self.vb.focusInProgress = false
		if not self.vb.bossFettered then
			timerMagmaWaveCD:Start(6.8, self.vb.magmawaveCount+1)
			timerDragonStrikeCD:Start(13.4, self.vb.dragonCount+1)
			timerGroundingSpearCD:Start(25.7)
			timerFieryFocusCD:Start(30.2, self.vb.focusCount+1)
		end
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 374854 and destGUID == UnitGUID("player") and self:AntiSpam(3, 2) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
