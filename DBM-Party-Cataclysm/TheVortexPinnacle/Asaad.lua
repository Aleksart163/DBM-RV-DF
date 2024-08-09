local isRetail = WOW_PROJECT_ID == (WOW_PROJECT_MAINLINE or 1)
local mod	= DBM:NewMod(116, "DBM-Party-Cataclysm", 8, 68)
local L		= mod:GetLocalizedStrings()

mod.statTypes = "normal,heroic,challenge,timewalker"
mod.upgradedMPlus = true

mod:SetRevision("20240808070000")
mod:SetCreatureID(43875)
mod:SetEncounterID(1042)
mod:SetUsedIcons(8)
mod:SetHotfixNoticeRev(20240809070000)
--mod:SetMinSyncRevision(20230226000000)
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 87618 87622",
	"SPELL_CAST_SUCCESS 413263 86930",
	"SPELL_AURA_APPLIED 86911",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

--If cataclysm classic is pre nerf, static cling has shorter cast and needs faster alert
--TODO, verify changes on non mythic+ in 10.1
--TODO, diff logs can have very different results for chain lighting, seems due to boss sometimes skiping entire casts or delaying them
--[[
(ability.id = 87622 or ability.id = 87618) and type = "begincast"
 or (ability.id = 86930 or ability.id = 413263) and type = "cast"
 or ability.id = 86911 and type = "applybuff"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
  or (source.type = "NPC" and source.firstSeen = timestamp) and (source.id = 52019) or (target.type = "NPC" and target.firstSeen = timestamp) and (target.id = 52019)
--]]
local warnStaticCling			= mod:NewCastAnnounce(87618, 4) --Мертвая хватка
local warnChainLightning		= mod:NewTargetNoFilterAnnounce(87622, 3) --Цепная молния
local warnNova					= mod:NewCountAnnounce(413263, 3, nil, nil, 411016) --Кольцо падающих звезд (Упавшая звезда)

local specWarnStaticCling		= mod:NewSpecialWarningJump(87618, nil, nil, nil, 1, 2) --Мертвая хватка
local specWarnNova				= mod:NewSpecialWarningSwitch(413263, "-Healer", 411016, nil, 1, 2) --Упавшая звезда
local specWarnStorm				= mod:NewSpecialWarningMoveTo(86930, nil, nil, nil, 4, 4) --Великая сила бури
local specWarnStorm2			= mod:NewSpecialWarningSpell(86930, nil, nil, nil, 1, 6) --Великая сила бури
local specWarnChainLit			= mod:NewSpecialWarningMoveAway(87622, nil, nil, nil, 1, 2) --Цепная молния

