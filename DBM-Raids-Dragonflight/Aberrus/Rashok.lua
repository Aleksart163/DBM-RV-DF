local mod	= DBM:NewMod(2525, "DBM-Raids-Dragonflight", 2, 1208)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240426174649")
mod:SetCreatureID(201320)
mod:SetEncounterID(2680)
mod:SetUsedIcons(8)
mod:SetHotfixNoticeRev(20240609070000)
--mod:SetMinSyncRevision(20221215000000)
mod.respawnTime = 30

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 405316 405821 406851 406333 406145 400777 410070 407596 407544",
	"SPELL_CAST_SUCCESS 407641",
	"SPELL_AURA_APPLIED 405819 407547 407597 401419 405827",
	"SPELL_AURA_APPLIED_DOSE 405827",
	"SPELL_AURA_REMOVED 405819 401419 405827 405091",
	"SPELL_AURA_REMOVED_DOSE 405827",
	"SPELL_PERIODIC_DAMAGE 403543",
	"SPELL_PERIODIC_MISSED 403543"
)

--NOTE, in LFR (and maybe normal), tank combo is not in random order so might be able to clean up tank code there
--[[
(ability.id = 410070 or ability.id = 405316 or ability.id = 405821 or ability.id = 406851 or ability.id = 406333 or ability.id = 406145 or ability.id = 400777 or ability.id = 407547 or ability.id = 407597 or ability.id = 406165 or ability.id = 407596 or ability.id = 407544) and type = "begincast"
 or ability.id = 401419 and (type = "applybuff" or type = "removebuff") or ability.id = 405825 or ability.id = 407641
--]]
--TODO, https://www.wowhead.com/ptr/spell=407706/molten-wrath seems passive, but still maybe have a 15 second timer with right script
local warnSearingSlam								= mod:NewTargetNoFilterAnnounce(405821, 4) --Обжигающий удар
local warnSiphonEnergyApplied						= mod:NewTargetNoFilterAnnounce(401419, 2) --Проводник старейшины
local warnSiphonEnergyRemoved						= mod:NewFadesAnnounce(401419, 2) --Проводник старейшины
local warnUnyieldingRage							= mod:NewFadesAnnounce(406165, 1) --Тлеющая ярость
local warnWrathDjaruun								= mod:NewSpellAnnounce(407641, 4)

local specWarnShatteredConduit						= mod:NewSpecialWarningSpell(410690, nil, nil, nil, 3, 4) --Сломанный проводник
local specWarnAncientFury							= mod:NewSpecialWarningSpell(405316, nil, nil, nil, 2, 2) --Древняя ярость
local specWarnSearingSlam							= mod:NewSpecialWarningRun(405821, nil, nil, nil, 4, 4) --Обжигающий удар
local specWarnDoomFlame								= mod:NewSpecialWarningSoakCount(406851, nil, nil, nil, 2, 2) --Огни рока
local specWarnShadowlavaBlast						= mod:NewSpecialWarningDodge(406333, nil, nil, nil, 2, 2) --Взрыв темной лавы
local specWarnChargedSmash							= mod:NewSpecialWarningSoakCount(400777, nil, nil, nil, 2, 2) --Заряженный удар
local specWarnFlamingSlash							= mod:NewSpecialWarningDefensive(407547, nil, nil, nil, 3, 2) --Огненный взмах
local specWarnFlamingSlashTaunt						= mod:NewSpecialWarningTaunt(407547, "Tank", nil, nil, 3, 2) --Огненный взмах
local specWarnEarthenCrush							= mod:NewSpecialWarningDefensive(407597, nil, nil, nil, 3, 2) --Земляное сокрушение
local specWarnEarthenCrushTaunt						= mod:NewSpecialWarningTaunt(407597, "Tank", nil, nil, 3, 2) --Земляное сокрушение

local specWarnUnleashedShadowflame					= mod:NewSpecialWarningCount(410070, nil, 98565, nil, 2, 2, 4) --Высвобождение пламени Тьмы(Горящие шары)
local specWarnGTFO									= mod:NewSpecialWarningGTFO(403543, nil, nil, nil, 1, 8)

