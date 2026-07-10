local mod	= DBM:NewMod("MPlusAffixes", "DBM-Affixes")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260427070000")
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
--	"LOADING_SCREEN_DISABLED",
	"CHALLENGE_MODE_COMPLETED",
	"CHALLENGE_MODE_RESET"
)

--Новые прошляпы Мурчаля Прошляпенко [✔✔✔]
--Рубиновые Омуты Жизни 2521, ﻿Наступление клана Нокхуд 2516, Лазурное Хранилище 2515, Академия Алгет'ар 2526, Чертоги доблести 1477, Квартал звёзд 1571, Некрополь призрачной луны 1176, Храм нефритовой змеи 960
--﻿Ульдаман: Наследие Тира 2451, Чертоги Насыщения 2527, Лощина Бурошкуров 2520, Нелтарий 2519, Логово Нелтариона 1458, Подгнилье 1841, Вольная Гавань 1754, Вершина Смерча 657
--﻿Рассвет Бесконечности (2 квартала) 2579, ﻿﻿Усадьба Уэйкрестов 1862, ﻿﻿Атал'Дазар 1763, Чаща Темного Сердца 1466, ﻿﻿Крепость Черной Ладьи 1501, Вечное цветение 1279, Трон Приливов 643
--﻿Ульдаман: Наследие Тира 2451, Чертоги Насыщения 2527, Лощина Бурошкуров 2520, Нелтарий 2519, Рубиновые Омуты Жизни 2521, Наступление клана Нокхуд 2516, Лазурное Хранилище 2515, Академия Алгет'ар 2526

local warnExplosion							= mod:NewCastAnnounce(240446, 4) --Взрыв
--local warnIncorporeal						= mod:NewCastAnnounce(408801, 4) --Бесплотность
local warnAfflictedCry						= mod:NewCastAnnounce(409492, 2, nil, nil, "Healer|RemoveMagic|RemoveCurse|RemoveDisease|RemovePoison", 2, nil, 14) --Крик изнемогающей души (Призыв духов)
local warnDestabalize						= mod:NewCastAnnounce(408805, 2, nil, nil, nil, 322274) --Дестабилизация (Ослабление)
--
local warnNecroticWound						= mod:NewStackAnnounce(209858, 3, nil, nil, 2) --Некротическая язва

