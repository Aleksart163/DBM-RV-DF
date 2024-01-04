local mod	= DBM:NewMod("MPlusAffixes", "DBM-Affixes")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20231226232556")
mod:SetZone()

mod.noStatistics = true

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
local warnAfflictedCry						= mod:NewCastAnnounce(409492, 4, nil, nil, nil, nil, nil, 14) --Крик изнемогающей души spellId, color, castTime, icon, optionDefault, optionName, _, soundOption
local warnDestabalize						= mod:NewCastAnnounce(408805, 4, nil, nil, false) --Дестабилизация
local warnSpitefulFixate					= mod:NewYouAnnounce(350209, 4) --Злобное сосредоточение
--
local warnNecroticWound						= mod:NewStackAnnounce(209858, 3, nil, nil, 2) --Некротическая язва

local specWarnMarkLightning					= mod:NewSpecialWarningYou(396369, nil, nil, nil, 3, 2) --Метка молнии
local specWarnMarkWind						= mod:NewSpecialWarningYou(396364, nil, nil, nil, 3, 2) --Метка ветра
local specWarnMarkLightning2				= mod:NewSpecialWarningEnd(396369, nil, nil, nil, 1, 2) --Метка молнии
local specWarnMarkWind2						= mod:NewSpecialWarningEnd(396364, nil, nil, nil, 1, 2) --Метка ветра
local specWarnNecroticWound					= mod:NewSpecialWarningStack(209858, nil, 10, nil, nil, 1, 3) --Некротическая язва
local specWarnBurst							= mod:NewSpecialWarningDefensive(240443, nil, nil, nil, 3, 3) --Взрыв
local specWarnGrievousWound					= mod:NewSpecialWarningStack(240559, nil, 4, nil, nil, 1, 2) --Тяжкая рана
local specWarnSanguineIchor					= mod:NewSpecialWarningMove(226512, nil, nil, nil, 1, 2) --Кровавый гной
local specWarnQuake							= mod:NewSpecialWarningCast(240447, "SpellCaster", nil, nil, 1, 2) --Землетрясение
local specWarnQuake2						= mod:NewSpecialWarningMoveAway(240447, "Physical", nil, nil, 1, 2) --Землетрясение

