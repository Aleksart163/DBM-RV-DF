local mod	= DBM:NewMod("MPlusAffixes", "DBM-Affixes")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240201052201")
mod:SetZone()

mod.noStatistics = true
mod.isTrashModBossFightAllowed = true

mod:RegisterEvents(
	"SPELL_CAST_START 240446 409492 408805",
	"SPELL_AURA_APPLIED 408801 408556 350209 226512 226510 240447 240559 209858 240443 396369 396364",
	"SPELL_AURA_APPLIED_DOSE 240559 209858 240443",
	"SPELL_AURA_REMOVED 226510 240447 240559 240443 396369 396364",
	"SPELL_PERIODIC_DAMAGE 226512 240559",
	"SPELL_PERIODIC_MISSED 226512 240559",
	"CHAT_MSG_MONSTER_YELL",
	"CHALLENGE_MODE_COMPLETED"
)

--Прошляпанное очко Мурчаля Прошляпенко [✔✔✔]
local warnExplosion							= mod:NewCastAnnounce(240446, 4) --Взрыв
local warnIncorporeal						= mod:NewCastAnnounce(408801, 4) --Бесплотность
local warnAfflictedCry						= mod:NewCastAnnounce(409492, 4, nil, nil, "Healer|RemoveMagic|RemoveCurse|RemoveDisease|RemovePoison", 2, nil, 14) --Крик изнемогающей души Flagged to only warn players who actually have literally any skill to deal with spirits, else alert is just extra noise to some rogue or warrior with no skills for mechanic
local warnDestabalize						= mod:NewCastAnnounce(408805, 4, nil, nil, false) --Дестабилизация
--
local warnNecroticWound						= mod:NewStackAnnounce(209858, 3, nil, nil, 2) --Некротическая язва

