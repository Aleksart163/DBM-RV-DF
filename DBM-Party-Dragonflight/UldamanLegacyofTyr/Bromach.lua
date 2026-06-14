local mod	= DBM:NewMod(2487, "DBM-Party-Dragonflight", 2, 1197)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240426062327")
mod:SetCreatureID(184018)
mod:SetEncounterID(2556)
mod:SetUsedIcons(8)
mod:SetHotfixNoticeRev(20230508000000)
--mod:SetMinSyncRevision(20211203000000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 369675 369754 369703 382303",
	"SPELL_CAST_SUCCESS 369605 369703",
	"SPELL_AURA_APPLIED 369725 369660"
)

--TODO, warn trogg Ambush casts?
--TODO, target scan thundering slam to notify direction of attack?
--TODO, rangecheck for chain lighting? it doesn't tell what range of "nearby enemy" means
--TODO, Mythic timer and heroic timers may actually differ but it's hard to review heroic timers when logs can't be searched
--TODO, https://www.wowhead.com/beta/spell=369674/stone-spike added in newer build but seems like low prio interrupt over Chain Lightning
--[[
(ability.id = 369754 or ability.id = 369703 or ability.id = 382303) and type = "begincast"
 or ability.id = 369605 and type = "cast"
 or ability.id = 369725
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
 or ability.id = 369675 and type = "begincast"
--]]
local warnChainLightning						= mod:NewCastAnnounce(369675, 4) --Цепная молния
local warnCalloftheDeep							= mod:NewSpellAnnounce(369605, 3) --Зов глубин
local warnBloodlust								= mod:NewSpellAnnounce(369754, 3) --Жажда крови

local specWarnQuakingTotem						= mod:NewSpecialWarningSwitch(369700, "-Healer", nil, nil, 3, 2) --Сотрясающий тотем
local specWarnChainLightning					= mod:NewSpecialWarningInterrupt(369675, "HasInterrupt", nil, nil, 1, 2) --Цепная молния
local specWarnThunderingSlam					= mod:NewSpecialWarningDodge(369703, nil, nil, nil, 2, 2) --Оглушающий удар

local timerTremor								= mod:NewCastTimer(10, 369660, DBM_COMMON_L.DAMAGEUP, nil, nil, 7, nil, nil, nil, 1, 5)
local timerCalloftheDeepCD						= mod:NewCDCountTimer(27.4, 369605, DBM_COMMON_L.ADDS.." (%s)", nil, nil, 1, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DAMAGE_ICON) --Зов глубин 28-30
local timerQuakingTotemCD						= mod:NewCDCountTimer(30, 369700, nil, nil, nil, 7, nil, nil, nil, 1, 5) --Сотрясающий тотем
local timerBloodlustCD							= mod:NewCDCountTimer(30, 369754, nil, nil, nil, 2, nil, DBM_COMMON_L.ENRAGE_ICON) --Жажда крови
local timerThunderingSlamCD						= mod:NewCDCountTimer(18.2, 369703, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON) --Оглушающий удар 18-23

mod.vb.callCount = 0
mod.vb.thunderingCount = 0
mod.vb.totemCount = 0
mod.vb.bloodlustCount = 0
mod.vb.brokenTotemCount = 0

local Proshlyap = false
local askShown = false

function mod:OnCombatStart(delay)
	Proshlyap = false
	askShown = false
	self.vb.callCount = 0
	self.vb.thunderingCount = 0
	self.vb.totemCount = 0
	self.vb.bloodlustCount = 0
	self.vb.brokenTotemCount = 0
	timerCalloftheDeepCD:Start(5.9-delay, 1) --
	timerThunderingSlamCD:Start(15.9-delay, 1) --
	timerQuakingTotemCD:Start(19.9-delay, 1)
	timerBloodlustCD:Start(32.9-delay, 1)
	--Зов глубин 5.9, 32, 40
	--Оглушающий удар 15.9, 32, 19, 28
	--Сотрясающий тотем 19.9, 40, 40
	--Жажда крови 32.9, 40, 40
