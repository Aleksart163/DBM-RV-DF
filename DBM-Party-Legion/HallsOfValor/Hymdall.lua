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

local warnBreath					= mod:NewCountAnnounce(188404, 4)
local warnDancingBlade				= mod:NewTargetAnnounce(193235, 3) --Танцующий клинок

local specWarnSweep					= mod:NewSpecialWarningDefensive(193092, "Tank", nil, nil, 3, 2) --Рог доблести
local specWarnHornOfValor			= mod:NewSpecialWarningDefensive(191284, "-Tank", nil, nil, 3, 2) --Рог доблести
local specWarnDancingBlade			= mod:NewSpecialWarningMove(193235, nil, nil, nil, 1, 8) --Танцующий клинок
local specWarnDancingBlade2			= mod:NewSpecialWarningYou(193235, nil, nil, nil, 3, 2) --Танцующий клинок

local timerSweepCD					= mod:NewCDTimer(16.9, 193092, nil, "Tank", nil, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerDancingBladeCD			= mod:NewCDTimer(10, 193235, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON)
local timerHornCD					= mod:NewCDTimer(42.6, 191284, nil, nil, nil, 2)
local timerBreathCast				= mod:NewCastCountTimer(43.8, 188404, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON)

local yellDancingBlade				= mod:NewShortYell(193235, nil, nil, nil, "YELL") --Танцующий клинок

mod:AddSetIconOption("SetIconOnDancingBlade", 193235, true, 0, {8})

mod.vb.bladeCount = 0
mod.vb.breathCount = 0

--function mod:DancingBladeTarget(targetname, uId)
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
	timerDancingBladeCD:Start(4.3-delay)
	timerHornCD:Start(9.2-delay)
	timerSweepCD:Start(15.3-delay)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 191284 then
		self.vb.breathCount = 0
		specWarnHornOfValor:Show()
		specWarnHornOfValor:Play("defensive")
		timerBreathCast:Start(4.7, 1)
		timerHornCD:Start()
	elseif spellId == 193235 then
		self.vb.bladeCount = self.vb.bladeCount + 1
		if self.vb.bladeCount % 2 == 0 then
			timerDancingBladeCD:Start(11.2)
		else
			timerDancingBladeCD:Start(31.1)
		end
	--	self:BossTargetScanner(args.sourceGUID, "DancingBladeTarget", 0.1, 2)
		self:ScheduleMethod(0.1, "BossTargetScanner", args.sourceGUID, "DancingBladeTarget", 0.1, 8)
	elseif spellId == 188404 then
		self.vb.breathCount = self.vb.breathCount + 1
		warnBreath:Show(self.vb.breathCount)
		if self.vb.breathCount < 3 then
			timerBreathCast:Start(5, self.vb.breathCount+1)
		end
	elseif spellId == 193092 then
		specWarnSweep:Show()
		specWarnSweep:Play("defensive")
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