local specWarnSpitefulFixate				= mod:NewSpecialWarningYou(350209, nil, 96306, nil, 1, 2) --Злобное преследование (Преследование)
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
local specWarnEntangled						= mod:NewSpecialWarningMove(408556, nil, 269678, nil, 1, 14) --Запутывание (Оплетение)
--Не используется после 1 сезона--
local timerPrimalOverloadCD					= mod:NewCDTimer(70, 396411, nil, nil, nil, 7) --Изначальная перегрузка
local timerPrimalOverload					= mod:NewCastTimer(3, 396411, nil, nil, nil, 7) --Изначальная перегрузка
local timerMarkLightning					= mod:NewBuffActiveTimer(15, 396369, nil, nil, nil, 7, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Метка молнии
local timerMarkWind							= mod:NewBuffActiveTimer(15, 396364, nil, nil, nil, 7, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Метка ветра
--
local timerQuake							= mod:NewCastTimer(2.5, 240447, nil, nil, nil, 2, nil, DBM_COMMON_L.INTERRUPT_ICON..DBM_COMMON_L.DEADLY_ICON, nil, 2, 2.5) --Землетрясение
local timerNecroticWound					= mod:NewBuffActiveTimer(9, 209858, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.HEALER_ICON) --Некротическая язва
local timerBurst							= mod:NewBuffActiveTimer(4, 240443, nil, nil, nil, 3, nil, DBM_COMMON_L.MYTHIC_ICON..DBM_COMMON_L.DEADLY_ICON) --Взрыв
local timerQuakingCD						= mod:NewCDTimer(20, 240447, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Землетрясение
local timerEntangledCD						= mod:NewCDTimer(30, 408556, 269678, nil, nil, 7, nil, DBM_COMMON_L.DEADLY_ICON, nil, nil, nil, nil, nil, nil, true) --Запутывание (Оплетение)
local timerAfflictedCD						= mod:NewCDTimer(30, 409492, 173254, nil, nil, 5, nil, DBM_COMMON_L.HEALER_ICON..DBM_COMMON_L.MAGIC_ICON, nil, mod:IsHealer() and 3 or nil, 3) --Крик изнемогающей души (Призыв духов)
local timerIncorporealCD					= mod:NewCDTimer(45, 408805, 173254, nil, nil, 5, nil, DBM_COMMON_L.INTERRUPT_ICON, nil, 3, 3) --Дестабилизация (Призыв духов)

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
local entangledCounting = false
local entangledDetected = false
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
	if DBM:UnitDebuff("player", 396364) then
		if self:AntiSpam(15.5, "Mark") then
			specWarnMarkWind2:Show()
			specWarnMarkWind2:Play("end")
		end
		yellPrimalOverload:Cancel()
		yellMarkWind:Cancel()
		timerMarkWind:Cancel()
		self.vb.mProshlyapCount = 0
		self:Unschedule(startProshlyapationOfMurchal)
	end
end

local function ProshlyapationOfMurchal(self)
	self.vb.murchalsProshlyapCount = 0
end

local function checkEntangled(self) --Запутывание (Гнев деревьев)
	if timerEntangledCD:GetRemaining() > 0 then
		--Timer exists, do nothing
		return
	end
	timerEntangledCD:Start(19.8)
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
	if entangledDetected then
		if combatFound and not entangledCounting then
			entangledCounting = true
			timerEntangledCD:Resume()
			local entangledRemaining = timerEntangledCD:GetRemaining()
			if entangledRemaining and entangledRemaining > 0 then--Shouldn't be 0, unless a player clicked it off, in which case we can't reschedule
				self:Unschedule(checkEntangled)
				self:Schedule(entangledRemaining+10, checkEntangled, self)
				DBM:Debug("Experimental reschedule of checkEntangled running")
			end
		elseif not combatFound and entangledCounting then
			entangledCounting = false
			timerEntangledCD:Pause()
			self:Unschedule(checkEntangled)--Soon as a pause happens this can no longer be trusted
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
	elseif spellId == 409492 and self:AntiSpam(3, "aff2") then --Крик изнемогающей души
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
	elseif spellId == 408805 and self:AntiSpam(2, "aff3") then --Дестабилизация (Ослабление)
		local unitId = self:GetUnitIdFromGUID(args.sourceGUID)
		if unitId and UnitIsEnemy("player", unitId) then
			warnDestabalize:Show()
		end
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
				self:Schedule(2.5, startProshlyapationOfMurchal, self)
			end
			timerMarkLightning:Start()
		end
	elseif spellId == 396364 then --Метка ветра
		if args:IsPlayer() then
			Wind = true
			specWarnMarkWind:Show()
			specWarnMarkWind:Play("gathershare")
			if self.Options.MurchalOchkenProshlyapen then
				yellPrimalOverload:Yell(7, MarkWind, 7) --Красная
				yellMarkWind:Countdown(spellId, 3)
				self:Schedule(2.5, startProshlyapationOfMurchal, self)
			end
			timerMarkWind:Start()
		end
	elseif spellId == 350209 and args:IsPlayer() and self:AntiSpam(5, "spitefulFixate") then
		specWarnSpitefulFixate:Show()
		specWarnSpitefulFixate:Play("targetyou")
--	elseif spellId == 408556 and self:AntiSpam(20, "aff6") then --Запутывание (Гнев деревьев)
	elseif spellId == 408556 then --Запутывание (Гнев деревьев)
--[[			specWarnEntangled:Show()
			specWarnEntangled:Play("breakvine")
			if not entangledDetected then
				entangledDetected = true
			end
			--Entangled check runs every 30 seconds, and if conditions aren't met for it activating it skips and goes into next 30 second CD
			--This checks if it was cast (by seeing if timer exists) if not, it starts next timer for next possible cast
			entangledCounting = true
			timerEntangledCD:Start()
			self:Unschedule(checkForCombat)
			self:Unschedule(checkEntangled)
			checkForCombat(self)
			self:Schedule(40, checkEntangled, self)]]
		if self:AntiSpam(20, "aff6") then --вариант 2
			if not entangledDetected then
				entangledDetected = true
			end
			entangledCounting = true
			timerEntangledCD:Start()
			self:Unschedule(checkForCombat)
			self:Unschedule(checkEntangled)
			checkForCombat(self)
			self:Schedule(40, checkEntangled, self)
		end
		if args:IsPlayer() then
			specWarnEntangled:Show()
			specWarnEntangled:Play("breakvine")--breakvine
		end
	elseif spellId == 408801 and self:AntiSpam(25, "aff7") then --Бесплотность
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
		--35, 45, 50
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
			end
			timerMarkLightning:Stop()
		end
	elseif spellId == 396364 then --Метка ветра
		self.vb.murchalsProshlyapCount = self.vb.murchalsProshlyapCount - 1
		if args:IsPlayer() then
			Wind = false
			self.vb.mProshlyapCount = 0
			if self:AntiSpam(15.5, "Mark") then
				specWarnMarkWind2:Show()
				specWarnMarkWind2:Play("end")
			end
			if self.Options.MurchalOchkenProshlyapen then
				self:Unschedule(startProshlyapationOfMurchal)
				yellMarkWind:Cancel()
			end
			timerMarkWind:Stop()
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
		timerPrimalOverload:Start()
		self:Schedule(18.5, ProshlyapationOfMurchal, self)
		if not overloadDetected then
			overloadDetected = true
		end
		self:Unschedule(checkForCombat)
		checkForCombat(self)
	end
end

function mod:CHALLENGE_MODE_COMPLETED()
	timerAfflictedCD:Stop()
	timerIncorporealCD:Stop()
	timerEntangledCD:Stop()
	overloadCounting = false --Изначальная перегрузка
	overloadDetected = false --Изначальная перегрузка
	afflictedCounting = false --Крик изнемогающей души (Призыв духов)
	afflictedDetected = false --Крик изнемогающей души (Призыв духов)
	incorporealCounting = false --Дестабилизация (Призыв духов)
	incorpDetected = false --Дестабилизация (Призыв духов)
	entangledCounting = false --Запутывание (Гнев деревьев)
	entangledDetected = false --Запутывание (Гнев деревьев)
	self:Unschedule(checkForCombat)
	self:Unschedule(checkAfflicted)
	self:Unschedule(checkIncorp)
	self:Unschedule(checkEntangled)
	DBM:Debug("Murchal proshlyap (Ключ закрыт)", 2)
end
mod.CHALLENGE_MODE_RESET = mod.CHALLENGE_MODE_COMPLETED