local timerUnyieldingRage							= mod:NewBuffActiveTimer(96, 406165, nil, nil, nil, 7, nil, nil, nil, 3, 5) --Тлеющая ярость
local timerAncientFuryCD							= mod:NewCDTimer(29.9, 405316, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Древняя ярость
local timerSearingSlamCD							= mod:NewCDCountTimer(40, 405821, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Обжигающий удар
local timerDoomFlameCD								= mod:NewCDCountTimer(28.9, 406851, nil, nil, nil, 5) --Огни рока
local timerShadowlavaBlastCD						= mod:NewCDCountTimer(28.9, 406333, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Взрыв темной лавы
local timerChargedSmashCD							= mod:NewCDCountTimer(40, 400777, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON) --Заряженный удар
local timerVolcanicComboCD							= mod:NewCDCountTimer(40, 407641, DBM_COMMON_L.TANKCOMBO.." (%s)", "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON) --Комбо
local timerUnleashedShadowflameCD					= mod:NewCDCountTimer(40, 410070, 98565, nil, nil, 2, nil, DBM_COMMON_L.MYTHIC_ICON) --Высвобождение пламени Тьмы(Горящие шары)
local berserkTimer									= mod:NewBerserkTimer(120)

local yellSearingSlam								= mod:NewShortYell(405821, nil, nil, nil, "YELL") --Обжигающий удар
local yellSearingSlamFades							= mod:NewShortFadesYell(405821, nil, nil, nil, "YELL") --Обжигающий удар

mod:AddInfoFrameOption(405827)
mod:AddSetIconOption("SetIconOnSearingSlam", 405821, false, 0, {8}) --Обжигающий удар
--mod:AddNamePlateOption("NPAuraOnAscension", 385541)
mod:AddDropdownOption("TankSwapBehavior", {"DoubleSoak", "MinMaxSoak", "OnlyIfDanger"}, "DoubleSoak", "misc", nil, 407641)
--mod:GroupSpells(390715, 396094)

mod.vb.slamCount = 0
mod.vb.doomCount = 0
mod.vb.blastCount = 0
mod.vb.smashCount = 0
mod.vb.tankCombo = 0--Cast
mod.vb.comboCount = 0--Combos within cast
mod.vb.firstHitTank = ""
mod.vb.shadowflameCount = 0
mod.vb.proshlyapMurchalCount = 0
mod.vb.murchalOchkenProshlyapationCount = 1

local overchargedStacks = {}
local normalFirstMurchalProshlyapTimers = {30.1, 13.8, 32.9}
local normalSecondMurchalProshlyapTimers = {31.1, 14.9, 33.9}
local normalThirdMurchalProshlyapTimers = {30.2, 15.9, 33}
local heroicFirstMurchalProshlyapTimers = {29.1, 15, 33}
local heroicSecondMurchalProshlyapTimers = {31.1, 15, 33}
local heroicThirdMurchalProshlyapTimers = {30.2, 15.9, 33}

function mod:FlamingSlashTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnFlamingSlash:Show()
		specWarnFlamingSlash:Play("defensive")
	else
		if UnitExists("boss1target") and not UnitIsUnit("player", "boss1target") then
			local _, _, _, _, _, expireTimeTarget = DBM:UnitDebuff("boss1target", 407547)
			if (expireTimeTarget and expireTimeTarget-GetTime() >= 2) and self:AntiSpam(1, 1) and not UnitIsDeadOrGhost("player") then
				specWarnFlamingSlashTaunt:Show(UnitName("boss1target"))
				specWarnFlamingSlashTaunt:Play("tauntboss")
			end
		end
	end
end

function mod:EarthenCrushTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnEarthenCrush:Show()
		specWarnEarthenCrush:Play("defensive")
	else
		if UnitExists("boss1target") and not UnitIsUnit("player", "boss1target") then
			local _, _, _, _, _, expireTimeTarget = DBM:UnitDebuff("boss1target", 407597)
			if (expireTimeTarget and expireTimeTarget-GetTime() >= 2) and self:AntiSpam(1, 1) and not UnitIsDeadOrGhost("player") then
				specWarnEarthenCrushTaunt:Show(UnitName("boss1target"))
				specWarnEarthenCrushTaunt:Play("tauntboss")
			end
		end
	end
end

local function startProshlyapationOfMurchal(self) -- Proshlyapation of Murchal
	self.vb.firstHitTank = ""
	self.vb.comboCount = 0
	self.vb.proshlyapMurchalCount = self.vb.proshlyapMurchalCount + 1
	local proshlyap  = self:IsMythic() and self.vb.murchalOchkenProshlyapationCount == 1 and heroicFirstMurchalProshlyapTimers[self.vb.proshlyapMurchalCount+1] or self:IsHeroic() and self.vb.murchalOchkenProshlyapationCount == 1 and heroicFirstMurchalProshlyapTimers[self.vb.proshlyapMurchalCount+1] or self:IsEasy() and self.vb.murchalOchkenProshlyapationCount == 1 and normalFirstMurchalProshlyapTimers[self.vb.proshlyapMurchalCount+1]
	local proshlyap2 = self:IsMythic() and self.vb.murchalOchkenProshlyapationCount == 2 and heroicSecondMurchalProshlyapTimers[self.vb.proshlyapMurchalCount+1] or self:IsHeroic() and self.vb.murchalOchkenProshlyapationCount == 2 and heroicSecondMurchalProshlyapTimers[self.vb.proshlyapMurchalCount+1] or self:IsEasy() and self.vb.murchalOchkenProshlyapationCount == 2 and normalSecondMurchalProshlyapTimers[self.vb.proshlyapMurchalCount+1]
	local proshlyap3 = self:IsMythic() and self.vb.murchalOchkenProshlyapationCount == 3 and heroicThirdMurchalProshlyapTimers[self.vb.proshlyapMurchalCount+1] or self:IsHeroic() and self.vb.murchalOchkenProshlyapationCount == 3 and heroicThirdMurchalProshlyapTimers[self.vb.proshlyapMurchalCount+1] or self:IsEasy() and self.vb.murchalOchkenProshlyapationCount == 3 and normalThirdMurchalProshlyapTimers[self.vb.proshlyapMurchalCount+1]
	if proshlyap then
		timerVolcanicComboCD:Start(proshlyap, self.vb.proshlyapMurchalCount+1)
		self:Schedule(proshlyap, startProshlyapationOfMurchal, self)
	elseif proshlyap2 then
		timerVolcanicComboCD:Start(proshlyap2, self.vb.proshlyapMurchalCount+1)
		self:Schedule(proshlyap2, startProshlyapationOfMurchal, self)
	elseif proshlyap3 then
		timerVolcanicComboCD:Start(proshlyap3, self.vb.proshlyapMurchalCount+1)
		self:Schedule(proshlyap3, startProshlyapationOfMurchal, self)
	end
	warnWrathDjaruun:Show()
end

local difficultyName = "normal"
local allProshlyapationsOfMurchal = {
	["mythic"] = {
		[1] = {
			--Обжигающий удар
			[405821] = {9.1, 45.9, 32.9},
		},
		[2] = {
			[405821] = {11.1, 45.9, 32.9},
		},
		[3] = {
			[405821] = {9.1, 46, 32.9},
		},
	},
	["heroic"] = {
		[1] = {
			--Обжигающий удар
			[405821] = {9.1, 45.9, 32.9}, --
		},
		[2] = {
			[405821] = {11.1, 45.9, 32.9}, --
		},
		[3] = {
			[405821] = {9.1, 46, 32.9}, --третий удар пока неизвестно
		},
	},
	["normal"] = {
		[1] = {
			--Обжигающий удар
			[405821] = {9.1, 44.9, 32.9}, --
		},
		[2] = {
			[405821] = {10.1, 45.9, 33.8}, --
		},
		[3] = {
			--пока неточная информация
			[405821] = {10.1, 45.9, 33.8},
		},
	},
}

function mod:OnCombatStart(delay)
	table.wipe(overchargedStacks)
	self.vb.proshlyapMurchalCount = 0
	self.vb.murchalOchkenProshlyapationCount = 1
	self.vb.slamCount = 0
	self.vb.doomCount = 0
	self.vb.blastCount = 0
	self.vb.smashCount = 0
	self.vb.tankCombo = 0
	self.vb.comboCount = 0
	self.vb.firstHitTank = ""
	self.vb.shadowflameCount = 0
	timerSearingSlamCD:Start(9.1-delay, 1)
	timerChargedSmashCD:Start(21.1-delay, 1)
	timerDoomFlameCD:Start(39.1-delay, 1)
	timerShadowlavaBlastCD:Start(95.2-delay, 1)
	timerAncientFuryCD:Start(120-delay)
	if self:IsMythic() then
		timerUnleashedShadowflameCD:Start(4.2-delay, 1)
		timerVolcanicComboCD:Start(29.1-delay, 1)
		self:Schedule(29.1, startProshlyapationOfMurchal, self)
		if self.Options.InfoFrame then
			DBM.InfoFrame:SetHeader(DBM:GetSpellName(405827))
			DBM.InfoFrame:Show(5, "table", overchargedStacks, 1)
		end
		self:RegisterShortTermEvents(
			"SPELL_ENERGIZE 405825"
		)
		difficultyName = "mythic"
	elseif self:IsHeroic() then
		timerVolcanicComboCD:Start(29.1-delay, 1)
		self:Schedule(29.1, startProshlyapationOfMurchal, self)
		difficultyName = "heroic"
	else
		timerVolcanicComboCD:Start(30.1-delay, 1)
		self:Schedule(30.1, startProshlyapationOfMurchal, self)
		difficultyName = "normal"
	end
end
	
function mod:OnCombatEnd()
	self:Unschedule(startProshlyapationOfMurchal)
	self:UnregisterShortTermEvents()
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end

function mod:OnTimerRecovery()
	if self:IsMythic() then
		difficultyName = "mythic"
	elseif self:IsHeroic() then
		difficultyName = "heroic"
	else
		difficultyName = "normal"
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 405316 then
		specWarnAncientFury:Show()
		specWarnAncientFury:Play("aesoon")
	elseif spellId == 405821 then --Обжигающий удар
		self.vb.slamCount = self.vb.slamCount + 1
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, difficultyName, self.vb.murchalOchkenProshlyapationCount, spellId, self.vb.slamCount+1)
		if timer then
			timerSearingSlamCD:Start(timer, self.vb.slamCount+1)
		end
	elseif spellId == 406851 then
		self.vb.doomCount = self.vb.doomCount + 1
		specWarnDoomFlame:Show(self.vb.doomCount)
		specWarnDoomFlame:Play("helpsoak")
	elseif spellId == 406333 or spellId == 406145 then
		self.vb.blastCount = self.vb.blastCount + 1
		specWarnShadowlavaBlast:Show()
		specWarnShadowlavaBlast:Play("shockwave")
	elseif spellId == 400777 then
		self.vb.smashCount = self.vb.smashCount + 1
		specWarnChargedSmash:Show(self.vb.smashCount)
		specWarnChargedSmash:Play("helpsoak")
		if self.vb.smashCount == 1 then
			timerChargedSmashCD:Start(45.9, self.vb.smashCount+1)
		end
	elseif spellId == 407544 then --Огненный взмах
		self.vb.comboCount = self.vb.comboCount + 1
		self:BossTargetScanner(args.sourceGUID, "FlamingSlashTarget", 0.1, 2)
	--[[	if self:IsTanking("player", "boss1", nil, true) then
			specWarnFlamingSlash:Show()
			specWarnFlamingSlash:Play("defensive")
		else
			--Other tank has this debuff already and it will NOT be gone when cast finishes, TAUNT NOW!
			--This doesn't check TankSwapBehavior dropdown because this always validates that the player about to get hit by this, shouldn't be hit by it
			if UnitExists("boss1target") and not UnitIsUnit("player", "boss1target") then
				local _, _, _, _, _, expireTimeTarget = DBM:UnitDebuff("boss1target", 407547)
				if (expireTimeTarget and expireTimeTarget-GetTime() >= 2) and self:AntiSpam(1, 1) and not UnitIsDeadOrGhost("player") then
					specWarnFlamingSlashTaunt:Show(UnitName("boss1target"))
					specWarnFlamingSlashTaunt:Play("tauntboss")
				end
			end
		end]]
	elseif spellId == 407596 then --Земляное сокрушение
		self.vb.comboCount = self.vb.comboCount + 1
		self:BossTargetScanner(args.sourceGUID, "EarthenCrushTarget", 0.1, 2)
	--[[	if self:IsTanking("player", "boss1", nil, true) then
			specWarnEarthenCrush:Show()
			specWarnEarthenCrush:Play("defensive")
		else
			--Other tank has this debuff already and it will NOT be gone when cast finishes, TAUNT NOW!
			--This doesn't check TankSwapBehavior dropdown because this always validates that the player about to get hit by this, shouldn't be hit by it
			if UnitExists("boss1target") and not UnitIsUnit("player", "boss1target") then
				local _, _, _, _, _, expireTimeTarget = DBM:UnitDebuff("boss1target", 407597)
				if (expireTimeTarget and expireTimeTarget-GetTime() >= 2) and self:AntiSpam(1, 1) and not UnitIsDeadOrGhost("player") then
					specWarnEarthenCrushTaunt:Show(UnitName("boss1target"))
					specWarnEarthenCrushTaunt:Play("tauntboss")
				end
			end
		end]]
	elseif spellId == 410070 then
		self.vb.shadowflameCount = self.vb.shadowflameCount + 1
		specWarnUnleashedShadowflame:Show(self.vb.shadowflameCount)
		specWarnUnleashedShadowflame:Play("specialsoon")--Better voice?
		--4.1, 45.9, 32.9
		local timer = (self.vb.shadowflameCount == 1) and 45.9 or (self.vb.shadowflameCount == 2) and 32.9
		if timer then
			timerUnleashedShadowflameCD:Start(timer, self.vb.shadowflameCount+1)
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 407641 then
		DBM:Debug("Murchal not proshlyap", 2)
--[[	self.vb.firstHitTank = ""
		self.vb.tankCombo = self.vb.tankCombo + 1
		self.vb.comboCount = 0
		local timer = (self.vb.tankCombo == 1) and 14.9 or (self.vb.tankCombo == 2) and 32.9
		if timer then
			timerVolcanicComboCD:Start(timer, self.vb.tankCombo+1)
		end]]
		--22.04.14.379 Пулл босса (обычка)
		--22.04.44.502 1 каст комбы
		--22.04.58.400 2 каст комбы
		--22.05.31.320 3 каст комбы
		--22.06.57.025 4 каст комбы
		--22.07.12.001 5 каст комбы
		--22.07.45.938 6 каст комбы
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 405819 then--405819 confirmed on all difficulties
		if args:IsPlayer() then
			specWarnSearingSlam:Show()
			specWarnSearingSlam:Play("targetyou")
			specWarnSearingSlam:ScheduleVoice(1.5, "defensive")
			yellSearingSlam:Yell()
			yellSearingSlamFades:Countdown(spellId)
		else
			warnSearingSlam:Show(args.destName)
		end
		if self.Options.SetIconOnSearingSlam then
			self:SetIcon(args.destName, 8)
		end
	elseif (spellId == 407597 or spellId == 407547) and not args:IsPlayer() then
		local alertTaunt
		if self.vb.comboCount == 1 then
			self.vb.firstHitTank = args.destName
		end
		if self.Options.TankSwapBehavior == "OnlyIfDanger" then
			--This means there are 0 preemtive taunts at all and you only taunt when a combo hit starts and it's not safe for the current target to take
			--This uses minimum amount of taunts but poses greater risk of messup since it's reactiev only and not proactive
			return
		elseif self.Options.TankSwapBehavior == "DoubleSoak" and self.vb.comboCount == 2 and args.destName == self.vb.firstHitTank then
			--This basically means the first tank took first 2 hits then 2nd tank taunts 3rd
			alertTaunt = true
		elseif self.Options.TankSwapBehavior == "MinMaxSoak" and self.vb.comboCount == 1 then
			--Min Max soaking to spread combo across both tanks to mitigate having one tank eat all the damage
			--Other tank got first part of combo, and you do NOT have debuff for next part of combo, make you taunt next part of combo so one tank doesn't get both debuffs
			--This condition is mostly a "first combo" catch, where the SPELL_CAST_START checks would fail to assign the tanks automatically based on what they took in previous combo
			local checkedSpellId
			if spellId == 407597 then
				checkedSpellId = 407547
			else
				checkedSpellId = 407597
			end
			if not DBM:UnitDebuff("player", checkedSpellId) then
				alertTaunt = true
			end
		end
		if alertTaunt and self:AntiSpam(1, 1) then
			specWarnFlamingSlashTaunt:Show(args.destName)
			specWarnFlamingSlashTaunt:Play("tauntboss")
		end
	elseif spellId == 401419 then --Проводник старейшины
		self:Unschedule(startProshlyapationOfMurchal)
		timerVolcanicComboCD:Stop()
		warnSiphonEnergyApplied:Show(args.destName)
		timerSearingSlamCD:Stop()
		timerChargedSmashCD:Stop()
		timerDoomFlameCD:Stop()
		timerShadowlavaBlastCD:Stop()
		timerAncientFuryCD:Stop()
		timerUnleashedShadowflameCD:Stop()
	elseif spellId == 405827 then
		local amount = args.amount or 1
		overchargedStacks[args.destName] = amount
		if self.Options.InfoFrame then
			DBM.InfoFrame:UpdateTable(overchargedStacks)
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 405819 then
		if args:IsPlayer() then
			yellSearingSlamFades:Cancel()
		end
		if self.Options.SetIconOnSearingSlam then
			self:SetIcon(args.destName, 0)
		end
	elseif spellId == 405827 then
		overchargedStacks[args.destName] = nil
		if self.Options.InfoFrame then
			DBM.InfoFrame:UpdateTable(overchargedStacks)
		end
	elseif spellId == 401419 then --Проводник старейшины
		self.vb.murchalOchkenProshlyapationCount = self.vb.murchalOchkenProshlyapationCount + 1
		self.vb.proshlyapMurchalCount = 0
		warnSiphonEnergyRemoved:Show(args.destName)
		self.vb.slamCount = 0
		self.vb.doomCount = 0
		self.vb.smashCount = 0
		self.vb.tankCombo = 0
		self.vb.comboCount = 0
		self.vb.shadowflameCount = 0
		if self.vb.murchalOchkenProshlyapationCount == 2 then
			timerVolcanicComboCD:Start(31.1, 1)
			self:Schedule(31.1, startProshlyapationOfMurchal, self)
			if self:IsMythic() then
				timerUnleashedShadowflameCD:Start(6.2, 1)
				timerSearingSlamCD:Start(11.1, 1)
			elseif self:IsHeroic() then
				timerSearingSlamCD:Start(11.1, 1) --
			else
				timerSearingSlamCD:Start(10.1, 1) --
			end
			DBM:Debug("Murchal proshlyap 2", 2)
		elseif self.vb.murchalOchkenProshlyapationCount == 3 then
			specWarnShatteredConduit:Show()
			specWarnShatteredConduit:Play("speedup")
			berserkTimer:Start()
			timerVolcanicComboCD:Start(30.2, 1)
			self:Schedule(30.2, startProshlyapationOfMurchal, self)
			if self:IsMythic() then
				timerUnleashedShadowflameCD:Start(6.2, 1)
				timerSearingSlamCD:Start(11.1, 1)
			elseif self:IsHeroic() then
				timerSearingSlamCD:Start(11.1, 1) --
			else
				timerSearingSlamCD:Start(10.1, 1) --пока неизвестно
			end
			DBM:Debug("Murchal proshlyap 3", 2)
		end
		timerChargedSmashCD:Start(23.2, 1)
		timerDoomFlameCD:Start(41.2, 1)
		timerShadowlavaBlastCD:Start(96.8, self.vb.blastCount+1) --2 каст в героике точно
		timerAncientFuryCD:Start(120)
		timerUnyieldingRage:Start()
	elseif spellId == 405091 then
		warnUnyieldingRage:Show()
	end
end

function mod:SPELL_AURA_REMOVED_DOSE(args)
	local spellId = args.spellId
	if spellId == 405827 then
		overchargedStacks[args.destName] = args.amount or 1
		if self.Options.InfoFrame then
			DBM.InfoFrame:UpdateTable(overchargedStacks)
		end
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 403543 and destGUID == UnitGUID("player") and self:AntiSpam(3, 2) and not DBM:UnitDebuff("player", 405819) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE

function mod:SPELL_ENERGIZE(_, _, _, _, destGUID, _, _, _, spellId, _, _, amount)
	if spellId == 405825 and destGUID == UnitGUID("boss1") then
		DBM:Debug("SPELL_ENERGIZE fired on Boss. Amount: "..amount)
		local bossPower = UnitPower("boss1")
--		bossPower = bossPower / 1--1 energy per second, making it every ~100 seconds
		local remaining = 100-bossPower
		if remaining > 0 then
			local elapsedTimer = 100-remaining
			timerAncientFuryCD:Update(elapsedTimer, 100)
			berserkTimer:Update(elapsedTimer, 100)
		else
			timerAncientFuryCD:Stop()
		end
	end
end