end

local allProshlyapationsOfMurchal = {
	--Зов глубин
	[369605] = {5.9, 32, 40},
	--Оглушающий удар
	[369703] = {15.9, 32, 19, 28},
	--Сотрясающий тотем
	[382303] = {19.9, 40, 40},
	--Жажда крови
	[369754] = {32.9, 40, 40},
}

local allProshlyapationsOfMurchal2 = {
	[1] = {
		--Зов глубин
		[369605] = {12.4, 41},
		--Оглушающий удар
		[369703] = {10, 16.6},
		--Сотрясающий тотем
		[382303] = {28.9},
		--Жажда крови
		[369754] = {36.9, 40},
	},
	[2] = {
		--Зов глубин
		[369605] = {12.4, 41},
		--Оглушающий удар
		[369703] = {10, 28.5},
		--Сотрясающий тотем
		[382303] = {28.9},
		--Жажда крови
		[369754] = {36.9, 40},
	},
	[3] = {
		--Зов глубин
		[369605] = {12.4, 41},
		--Оглушающий удар
		[369703] = {10, 28.5},
		--Сотрясающий тотем
		[382303] = {28.9},
		--Жажда крови
		[369754] = {36.9, 40},
	},
	[4] = {
		--Зов глубин
		[369605] = {12.4, 41},
		--Оглушающий удар
		[369703] = {10, 20},
		--Сотрясающий тотем
		[382303] = {28.9},
		--Жажда крови
		[369754] = {36.9, 40},
	},
	[5] = {
		--Зов глубин
		[369605] = {12.4, 41},
		--Оглушающий удар
		[369703] = {10, 28.5},
		--Сотрясающий тотем
		[382303] = {28.9},
		--Жажда крови
		[369754] = {36.9, 40},
	},
}

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 369675 and args:GetSrcCreatureID() == 186658 then --Цепная молния 186658 boss version of mob
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnChainLightning:Show(args.sourceName)
			specWarnChainLightning:Play("kickcast")
		else
			warnChainLightning:Show()
		end
	elseif spellId == 369754 then --Жажда крови
		self.vb.bloodlustCount = self.vb.bloodlustCount + 1
		warnBloodlust:Show()
		if not Proshlyap then
			local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.bloodlustCount+1)
			if timer then
				timerBloodlustCD:Start(timer, self.vb.bloodlustCount+1)
			else
				if not askShown then
					askShown = true
					DBM:AddMsg("Данный спелл не имеет таймера, т.к. бой не предусматривался быть настолько долгим.")
				end
			end
		elseif Proshlyap then
			local timer2 = self:GetFromTimersTable(allProshlyapationsOfMurchal2, false, self.vb.brokenTotemCount, spellId, self.vb.bloodlustCount+1)
			if timer2 then
				timerBloodlustCD:Start(timer2, self.vb.bloodlustCount+1)
			else
				if not askShown then
					askShown = true
					DBM:AddMsg("Данный спелл не имеет таймера, т.к. бой не предусматривался быть настолько долгим.")
				end
			end
		end
	--	timerBloodlustCD:Start(nil, self.vb.bloodlustCount+1)
	elseif spellId == 369703 then --Оглушающий удар
		specWarnThunderingSlam:Show()
		specWarnThunderingSlam:Play("watchstep")
	elseif spellId == 382303 then --Сотрясающий тотем
		self.vb.totemCount = self.vb.totemCount + 1
		specWarnQuakingTotem:Show()
		specWarnQuakingTotem:Play("attacktotem")
		if not Proshlyap then
			local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.totemCount+1)
			if timer then
				timerQuakingTotemCD:Start(timer, self.vb.totemCount+1)
			else
				if not askShown then
					askShown = true
					DBM:AddMsg("Данный спелл не имеет таймера, т.к. бой не предусматривался быть настолько долгим.")
				end
			end
		elseif Proshlyap then
			local timer2 = self:GetFromTimersTable(allProshlyapationsOfMurchal2, false, self.vb.brokenTotemCount, spellId, self.vb.totemCount+1)
			if timer2 then
				timerQuakingTotemCD:Start(timer2, self.vb.totemCount+1)
			else
				if not askShown then
					askShown = true
					DBM:AddMsg("Данный спелл не имеет таймера, т.к. бой не предусматривался быть настолько долгим.")
				end
			end
		end
	--	timerQuakingTotemCD:Start(nil, self.vb.totemCount+1)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 369605 then --Зов глубин
		self.vb.callCount = self.vb.callCount + 1
		warnCalloftheDeep:Show()
		if not Proshlyap then
			local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.callCount+1)
			if timer then
				timerCalloftheDeepCD:Start(timer, self.vb.callCount+1)
			else
				if not askShown then
					askShown = true
					DBM:AddMsg("Данный спелл не имеет таймера, т.к. бой не предусматривался быть настолько долгим.")
				end
			end
		elseif Proshlyap then
			local timer2 = self:GetFromTimersTable(allProshlyapationsOfMurchal2, false, self.vb.brokenTotemCount, spellId, self.vb.callCount+1)
			if timer2 then
				timerCalloftheDeepCD:Start(timer2, self.vb.callCount+1)
			else
				if not askShown then
					askShown = true
					DBM:AddMsg("Данный спелл не имеет таймера, т.к. бой не предусматривался быть настолько долгим.")
				end
			end
		end
	--	timerCalloftheDeepCD:Start(nil, self.vb.callCount+1)
	elseif spellId == 369703 then --Оглушающий удар
		self.vb.thunderingCount = self.vb.thunderingCount + 1
		if not Proshlyap then
			local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.thunderingCount+1)
			if timer then
				timerThunderingSlamCD:Start(timer, self.vb.thunderingCount+1)
			else
				if not askShown then
					askShown = true
					DBM:AddMsg("Данный спелл не имеет таймера, т.к. бой не предусматривался быть настолько долгим.")
				end
			end
		elseif Proshlyap then
			local timer2 = self:GetFromTimersTable(allProshlyapationsOfMurchal2, false, self.vb.brokenTotemCount, spellId, self.vb.thunderingCount+1)
			if timer2 then
				timerThunderingSlamCD:Start(timer2, self.vb.thunderingCount+1)
			else
				if not askShown then
					askShown = true
					DBM:AddMsg("Данный спелл не имеет таймера, т.к. бой не предусматривался быть настолько долгим.")
				end
			end
		end
	--	timerThunderingSlamCD:Start(14.7, self.vb.thunderingCount+1)--18.2 - 3.5
	end
