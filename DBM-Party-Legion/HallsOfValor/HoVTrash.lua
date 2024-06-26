local mod	= DBM:NewMod("HoVTrash", "DBM-Party-Legion", 4)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20231026112110")
--mod:SetModelID(47785)
mod:SetZone(1477)

mod.isTrashMod = true

mod:RegisterEvents(
	"SPELL_CAST_START 199805 192563 199726 191508 199210 198892 198934 215433 210875 192158 200901 198595 192288 199652",
	"SPELL_CAST_SUCCESS 200901",
	"SPELL_AURA_APPLIED 215430 199652 193783",
	"SPELL_AURA_APPLIED_DOSE 199652",
	"SPELL_AURA_REMOVED 215430 199652",
	"UNIT_DIED",
	"CHAT_MSG_MONSTER_YELL",
	"GOSSIP_SHOW"
)

--TODO wicked dagger (199674)?
local warnAegis						= mod:NewTargetNoFilterAnnounce(193783, 1) --Эгида Агграмара
local warnCrackle					= mod:NewTargetNoFilterAnnounce(199805, 2)
local warnCracklingStorm			= mod:NewTargetAnnounce(198892, 2)
local warnThunderousBolt			= mod:NewCastAnnounce(198595, 3)
local warnCleansingFlame			= mod:NewCastAnnounce(192563, 4)
local warnHolyRadiance				= mod:NewCastAnnounce(215433, 3)
local warnRuneOfHealing				= mod:NewCastAnnounce(198934, 3)
local warnUnrulyYell				= mod:NewCastAnnounce(199726, 3) --Буйный вопль

local specWarnSever					= mod:NewSpecialWarningStack(199652, nil, 4, nil, nil, 3, 2) --Рассечение
local specWarnBlastofLight			= mod:NewSpecialWarningDodge(191508, nil, nil, nil, 2, 2)
local specWarnPenetratingShot		= mod:NewSpecialWarningDodge(199210, nil, nil, nil, 2, 2)
local specWarnChargePulse			= mod:NewSpecialWarningDodge(210875, nil, nil, nil, 2, 2)
local specWarnSanctify				= mod:NewSpecialWarningDodge(192158, nil, nil, nil, 2, 5)
local specWarnEyeofStorm			= mod:NewSpecialWarningMoveTo(200901, nil, nil, nil, 2, 2)
local specWarnEyeofStorm2			= mod:NewSpecialWarningDefensive(200901, nil, nil, nil, 3, 2)
local specWarnCrackle				= mod:NewSpecialWarningYou(199805, nil, nil, nil, 1, 2)
local specWarnCracklingStorm		= mod:NewSpecialWarningYou(198892, nil, nil, nil, 1, 2)
local specWarnThunderstrike			= mod:NewSpecialWarningMoveAway(215430, nil, nil, nil, 1, 2)
local specWarnThunderousBolt		= mod:NewSpecialWarningInterrupt(198595, "HasInterrupt", nil, nil, 1, 2)
local specWarnHolyRadiance			= mod:NewSpecialWarningInterrupt(215433, "HasInterrupt", nil, nil, 1, 2)
local specWarnRuneOfHealing			= mod:NewSpecialWarningInterrupt(198934, false, nil, nil, 1, 2)--Mob can be moved out of it so Holy more important spell to kick
local specWarnCleansingFlame		= mod:NewSpecialWarningInterrupt(192563, "HasInterrupt", nil, nil, 1, 2)
local specWarnUnrulyYell			= mod:NewSpecialWarningInterrupt(199726, "HasInterrupt", nil, nil, 1, 2) --Буйный вопль
local specWarnSearingLight			= mod:NewSpecialWarningInterrupt(192288, "HasInterrupt", nil, nil, 1, 2)

local timerUnrulyYellCD				= mod:NewCDNPTimer(20, 199726, nil, nil, nil, 2, nil, DBM_COMMON_L.INTERRUPT_ICON) --Буйный вопль
local timerSeverCD					= mod:NewCDNPTimer(10, 199652, nil, nil, nil, 3, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON) --Рассечение
local timerThunderousBoltCD			= mod:NewCDNPTimer(4.8, 198595, nil, nil, nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON)--6-7
local timerRuneOfHealingCD			= mod:NewCDNPTimer(17, 198934, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON)--17-18.2
local timerHolyRadianceCD			= mod:NewCDNPTimer(18.1, 215433, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON)--17-18.2
local timerCleansingFlameCD			= mod:NewCDNPTimer(6.1, 192563, nil, nil, nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON)--6-9
local timerBlastofLightCD			= mod:NewCDNPTimer(18, 191508, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON)--May be lower
local timerEyeofStormCD				= mod:NewCDNPTimer(25, 200901, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON, nil, 3, 3)
local timerSanctifyCD				= mod:NewCDNPTimer(25, 192158, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON, nil, 3, 3)
local timerRP						= mod:NewRPTimer(28.5)