local timerChainLightningCD		= mod:NewCDTimer(13.4, 87622, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Цепная молния
local timerStaticClingCD		= mod:NewCDCountTimer(15.8, 87618, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON..DBM_COMMON_L.MAGIC_ICON, nil, 2, 3) --Мертвая хватка
local timerStaticCling			= mod:NewCastTimer(3, 87618, nil, nil, nil, 7) --Мертвая хватка
local timerStorm				= mod:NewCastTimer(10, 86930, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Великая сила бури
local timerGroundingFieldCD		= mod:NewCDTimer(45.7, 86911, 87474, nil, nil, 7, nil, nil, nil, 1, 5) --Нестабильное заземляющее поле (Заземляющее поле)
local timerNovaCD				= mod:NewCDTimer(12.1, 413263, 411016, nil, nil, 1, nil, DBM_COMMON_L.DAMAGE_ICON..DBM_COMMON_L.HEALER_ICON) --Кольцо падающих звезд (Упавшая звезда)

local yellChainLit				= mod:NewShortYell(87622, nil, nil, nil, "YELL") --Цепная молния

mod:AddSetIconOption("SetIconOnChainLightning", 87622, true, 0, {8}) --Цепная молния

local GroundingField = DBM:GetSpellName(87474)
local Proshlyap = nil

mod.vb.groundingCount = 0
mod.vb.novaCount = 0
mod.vb.staticClingCount = 0
mod.vb.chainLightningCount = 0

function mod:LitTarget(targetname)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnChainLit:Show()
		specWarnChainLit:Play("runout")
		yellChainLit:Yell()
	else
		warnChainLightning:Show(targetname)
	end
	if self.Options.SetIconOnChainLightning then
		self:SetIcon(targetname, 8, 3)
	end
end

local allProshlyapationsOfMurchal = {
	--Мертвая хватка
	[87618] = {25.3, 44.2, 29, 42.3, 29, 42.3, 29, 42.4, 29},
	--Упавшая звезда
	[96260] = {17.9, 43.3, 26, 44.5, 25.9, 45.4, 25.9, 45.3, 26},
}

function mod:OnCombatStart(delay)
	Proshlyap = false
	self.vb.groundingCount = 0
	self.vb.novaCount = 0
	self.vb.staticClingCount = 0
	self.vb.chainLightningCount = 0
	if self:IsMythic() then
		timerChainLightningCD:Start(12.1-delay) --
		timerNovaCD:Start(17.9) --
		timerStaticClingCD:Start(25.3-delay, 1) --
		timerGroundingFieldCD:Start(30.3-delay) --
	else--TODO, check non M+ on 10.1
		timerNovaCD:Start(10.7)
		timerStaticClingCD:Start(10.7-delay, 1)
		timerChainLightningCD:Start(13.1-delay)
		timerGroundingFieldCD:Start(16.9-delay)
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 87618 then --Мертвая хватка
		--1.25 post nerf in classic, 1 sec pre nerf
		--3 lol giga nerf in M+
		self.vb.staticClingCount = self.vb.staticClingCount + 1
		warnStaticCling:Show()
		specWarnStaticCling:Schedule(self:IsClassic() and 0.5 or 2.3)--delay message since jumping at start of cast is no longer correct in 4.0.6+
		specWarnStaticCling:ScheduleVoice(self:IsClassic() and 0.5 or 2.3, "jumpnow")
		timerStaticCling:Start(self:IsClassic() and 1.25 or 3)
		if self:IsMythic() then
			local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.staticClingCount+1) 
			if timer then
				timerStaticClingCD:Start(timer, self.vb.staticClingCount+1)
			end
		else
			local expectedTimer = self:IsMythic() and 29.1 or 15.8
			if timerGroundingFieldCD:GetRemaining() < expectedTimer then
				timerStaticClingCD:Start(expectedTimer, self.vb.staticClingCount+1)
			end
		end
	elseif spellId == 87622 then --Цепная молния
	--	self:ScheduleMethod(0.2, "BossTargetScanner", args.sourceGUID, "LitTarget", 0.1, 8, true)
		self.vb.chainLightningCount = self.vb.chainLightningCount + 1
		self:BossTargetScanner(args.sourceGUID, "LitTarget", 0.1, 2)
		if self:IsMythic() and Proshlyap then
			if self.vb.chainLightningCount == 1 then
				timerChainLightningCD:Start(19)
			elseif self.vb.chainLightningCount == 2 then
				timerChainLightningCD:Start(18.5)
			end
		else
			local expectedTimer = self:IsMythic() and 18.1 or 13.4
			if timerGroundingFieldCD:GetRemaining() < expectedTimer then
				timerChainLightningCD:Start(expectedTimer)
			end
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 86930 then --Великая сила бури
		self.vb.chainLightningCount = 0
		if not Proshlyap then
			Proshlyap = true
		end
		specWarnStorm2:Show()
		specWarnStorm2:Play("stilldanger")
		timerChainLightningCD:Start(12)
--[[	if args.spellId == 413263 and self:AntiSpam(5, 2) then
		if self:IsMythicPlus() then
			if timerGroundingFieldCD:GetRemaining() < 25.4 then
				timerNovaCD:Start(25.4)
			end
		else
			if timerGroundingFieldCD:GetRemaining() < 12.1 then
				timerNovaCD:Start()
			end
		end]]
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 86911 and self:AntiSpam(2, 1) then --Нестабильное заземляющее поле
		self.vb.groundingCount = self.vb.groundingCount + 1
		specWarnStorm:Show(GroundingField)
		specWarnStorm:Play("findshelter")
		timerStorm:Start()
		if self:IsMythic() then
			timerGroundingFieldCD:Start(71.3)
		else
			timerStaticClingCD:Start(12, self.vb.staticClingCount+1)
			--timerChainLightningCD:Start(19.3)
			timerNovaCD:Start(22.9, self.vb.novaCount+1)
			timerGroundingFieldCD:Start(45.7)--45.7
		end
	end
end

--Pre 10.1 "Summon Skyfall Star-96260-npc:43875-000008E8D0 = pull:10.7, 29.1, 14.6, 31.6, 13.4, 31.6, 12.1", -- [7]
function mod:UNIT_SPELLCAST_SUCCEEDED(_, _, spellId)
	if spellId == 96260 then
		self.vb.novaCount = self.vb.novaCount + 1
		warnNova:Show(self.vb.novaCount)
		specWarnNova:Show()
		specWarnNova:Play("killmob")
		if self:IsMythic() then
			local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.novaCount+1) 
			if timer then
				timerNovaCD:Start(timer, self.vb.novaCount+1)
			end
		else
			local expectedTime = self:IsMythic() and 25.1 or 12.1
			if timerGroundingFieldCD:GetRemaining() < expectedTime then
				timerNovaCD:Start(expectedTime, self.vb.novaCount+1)
			end
		end
	end
end