end


function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 369725 then--Tremor
	--	timerCalloftheDeepCD:AddTime(10, self.vb.callCount+1)
	--	timerThunderingSlamCD:AddTime(10, self.vb.thunderingCount+1)
	--	timerQuakingTotemCD:AddTime(10, self.vb.totemCount+1)
	--	timerBloodlustCD:AddTime(10)
	--	timerTremor:Start()
		DBM:Debug("Сломался тотем 1", 2)
	elseif spellId == 369660 then --Дрожь
		local cid = self:GetCIDFromGUID(args.destGUID)
		if cid == 184018 then
			self.vb.brokenTotemCount = self.vb.brokenTotemCount + 1
			if not Proshlyap then
				Proshlyap = true
			end
			self.vb.callCount = 0
			self.vb.thunderingCount = 0
			self.vb.totemCount = 0
			self.vb.bloodlustCount = 0
			timerThunderingSlamCD:Stop()
			timerCalloftheDeepCD:Stop()
			timerQuakingTotemCD:Stop()
			timerBloodlustCD:Stop()
			timerTremor:Start() --
			timerThunderingSlamCD:Start(10, 1) --
			timerCalloftheDeepCD:Start(12.4, 1) --
			timerQuakingTotemCD:Start(28.9, 1) --
			timerBloodlustCD:Start(36.9, 1) --
			DBM:Debug("Сломался тотем 2", 2)
		end
	end
end
