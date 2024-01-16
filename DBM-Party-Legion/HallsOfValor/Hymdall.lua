local mod	= DBM:NewMod(1485, "DBM-Party-Legion", 4, 721)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20230504231118")
mod:SetCreatureID(94960)
mod:SetEncounterID(1805)
mod:SetUsedIcons(8)
mod:SetHotfixNoticeRev(20221127000000)
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 191284 193235 193092 188404",
	"SPELL_PERIODIC_DAMAGE 193234",
	"SPELL_PERIODIC_MISSED 193234"
)

--[[
(ability.id = 191284 or ability.id = 193235 or ability.id = 193092) and type = "begincast"
 or ability.id = 188404 and type = "cast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
local warnBreath					= mod:NewCountAnnounce(188404, 4)
local warnDancingBlade				= mod:NewTargetAnnounce(193235, 3)
local warnSweep						= mod:NewSpellAnnounce(193092, 2, nil, "Tank")

local specWarnHornOfValor			= mod:NewSpecialWarningDefensive(191284, nil, nil, nil, 3, 2)
local specWarnDancingBlade			= mod:NewSpecialWarningMove(193235, nil, nil, nil, 1, 8) --Танцующий клинок
local specWarnDancingBlade2			= mod:NewSpecialWarningYou(193235, nil, nil, nil, 3, 6) --Танцующий клинок
--local yellDancingBlade				= mod:NewYell(193235)

local timerSweepCD					= mod:NewCDTimer(16.9, 193092, nil, "Tank", nil, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerDancingBladeCD			= mod:NewCDTimer(10, 193235, nil, nil, nil, 3)
local timerHornCD					= mod:NewCDTimer(43.8, 191284, nil, nil, nil, 2)
local timerBreathCast				= mod:NewCastCountTimer(43.8, 188404, nil, nil, nil, 3)

local yellDancingBlade				= mod:NewYell(193235, nil, nil, nil, "YELL")

mod:AddSetIconOption("SetIconOnDancingBlade", 193235, true, 0, {8})

mod.vb.bladeCount = 0
mod.vb.breathCount = 0

function mod:DancingBladeTarget(targetname, uId) --Танцующий клинок [✔] прошляпанного очка Мурчаля Прошляпенко
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnDancingBlade2:Show()
		specWarnDancingBlade2:Play("runout")
		yellDancingBlade:Yell()
	else
		warnDancingBlade:Show(targetname)
	end
	if self.Options.SetIconOnDancingBlade then
		self:SetIcon(targetname, 8, 5)
	end
end

function mod:OnCombatStart(delay)
	self.vb.bladeCount = 0
	timerDancingBladeCD:Start(5.2-delay)
	timerHornCD:Start(10.8-delay)
	timerSweepCD:Start(15.7-delay)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 191284 then
		self.vb.breathCount = 0
		specWarnHornOfValor:Show()
		specWarnHornOfValor:Play("defensive")
		timerBreathCast:Start(8, 1)
		timerHornCD:Start()
	elseif spellId == 193235 then
		self.vb.bladeCount = self.vb.bladeCount + 1
	--	warnDancingBlade:Show(self.vb.bladeCount)
		self:BossTargetScanner(args.sourceGUID, "DancingBladeTarget", 0.1, 20, true, nil, nil, nil, true)
		if self.vb.bladeCount % 2 == 0 then
			timerDancingBladeCD:Start(11.2)
		else
			timerDancingBladeCD:Start(31.1)
		end
	elseif spellId == 188404 then
		self.vb.breathCount = self.vb.breathCount + 1
		warnBreath:Show(self.vb.breathCount)
		if self.vb.breathCount < 3 then
			timerBreathCast:Start(5, self.vb.breathCount+1)
		end
	elseif spellId == 193092 then
		warnSweep:Show()
		timerSweepCD:Start()
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId)
	if spellId == 193234 and destGUID == UnitGUID("player") and self:AntiSpam(2, 1) then
		specWarnDancingBlade:Show()
		specWarnDancingBlade:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