local specWarnSpitefulFixate				= mod:NewSpecialWarningYou(350209, nil, nil, 2, 1, 2) --Злобное преследование
local specWarnMarkLightning					= mod:NewSpecialWarningYou(396369, nil, nil, nil, 1, 2) --Метка молнии
local specWarnMarkLightning2				= mod:NewSpecialWarningEnd(396369, nil, nil, nil, 1, 2) --Метка молнии
local specWarnMarkWind						= mod:NewSpecialWarningYou(396364, nil, nil, nil, 1, 2) --Метка ветра
local specWarnMarkWind2						= mod:NewSpecialWarningEnd(396364, nil, nil, nil, 1, 2) --Метка ветра
local specWarnNecroticWound					= mod:NewSpecialWarningStack(209858, nil, 10, nil, nil, 1, 3) --Некротическая язва
local specWarnBurst							= mod:NewSpecialWarningDefensive(240443, nil, nil, nil, 3, 3) --Взрыв
local specWarnGrievousWound					= mod:NewSpecialWarningStack(240559, nil, 4, nil, nil, 1, 2) --Тяжкая рана
local specWarnSanguineIchor					= mod:NewSpecialWarningMove(226512, nil, nil, nil, 1, 2) --Кровавый гной
local specWarnQuake							= mod:NewSpecialWarningCast(240447, "SpellCaster", nil, nil, 1, 2) --Землетрясение
local specWarnQuake2						= mod:NewSpecialWarningMoveAway(240447, "Physical", nil, nil, 1, 2) --Землетрясение
--
local timerPrimalOverloadCD					= mod:NewCDTimer(70, 396411, nil, nil, nil, 7) --Изначальная перегрузка
local timerMarkLightning					= mod:NewBuffActiveTimer(15, 396369, nil, nil, nil, 7, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Метка молнии
local timerMarkWind							= mod:NewBuffActiveTimer(15, 396364, nil, nil, nil, 7, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Метка ветра
local timerQuake							= mod:NewCastTimer(2.5, 240447, nil, nil, nil, 2, nil, DBM_COMMON_L.INTERRUPT_ICON..DBM_COMMON_L.DEADLY_ICON, nil, 2, 2.5) --Землетрясение
local timerNecroticWound					= mod:NewBuffActiveTimer(9, 209858, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.HEALER_ICON) --Некротическая язва
local timerBurst							= mod:NewBuffActiveTimer(4, 240443, nil, nil, nil, 3, nil, DBM_COMMON_L.MYTHIC_ICON..DBM_COMMON_L.DEADLY_ICON) --Взрыв
--
local timerQuakingCD						= mod:NewNextTimer(20, 240447, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON)
local timerEntangledCD						= mod:NewCDTimer(30, 408556, nil, nil, nil, 3, 396347, nil, nil, 2, 3, nil, nil, nil, true)
local timerAfflictedCD						= mod:NewCDTimer(30, 409492, nil, nil, nil, 5, 2, DBM_COMMON_L.HEALER_ICON, nil, mod:IsHealer() and 3 or nil, 3)--Timer is still on for all, cause knowing when they spawn still informs decisions like running ahead or pulling
local timerIncorporealCD					= mod:NewCDTimer(45, 408801, nil, nil, nil, 5, nil, nil, nil, 3, 3)

local yellPrimalOverload					= mod:NewPosYell(396411, DBM_CORE_L.AUTO_YELL_CUSTOM_POSITION2, nil, nil, "YELL") --Изначальная перегрузка
local yellMarkLightning						= mod:NewFadesYell(396369, nil, nil, nil, "YELL") --Метка молнии
local yellMarkWind							= mod:NewFadesYell(396364, nil, nil, nil, "YELL") --Метка ветра

mod:AddBoolOption("MurchalOchkenProshlyapen", true)
mod:AddNamePlateOption("NPSanguine", 226510, "Tank")

local dota5s = false
local Lightning = false
local Wind = false
local checkMarks = false
--
local overloadCounting = false
local overloadDetected = false
local incorporealCounting = false
local incorpDetected = false
local afflictedCounting = false
local afflictedDetected = false
--
local MarkLightning = SpellLinks(396369) --Метка молнии
local MarkWind = SpellLinks(396364) --Метка ветра

mod.vb.murchalsProshlyapCount = 0
mod.vb.mProshlyapCount = 0

local function startProshlyapationOfMurchal(self) --Изначальная перегрузка
	self.vb.mProshlyapCount = self.vb.mProshlyapCount + 1
	if Lightning and self.vb.mProshlyapCount < 4 then
		yellPrimalOverload:Yell(6, MarkLightning, 6)
		self:Schedule(2.5, startProshlyapationOfMurchal, self)
	elseif Wind and self.vb.mProshlyapCount < 4 then
		yellPrimalOverload:Yell(7, MarkWind, 7)
		self:Schedule(2.5, startProshlyapationOfMurchal, self)
	elseif self.vb.mProshlyapCount == 4 then
		self.vb.mProshlyapCount = 0
		self:Unschedule(startProshlyapationOfMurchal)
	end
end

local function stopProshlyapationOfMurchal(self)
	if self:AntiSpam(15.5, "MarkOfWind") then
		specWarnMarkWind2:Show()
		specWarnMarkWind2:Play("end")
	end
	yellPrimalOverload:Cancel()
	yellMarkWind:Cancel()
	timerMarkWind:Cancel()
	self.vb.mProshlyapCount = 0
	self:Unschedule(startProshlyapationOfMurchal)
end

local function ProshlyapationOfMurchal(self)
	self.vb.murchalsProshlyapCount = 0
end

local function checkEntangled(self)
	if timerEntangledCD:GetRemaining() > 0 then
		--Timer exists, do nothing
		return
	end
	timerEntangledCD:Start(25)
	self:Schedule(30, checkEntangled, self)
end

local function checkAfflicted(self)
	if timerAfflictedCD:GetRemaining() > 0 then
		--Timer exists, do nothing
		return
	end
	timerAfflictedCD:Start(20)
	self:Schedule(30, checkAfflicted, self)
end

local function checkIncorp(self)
	if timerIncorporealCD:GetRemaining() > 0 then
		--Timer exists, do nothing
		return
	end
	timerIncorporealCD:Start(35)
	self:Schedule(45, checkIncorp, self)
end

local function checkPrimalOverload(self)
	if timerPrimalOverloadCD:GetRemaining() > 0 then
		--Timer exists, do nothing
		return
	end
	timerPrimalOverloadCD:Start(60)
	self:Schedule(70, checkPrimalOverload, self)
end

local function checkForCombat(self)
	local combatFound = self:GroupInCombat()
	if incorpDetected then
		if combatFound and not incorporealCounting then
			incorporealCounting = true
			timerIncorporealCD:Resume()
			local incorpRemaining = timerIncorporealCD:GetRemaining()
			if incorpRemaining and incorpRemaining > 0 then--Shouldn't be 0, unless a player clicked it off, in which case we can't reschedule
				self:Unschedule(checkIncorp)
				self:Schedule(incorpRemaining+10, checkIncorp, self)
				DBM:Debug("Experimental reschedule of checkIncorp running")
			end
		elseif not combatFound and incorporealCounting then
			incorporealCounting = false
			timerIncorporealCD:Pause()
			self:Unschedule(checkIncorp)--Soon as a pause happens this can no longer be trusted
		end
	end
	if afflictedDetected then
		if combatFound and not afflictedCounting then
			afflictedCounting = true
			timerAfflictedCD:Resume()
			local afflictRemaining = timerAfflictedCD:GetRemaining()
			if afflictRemaining and afflictRemaining > 0 then--Shouldn't be 0, unless a player clicked it off, in which case we can't reschedule
				self:Unschedule(checkAfflicted)
				self:Schedule(afflictRemaining+10, checkAfflicted, self)
				DBM:Debug("Experimental reschedule of checkAfflicted running")
			end
		elseif not combatFound and afflictedCounting then
			afflictedCounting = false
			timerAfflictedCD:Pause()
			self:Unschedule(checkAfflicted)--Soon as a pause happens this can no longer be trusted
		end
	end
	if overloadDetected then
		if combatFound and not overloadCounting then
			overloadCounting = true
			timerPrimalOverloadCD:Resume()
			local overloadRemaining = timerPrimalOverloadCD:GetRemaining()
			if overloadRemaining and overloadRemaining > 0 then
				self:Unschedule(checkPrimalOverload)
				self:Schedule(overloadRemaining+10, checkPrimalOverload, self)
			end
		elseif not combatFound and overloadCounting then
			overloadCounting = false
			timerPrimalOverloadCD:Pause()
			self:Unschedule(checkPrimalOverload)
		end
	end
	self:Schedule(0.25, checkForCombat, self)
end

function mod:SPELL_CAST_START(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 240446 and self:AntiSpam(3, "aff1") then
		warnExplosion:Show()
	elseif spellId == 409492 and self:AntiSpam(3, "aff2") then
		warnAfflictedCry:Show()
		warnAfflictedCry:Play("helpspirit")
		if not afflictedDetected then
			afflictedDetected = true
		end
		--This one is interesting cause it runs every 30 seconds, sometimes skips a cast and goes 60, but also pauses out of combat
		afflictedCounting = true
		timerAfflictedCD:Start()
		self:Unschedule(checkForCombat)
		self:Unschedule(checkAfflicted)
		checkForCombat(self)
		self:Schedule(40, checkAfflicted, self)
	elseif spellId == 408805 and self:AntiSpam(3, "aff3") then
		warnDestabalize:Show()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 240447 then --Землетрясение
		if self:AntiSpam(3, "aff5") then
			timerQuakingCD:Start()
			timerQuake:Start()
		end
		if self:IsSpellCaster() and self:AntiSpam(2, "Quake") then
			specWarnQuake:Show()
			specWarnQuake:Play("stopcast")
		elseif self:IsMelee() and self:AntiSpam(2, "Quake") then
			specWarnQuake2:Show()
			specWarnQuake2:Play("range5")
		end
	elseif spellId == 240559 then --Тяжкая рана
		local amount = args.amount or 1
		if args:IsPlayer() then
			if amount >= 4 then
				specWarnGrievousWound:Show(amount)
				specWarnGrievousWound:Play("stackhigh")
				dota5s = true
			end
		end
	elseif spellId == 209858 and args:IsDestTypePlayer() then --Некротическая язва
		local amount = args.amount or 1
		timerNecroticWound:Start(args.destName)
		if amount >= 10 and amount % 5 == 0 then
			if args:IsPlayer() then
				specWarnNecroticWound:Show(amount)
				specWarnNecroticWound:Play("stackhigh")
			else
				warnNecroticWound:Show(args.destName, amount)
			end
		end
	elseif spellId == 240443 and args:IsDestTypePlayer() then --Взрыв
		local amount = args.amount or 1
		if args:IsPlayer() then
			timerBurst:Start(args.destName)
			if amount == 7 then
				specWarnBurst:Show()
				specWarnBurst:Play("stackhigh")
			elseif amount >= 10 and amount % 5 == 0 and self:AntiSpam(3, "burst") then
				specWarnBurst:Show()
				specWarnBurst:Play("stackhigh")
			end
		end
	elseif spellId == 396369 then --Метка молнии
		if args:IsPlayer() then
			Lightning = true
			specWarnMarkLightning:Show()
			specWarnMarkLightning:Play("gathershare")
			if self.Options.MurchalOchkenProshlyapen then
				yellPrimalOverload:Yell(6, MarkLightning, 6) --Синяя
				yellMarkLightning:Countdown(spellId, 3)
				timerMarkLightning:Start(args.destName)
				self:Schedule(2.5, startProshlyapationOfMurchal, self)
			end
		end
	elseif spellId == 396364 then --Метка ветра
		if args:IsPlayer() then
			Wind = true
			specWarnMarkWind:Show()
			specWarnMarkWind:Play("gathershare")
			if self.Options.MurchalOchkenProshlyapen then
				yellPrimalOverload:Yell(7, MarkWind, 7) --Красная
				yellMarkWind:Countdown(spellId, 3)
				timerMarkWind:Start(args.destName)
				self:Schedule(2.5, startProshlyapationOfMurchal, self)
			end
		end
	elseif spellId == 350209 and args:IsPlayer() and self:AntiSpam(5, "spitefulFixate") then
		specWarnSpitefulFixate:Show()
		specWarnSpitefulFixate:Play("targetyou")
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 240447 then --Землетрясение
		timerQuake:Stop()
	elseif spellId == 209858 then --Некротическая язва
		timerNecroticWound:Cancel(args.destName)
	elseif spellId == 240559 then --Тяжкая рана
		if args:IsPlayer() then
			dota5s = false
		end
	elseif spellId == 240443 then --Взрыв
		if args:IsPlayer() then
			timerBurst:Cancel(args.destName)
		end
	elseif spellId == 396369 then --Метка молнии
		if args:IsPlayer() then
			Lightning = false
			self.vb.mProshlyapCount = 0
			specWarnMarkLightning2:Show()
			specWarnMarkLightning2:Play("end")
			if self.Options.MurchalOchkenProshlyapen then
				self:Unschedule(startProshlyapationOfMurchal)
				yellMarkLightning:Cancel()
				timerMarkLightning:Cancel(args.destName)
			end
		end
	elseif spellId == 396364 then --Метка ветра
		self.vb.murchalsProshlyapCount = self.vb.murchalsProshlyapCount - 1
		if args:IsPlayer() then
			Wind = false
			self.vb.mProshlyapCount = 0
			if self:AntiSpam(15.5, "MarkOfWind") then
				specWarnMarkWind2:Show()
				specWarnMarkWind2:Play("end")
			end
			if self.Options.MurchalOchkenProshlyapen then
				self:Unschedule(startProshlyapationOfMurchal)
				yellMarkWind:Cancel()
				timerMarkWind:Cancel(args.destName)
			end
		end
		if self.vb.murchalsProshlyapCount == 1 then
			self:Schedule(0.1, stopProshlyapationOfMurchal, self)
		end
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 226512 and destGUID == UnitGUID("player") and self:AntiSpam(2, "sanguine") then --Кровавый гной
		specWarnSanguineIchor:Show()
		specWarnSanguineIchor:Play("runaway")
	elseif spellId == 240559 and destGUID == UnitGUID("player") then --Тяжкая рана
		if dota5s then
			if self:AntiSpam(7, "grievous") then
				specWarnGrievousWound:Show(4)
				specWarnGrievousWound:Play("stackhigh")
			end
		end
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.AfRaszageth1 or msg == L.AfRaszageth2 then
		self.vb.murchalsProshlyapCount = 3
		self:Schedule(18.5, ProshlyapationOfMurchal, self)
		if not overloadDetected then
			overloadDetected = true
		end
		self:Unschedule(checkForCombat)
		checkForCombat(self)
	end
end

function mod:CHALLENGE_MODE_COMPLETED()
	overloadCounting = false
	overloadDetected = false
	afflictedCounting = false
	incorporealCounting = false
	incorpDetected = false
	afflictedDetected = false
	self:Unschedule(checkForCombat)
end

--[[
local mod	= DBM:NewMod("MPlusAffixes", "DBM-Affixes")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240305165926")
--mod:SetModelID(47785)
mod:SetZone(DBM_DISABLE_ZONE_DETECTION)--Stays active in all zones for zone change handlers, but registers events based on dungeon ids

mod.isTrashMod = true
mod.isTrashModBossFightAllowed = true

mod:RegisterEvents(
	"ZONE_CHANGED_NEW_AREA",
	"LOADING_SCREEN_DISABLED"
)

--TODO, fine tune tank stacks/throttle?
--[[
(ability.id = 240446 or ability.id = 409492) and type = "begincast"
 or (ability.id = 408556 or ability.id = 408801) and type = "applydebuff"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
 or (source.type = "NPC" and source.firstSeen = timestamp) and (source.name = "Afflicted Soul") or (target.type = "NPC" and target.firstSeen = timestamp) and (target.name = "Afflicted Soul")

local warnExplosion							= mod:NewCastAnnounce(240446, 4)
local warnIncorporeal						= mod:NewCastAnnounce(408801, 4)
local warnAfflictedCry						= mod:NewCastAnnounce(409492, 4, nil, nil, "Healer|RemoveMagic|RemoveCurse|RemoveDisease|RemovePoison", 2, nil, 14)--Flagged to only warn players who actually have literally any skill to deal with spirits, else alert is just extra noise to some rogue or warrior with no skills for mechanic
local warnDestabalize						= mod:NewCastAnnounce(408805, 4, nil, nil, false)
local warnSpitefulFixate					= mod:NewYouAnnounce(350209, 4)

local specWarnQuake							= mod:NewSpecialWarningMoveAway(240447, nil, nil, nil, 1, 2)
local specWarnSpitefulFixate				= mod:NewSpecialWarningYou(350209, false, nil, 2, 1, 2)
local specWarnEntangled						= mod:NewSpecialWarningYou(408556, nil, nil, nil, 1, 14)

local specWarnGTFO							= mod:NewSpecialWarningGTFO(209862, nil, nil, nil, 1, 8)--Volcanic and Sanguine

local timerQuakingCD						= mod:NewNextTimer(20, 240447, nil, nil, nil, 3)
local timerEntangledCD						= mod:NewCDTimer(30, 408556, nil, nil, nil, 3, 396347, nil, nil, 2, 3, nil, nil, nil, true)
local timerAfflictedCD						= mod:NewCDTimer(30, 409492, nil, nil, nil, 5, 2, DBM_COMMON_L.HEALER_ICON, nil, mod:IsHealer() and 3 or nil, 3)--Timer is still on for all, cause knowing when they spawn still informs decisions like running ahead or pulling
local timerIncorporealCD					= mod:NewCDTimer(45, 408801, nil, nil, nil, 5, nil, nil, nil, 3, 3)

mod:AddNamePlateOption("NPSanguine", 226510, "Tank")

--Antispam IDs for this mod: 1 run away, 2 dodge, 3 dispel, 4 incoming damage, 5 you/role, 6 misc, 7 gtfo, 8 personal aggregated alert

local incorporealCounting = false
local incorpDetected = false
local afflictedCounting = false
local afflictedDetected = false

local function checkEntangled(self)
	if timerEntangledCD:GetRemaining() > 0 then
		--Timer exists, do nothing
		return
	end
	timerEntangledCD:Start(25)
	self:Schedule(30, checkEntangled, self)
end

local function checkAfflicted(self)
	if timerAfflictedCD:GetRemaining() > 0 then
		--Timer exists, do nothing
		return
	end
	timerAfflictedCD:Start(20)
	self:Schedule(30, checkAfflicted, self)
end

local function checkIncorp(self)
	if timerIncorporealCD:GetRemaining() > 0 then
		--Timer exists, do nothing
		return
	end
	timerIncorporealCD:Start(35)
	self:Schedule(45, checkIncorp, self)
end

--UGLY function to detect this because there isn't a good API for this.
--player regen was very unreliable due to fact it only fires for self
--This wastes cpu time being an infinite loop though but probably no more so than any WA doing this
local function checkForCombat(self)
	local combatFound = self:GroupInCombat()
	if incorpDetected then
		if combatFound and not incorporealCounting then
			incorporealCounting = true
			timerIncorporealCD:Resume()
			local incorpRemaining = timerIncorporealCD:GetRemaining()
			if incorpRemaining and incorpRemaining > 0 then--Shouldn't be 0, unless a player clicked it off, in which case we can't reschedule
				self:Unschedule(checkIncorp)
				self:Schedule(incorpRemaining+10, checkIncorp, self)
				DBM:Debug("Experimental reschedule of checkIncorp running")
			end
		elseif not combatFound and incorporealCounting then
			incorporealCounting = false
			timerIncorporealCD:Pause()
			self:Unschedule(checkIncorp)--Soon as a pause happens this can no longer be trusted
		end
	end
	if afflictedDetected then
		if combatFound and not afflictedCounting then
			afflictedCounting = true
			timerAfflictedCD:Resume()
			local afflictRemaining = timerAfflictedCD:GetRemaining()
			if afflictRemaining and afflictRemaining > 0 then--Shouldn't be 0, unless a player clicked it off, in which case we can't reschedule
				self:Unschedule(checkAfflicted)
				self:Schedule(afflictRemaining+10, checkAfflicted, self)
				DBM:Debug("Experimental reschedule of checkAfflicted running")
			end
		elseif not combatFound and afflictedCounting then
			afflictedCounting = false
			timerAfflictedCD:Pause()
			self:Unschedule(checkAfflicted)--Soon as a pause happens this can no longer be trusted
		end
	end
	self:Schedule(0.25, checkForCombat, self)
end

do
	local validZones
	if (C_MythicPlus.GetCurrentSeason() or 0) == 9 then--DF Season 1
		--2516, 2526, 2515, 2521, 1477, 1571, 1176, 960
		validZones = {[2516]=true, [2526]=true, [2515]=true, [2521]=true, [1477]=true, [1571]=true, [1176]=true, [960]=true}
	elseif (C_MythicPlus.GetCurrentSeason() or 0) == 10 then--DF Season 2
		--657, 1841, 1754, 1458, 2527, 2519, 2451, 2520
		validZones = {[657]=true, [1841]=true, [1754]=true, [1458]=true, [2527]=true, [2519]=true, [2451]=true, [2520]=true}
	elseif (C_MythicPlus.GetCurrentSeason() or 0) == 12 then--DF Season 4
		--NOT YET KNOWN, season 3 placeholders
		validZones = {[2579]=true, [1279]=true, [1501]=true, [1466]=true, [1763]=true, [643]=true, [1862]=true}
	else--Season 3 (11) (latest LIVE season put in else so if api fails, it just always returns latest)
		--2579, 1279, 1501, 1466, 1763, 643, 1862
		validZones = {[2579]=true, [1279]=true, [1501]=true, [1466]=true, [1763]=true, [643]=true, [1862]=true}
	end
	local eventsRegistered = false
	function mod:DelayedZoneCheck(force)
		local currentZone = DBM:GetCurrentArea() or 0
		if not force and validZones[currentZone] and not eventsRegistered then
			eventsRegistered = true
			self:RegisterShortTermEvents(
				"SPELL_CAST_START 240446 409492 408805",
			--	"SPELL_CAST_SUCCESS",
				"SPELL_AURA_APPLIED 240447 226510 226512 350209 408556 408801",
			--	"SPELL_AURA_APPLIED_DOSE",
				"SPELL_AURA_REMOVED 226510",
--				"SPELL_DAMAGE 209862",
--				"SPELL_MISSED 209862",
				"CHALLENGE_MODE_COMPLETED"
			)
			if self.Options.NPSanguine then
				DBM:FireEvent("BossMod_EnableHostileNameplates")
			end
			DBM:Debug("Registering M+ events")
		elseif force or (not validZones[currentZone] and eventsRegistered) then
			eventsRegistered = false
			afflictedCounting = false
			incorporealCounting = false
			incorpDetected = false
			afflictedDetected = false
			self:UnregisterShortTermEvents()
			self:Unschedule(checkForCombat)
			self:Unschedule(checkEntangled)
			self:Unschedule(checkAfflicted)
			self:Stop()
			if self.Options.NPSanguine then
				DBM.Nameplate:Hide(true, nil, nil, nil, true, true)
			end
			DBM:Debug("Unregistering M+ events")
		end
	end
	function mod:LOADING_SCREEN_DISABLED()
		self:UnscheduleMethod("DelayedZoneCheck")
		--Checks Delayed 1 second after core checks to prevent race condition of checking before core did and updated cached ID
		self:ScheduleMethod(2, "DelayedZoneCheck")
		self:ScheduleMethod(6, "DelayedZoneCheck")
	end
	mod.OnInitialize = mod.LOADING_SCREEN_DISABLED
	mod.ZONE_CHANGED_NEW_AREA	= mod.LOADING_SCREEN_DISABLED

	function mod:CHALLENGE_MODE_COMPLETED()
		--This basically force unloads things even when in a dungeon, so it's not countdown affixes that are disabled
		self:DelayedZoneCheck(true)
	end
end

function mod:SPELL_CAST_START(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 240446 and self:AntiSpam(3, "aff1") then
		warnExplosion:Show()
	elseif spellId == 409492 and self:AntiSpam(3, "aff2") then
		warnAfflictedCry:Show()
		warnAfflictedCry:Play("helpspirit")
		if not afflictedDetected then
			afflictedDetected = true
		end
		--This one is interesting cause it runs every 30 seconds, sometimes skips a cast and goes 60, but also pauses out of combat
		afflictedCounting = true
		timerAfflictedCD:Start()
		self:Unschedule(checkForCombat)
		self:Unschedule(checkAfflicted)
		checkForCombat(self)
		self:Schedule(40, checkAfflicted, self)
	elseif spellId == 408805 and self:AntiSpam(3, "aff3") then
		warnDestabalize:Show()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 240447 then
		if self:AntiSpam(3, "aff5") then
			timerQuakingCD:Start()
		end
		if args:IsPlayer() then
			specWarnQuake:Show()
			specWarnQuake:Play("range5")
		end
	elseif spellId == 226512 and args:IsPlayer() and self:AntiSpam(3, "aff4") then--Sanguine Ichor on player
		specWarnGTFO:Show(args.spellName)
		specWarnGTFO:Play("watchfeet")
	elseif spellId == 226510 then--Sanguine Ichor on mob
		if self.Options.NPSanguine then
			DBM.Nameplate:Show(true, args.destGUID, spellId)
		end
	elseif spellId == 350209 and args:IsPlayer() and self:AntiSpam(3, "aff5") then
		if self.Options.Specwarn350209you then
			specWarnSpitefulFixate:Show()
			specWarnSpitefulFixate:Play("targetyou")
		else
			warnSpitefulFixate:Show()
		end
	elseif spellId == 408556 then
		if self:AntiSpam(20, "aff6") then
			timerEntangledCD:Start(30)
			--Entangled check runs every 30 seconds, and if conditions aren't met for it activating it skips and goes into next 30 second CD
			--This checks if it was cast (by seeing if timer exists) if not, it starts next timer for next possible cast
			self:Unschedule(checkEntangled)
			self:Schedule(35, checkEntangled, self)
		end
		if args:IsPlayer() then
			specWarnEntangled:Show()
			specWarnEntangled:Play("breakvine")--breakvine
		end
	elseif spellId == 408801 and self:AntiSpam(25, "aff7") then
		if not incorpDetected then
			incorpDetected = true
		end
		--This one is interesting cause it runs every 45 seconds, sometimes skips a cast and goes 90, but also pauses out of combat
		incorporealCounting = true
		timerIncorporealCD:Start()
		self:Unschedule(checkForCombat)
		self:Unschedule(checkIncorp)
		checkForCombat(self)
		self:Schedule(50, checkIncorp, self)
	end
end
--mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 226510 then--Sanguine Ichor on mob
		if self.Options.NPSanguine then
			DBM.Nameplate:Hide(true, args.destGUID, spellId)
		end
	end
end

--[[
function mod:SPELL_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 209862 and destGUID == UnitGUID("player") and self:AntiSpam(3, "aff7") then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_MISSED = mod.SPELL_DAMAGE
--]]

--<610.64 01:20:34> [CHAT_MSG_MONSTER_YELL] Marked by lightning!#Raszageth###Global Affix Stalker##0#0##0#3611#nil#0#false#false#false#false", -- [3882]
--<614.44 01:20:38> [CLEU] SPELL_AURA_APPLIED#Creature-0-3023-1477-12533-199388-00007705B2#Raszageth#Player-3726-0C073FB8#Onlysummonz-Khaz'goroth#396364#Mark of Wind#DEBUFF#nil", -- [3912]