local yellAegis						= mod:NewYell(193783, nil, nil, nil, "YELL") --Эгида Агграмара
local yellCrackle					= mod:NewShortYell(199805, nil, nil, nil, "YELL")
local yellCracklingStorm			= mod:NewShortYell(198892, nil, nil, nil, "YELL")
local yellThunderstrike				= mod:NewShortYell(215430, nil, nil, nil, "YELL")

mod:AddBoolOption("AGSkovaldTrash", true)
mod:AddBoolOption("AGStartOdyn", true)
--Antispam IDs for this mod: 1 run away, 2 dodge, 3 dispel, 4 incoming damage, 5 you/role, 6 generalized, 7 GTFO

local eyeShortName = DBM:GetSpellInfo(91320)--Inner Eye

function mod:CrackleTarget(targetname, uId)
	if not targetname then
		warnCrackle:Show(DBM_COMMON_L.UNKNOWN)
		return
	end
	if targetname == UnitName("player") then
		specWarnCrackle:Show()
		specWarnCrackle:Play("targetyou")
		yellCrackle:Yell()
	else
		warnCrackle:Show(targetname)
	end
end

function mod:CracklingStormTarget(targetname, uId)
	if not targetname then
		warnCracklingStorm:Show(DBM_COMMON_L.UNKNOWN)
		return
	end
	if targetname == UnitName("player") then
		specWarnCracklingStorm:Show()
		specWarnCracklingStorm:Play("targetyou")
		yellCracklingStorm:Yell()
	else
		warnCracklingStorm:Show(targetname)
	end
end

function mod:SPELL_CAST_START(args)
	if not self.Options.Enabled then return end
	if not self:IsValidWarning(args.sourceGUID) then return end
	local spellId = args.spellId
	if spellId == 199805 then
		self:BossTargetScanner(args.sourceGUID, "CrackleTarget", 0.1, 9)
	elseif spellId == 198892 then
		self:BossTargetScanner(args.sourceGUID, "CracklingStormTarget", 0.1, 9)
	elseif spellId == 192563 then
		timerCleansingFlameCD:Start(nil, args.sourceGUID)
		if self.Options.SpecWarn192563interrupt and self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnCleansingFlame:Show(args.sourceName)
			specWarnCleansingFlame:Play("kickcast")
		elseif self:AntiSpam(2, 5) then
			warnCleansingFlame:Show()
		end
	elseif spellId == 215433 then
		timerHolyRadianceCD:Start(nil, args.sourceGUID)
		if self.Options.SpecWarn215433interrupt and self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnHolyRadiance:Show(args.sourceName)
			specWarnHolyRadiance:Play("kickcast")
		elseif self:AntiSpam(2, 5) then
			warnHolyRadiance:Show()
		end
	elseif spellId == 198934 then
		timerRuneOfHealingCD:Start(nil, args.sourceGUID)
		if self.Options.SpecWarn198934interrupt and self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnRuneOfHealing:Show(args.sourceName)
			specWarnRuneOfHealing:Play("kickcast")
		elseif self:AntiSpam(2, 5) then
			warnRuneOfHealing:Show()
		end
	elseif spellId == 199726 then --Буйный вопль
		timerUnrulyYellCD:Start(nil, args.sourceGUID)
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnUnrulyYell:Show(args.sourceName)
			specWarnUnrulyYell:Play("kickcast")
		elseif self:AntiSpam(2, 5) then
			warnUnrulyYell:Show()
		end
	elseif spellId == 191508 then
		if self:AntiSpam(3, 2) then
			specWarnBlastofLight:Show()
			specWarnBlastofLight:Play("shockwave")
		end
		timerBlastofLightCD:Start(nil, args.sourceGUID)
	elseif spellId == 198595 then
		timerThunderousBoltCD:Start(nil, args.sourceGUID)
		if self.Options.SpecWarn198595interrupt and self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnThunderousBolt:Show(args.sourceName)
			specWarnThunderousBolt:Play("kickcast")
		elseif self:AntiSpam(2, 5) then
			warnThunderousBolt:Show()
		end
	elseif spellId == 199210 and self:AntiSpam(3, 2) then
		specWarnPenetratingShot:Show()
		specWarnPenetratingShot:Play("shockwave")
	elseif spellId == 210875 and self:AntiSpam(3, 2) then
		specWarnChargePulse:Show()
		specWarnChargePulse:Play("watchstep")
	elseif spellId == 192158 then--P1 2 adds
		specWarnSanctify:Show()
		specWarnSanctify:Play("watchorb")
		timerSanctifyCD:Start()
	--2/22 01:53:53.948  SPELL_CAST_START,Creature-0-3019-1477-12381-97219-000075B856,"Solsten",0x10a48,0x0,0000000000000000,nil,0x80000000,0x80000000,200901,"Eye of the Storm",0x8
	elseif spellId == 200901 and args:GetSrcCreatureID() == 97219 then