local timerIncorporealCD					= mod:NewCDTimer(45, 408801, nil, nil, nil, 5, nil, nil, nil, 3, 3)
--
local timerPrimalOverloadCD					= mod:NewCDTimer(70, 396411, nil, nil, nil, 7) --Изначальная перегрузка
local timerMarkLightning					= mod:NewBuffActiveTimer(15, 396369, nil, nil, nil, 7, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Метка молнии
local timerMarkWind							= mod:NewBuffActiveTimer(15, 396364, nil, nil, nil, 7, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Метка ветра
local timerQuake							= mod:NewCastTimer(2.5, 240447, nil, nil, nil, 2, nil, DBM_COMMON_L.INTERRUPT_ICON..DBM_COMMON_L.DEADLY_ICON, nil, 2, 2.5) --Землетрясение
local timerNecroticWound					= mod:NewBuffActiveTimer(9, 209858, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.HEALER_ICON) --Некротическая язва
local timerBurst							= mod:NewBuffActiveTimer(4, 240443, nil, nil, nil, 3, nil, DBM_COMMON_L.MYTHIC_ICON..DBM_COMMON_L.DEADLY_ICON) --Взрыв

local yellPrimalOverload					= mod:NewPosYell(396411, DBM_CORE_L.AUTO_YELL_CUSTOM_POSITION2, nil, nil, "YELL") --Изначальная перегрузка
local yellMarkLightning						= mod:NewFadesYell(396369, nil, nil, nil, "YELL") --Метка молнии
local yellMarkWind							= mod:NewFadesYell(396364, nil, nil, nil, "YELL") --Метка ветра

mod:AddNamePlateOption("NPSanguine", 226510, "Tank")

local dota5s = false
local Lightning = false
local Wind = false
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

local function ProshlyapationOfMurchal(self) --Изначальная перегрузка
	if Lightning then
		yellPrimalOverload:Yell(6, MarkLightning, 6)
		self:Schedule(4, ProshlyapationOfMurchal, self)
	elseif Wind then
		yellPrimalOverload:Yell(7, MarkWind, 7)
		self:Schedule(4, ProshlyapationOfMurchal, self)
	end
end

local function CheckProshlyapationOfMurchal(self)
	if Lightning and timerMarkLightning:GetTime() == 3 then
		yellPrimalOverload:Cancel()
	elseif Wind and timerMarkWind:GetTime() == 3 then
		yellPrimalOverload:Cancel()
	end
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

--UGLY function to detect this because there isn't a good API for this.
--player regen was very unreliable due to fact it only fires for self
--This wastes cpu time being an infinite loop though but probably no more so than any WA doing this
--[[
local function checkForCombatRas(self)
	local combatFound = self:GroupInCombat()
	if combatFound and not overloadCounting then
		overloadCounting = true
		timerPrimalOverloadCD:Resume()
		local overloadRemaining = timerPrimalOverloadCD:GetRemaining()
		if overloadRemaining and overloadRemaining > 0 then
			self:Unschedule(checkPrimalOverload)
		end
	elseif not combatFound and overloadCounting then
		overloadCounting = false
		timerPrimalOverloadCD:Pause()
		self:Unschedule(checkPrimalOverload)
	end
	self:Schedule(0.25, checkForCombatRas, self)
end]]

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
				DBM:Debug("Experimental reschedule of checkIncorp running because you're in debug mode")
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
				DBM:Debug("Experimental reschedule of checkAfflicted running because you're in debug mode")
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

--[[
local function MarkLightningOnPlayer(self) --Метка молнии
--	if UnitDebuff("player", 396369) then
	yellPrimalOverload:Yell(6, MarkLightning, 6)
	self:Schedule(3, MarkLightningOnPlayer, self)
--	end
end

local function MarkWindOnPlayer(self) --Метка ветра
--	if UnitDebuff("player", 396364) then
	yellPrimalOverload:Yell(6, MarkWind, 6)
	self:Schedule(3, MarkWindOnPlayer, self)
--	end
end]]

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
		self:Schedule(35, checkAfflicted, self)
	elseif spellId == 408805 and self:AntiSpam(3, "aff3") then
		warnDestabalize:Show()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 240447 then --Землетрясение
		if args:IsPlayer() then
			specWarnQuake:Show()
			specWarnQuake:Play("runaway")
			specWarnQuake2:Show()
			specWarnQuake2:Play("runaway")
			timerQuake:Start()
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
	elseif spellId == 396364 or spellId == 396369 then --Изначальная перегрузка
		if spellId == 396369 then --Метка молнии
			if args:IsPlayer() then
				Lightning = true
				specWarnMarkLightning:Show()
				specWarnMarkLightning:Play("gathershare")
				yellPrimalOverload:Yell(6, MarkLightning, 6) --Синяя
				yellMarkLightning:Countdown(spellId, 3)
				timerMarkLightning:Start(args.destName)
				self:Schedule(4, ProshlyapationOfMurchal, self)
			--	self:Schedule(12, CheckProshlyapationOfMurchal, self)
			end
		elseif spellId == 396364 then --Метка ветра
			if args:IsPlayer() then
				Wind = true
				specWarnMarkWind:Show()
				specWarnMarkWind:Play("gathershare")
				yellPrimalOverload:Yell(7, MarkWind, 7) --Красная
				yellMarkWind:Countdown(spellId, 3)
				timerMarkWind:Start(args.destName)
				self:Schedule(4, ProshlyapationOfMurchal, self)
			--	self:Schedule(12, CheckProshlyapationOfMurchal, self)
			end
		end
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
			specWarnMarkLightning2:Show()
			specWarnMarkLightning2:Play("end")
			self:Unschedule(ProshlyapationOfMurchal)
			yellMarkLightning:Cancel()
			timerMarkLightning:Cancel(args.destName)
		end
	elseif spellId == 396364 then --Метка ветра
		if args:IsPlayer() then
			Wind = false
			specWarnMarkWind2:Show()
			specWarnMarkWind2:Play("end")
			self:Unschedule(ProshlyapationOfMurchal)
			yellMarkWind:Cancel()
			timerMarkWind:Cancel(args.destName)
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
	if msg == L.RasAffix1 or msg == L.RasAffix2 then
		DBM:Debug("Check Raszageth")
		if not overloadDetected then
			overloadDetected = true
		end
		self:Unschedule(checkForCombat)
		checkForCombat(self)
--		self:Unschedule(checkForCombatRas)
--		checkForCombatRas(self)
--		self:SendSync("MurchalProshlyapation")
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
function mod:OnSync(msg)
	if msg == "MurchalProshlyapation" then
		self:Unschedule(checkForCombatRas)
		checkForCombatRas(self)
	end
end]]