--[[		if self:AntiSpam(2, "EyeofStorm") then
			specWarnEyeofStorm:Show(eyeShortName)
			specWarnEyeofStorm:Play("findshelter")
		end]]
		timerEyeofStormCD:Start()
		self:SendSync("EyeofStorm1")
	elseif spellId == 192288 then
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnSearingLight:Show(args.sourceName)
			specWarnSearingLight:Play("kickcast")
		end
		--On fly correct santify which is delayed by the forced ICD of Searing Light casts
		if (timerSanctifyCD:GetRemaining() > 0) and (timerSanctifyCD:GetRemaining() < 6) then
			local elapsed, total = timerSanctifyCD:GetTime()
			local extend = 6 - (total-elapsed)
			DBM:Debug("timerSanctifyCD extended by: "..extend, 2)
			timerSanctifyCD:Update(elapsed, total+extend)
		end
	elseif spellId == 199652 then
		timerSeverCD:Start(nil, args.sourceGUID)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 200901 then
		self:SendSync("EyeofStorm2")
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 215430 then
		if args:IsPlayer() then
			specWarnThunderstrike:Show()
			specWarnThunderstrike:Play("scatter")
			yellThunderstrike:Yell()
			if self.Options.RangeFrame then
				DBM.RangeCheck:Show(6)
			end
		end
	elseif spellId == 199652 then --Рассечение
		local amount = args.amount or 1
		if args:IsPlayer() and self:IsMythic() then
			if amount >= 4 then
				specWarnSever:Show(amount)
				specWarnSever:Play("stackhigh")
			end
		end
	elseif spellId == 193783 and self:AntiSpam(2, 2) then
		if args:IsPlayer() then
			yellAegis:Yell()
		else
			warnAegis:Show(args.destName)
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 215430 and args:IsPlayer() then
		if self.Options.RangeFrame then
			DBM.RangeCheck:Hide()
		end
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 101637 then--Valarjar Aspirant
		timerBlastofLightCD:Stop(args.destGUID)
	elseif cid == 95834 then--Valajar Mystic
		timerRuneOfHealingCD:Stop(args.destGUID)
		timerHolyRadianceCD:Stop(args.destGUID)
	elseif cid == 97197 then--Valajar Purifier
		timerCleansingFlameCD:Stop(args.destGUID)
	elseif cid ==  95842 then--Valjar Thundercaller
		timerThunderousBoltCD:Stop(args.destGUID)
	elseif cid == 97219 then--Solsten
		timerEyeofStormCD:Stop()
	elseif cid == 97202 then--Olmyr
		timerSanctifyCD:Stop()
	elseif cid == 97081 or cid == 95843 or cid == 97083 or cid == 97084 then
		timerSeverCD:Stop(args.destGUID)
		timerUnrulyYellCD:Stop(args.destGUID)
	end
end

function mod:GOSSIP_SHOW()
	local gossipOptionID = self:GetGossipID()
	if gossipOptionID then
		if self.Options.AGSkovaldTrash and (gossipOptionID == 44755 or gossipOptionID == 44801 or gossipOptionID == 44802 or gossipOptionID == 44754) then -- Skovald Trash
			self:SelectGossip(gossipOptionID)
		elseif self.Options.AGStartOdyn and gossipOptionID == 44910 then -- Odyn
			self:SelectGossip(gossipOptionID, true)
			self:SendSync("RPOdyn2")
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.RPOdyn then
		self:SendSync("RPOdyn1")
--	elseif msg == L.RPSolsten then
--		self:SendSync("RPSolsten1")
	elseif msg == L.RPSolsten2 then
		self:SendSync("RPSolsten2")
		timerEyeofStormCD:Stop()
--	elseif msg == L.RPOlmyr then
--		timerSanctifyCD:Start(9)
	elseif msg == L.RPOlmyr2 then
		timerSanctifyCD:Stop()
	end
end

function mod:OnSync(msg)
	if msg == "RPOdyn2" then
		timerRP:Start(3)
	elseif msg == "RPOdyn1" and self:AntiSpam(2, "OdynPull") then
		timerRP:Start(10.5)
--	elseif msg == "RPSolsten1" then
--		timerEyeofStormCD:Start(11)
	elseif msg == "RPSolsten2" then
		timerEyeofStormCD:Stop()
	elseif msg == "EyeofStorm1" and self:AntiSpam(2, "EyeofStorm") then
		specWarnEyeofStorm:Show(eyeShortName)
		specWarnEyeofStorm:Play("findshelter")
	elseif msg == "EyeofStorm2" then
		if not UnitIsDeadOrGhost("player") then
			specWarnEyeofStorm2:Show()
			specWarnEyeofStorm2:Play("defensive")
		end
	end
end
