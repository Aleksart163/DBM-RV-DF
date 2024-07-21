local mod	= DBM:NewMod(1662, "DBM-Party-Legion", 5, 767)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20230916034331")
mod:SetCreatureID(91003)
mod:SetEncounterID(1790)
mod:SetHotfixNoticeRev(20240617070000)
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 188169 188114",
	"SPELL_PERIODIC_DAMAGE 192800",
	"SPELL_PERIODIC_MISSED 192800"
)

--TODO, is razorshards 29 seconds now?
local warnShatter					= mod:NewCountAnnounce(188114, 2) --Дробление

local specWarnShatter				= mod:NewSpecialWarningDefensive(188114, nil, nil, nil, 2, 4) --Дробление
local specWarnRazorShards			= mod:NewSpecialWarningDodge(188169, nil, nil, nil, 3, 4) --Бритвенно-острые осколки
local specWarnGas					= mod:NewSpecialWarningGTFO(192800, nil, nil, nil, 1, 8) --Удушающая пыль

local timerShatterCD				= mod:NewCDCountTimer(24.9, 188114, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON, nil, 2, 5) --Дробление
local timerRazorShardsCD			= mod:NewCDTimer(26.1, 188169, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON) --Бритвенно-острые осколки

mod.vb.shatterCount = 0

function mod:OnCombatStart(delay)
	self.vb.shatterCount = 0
	timerShatterCD:Start(19.9-delay, 1)
	timerRazorShardsCD:Start(28.9-delay)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 188169 then
		specWarnRazorShards:Show()
		specWarnRazorShards:Play("shockwave")
		timerRazorShardsCD:Start()
	elseif spellId == 188114 then --Дробление
		self.vb.shatterCount = self.vb.shatterCount + 1
		warnShatter:Show(self.vb.shatterCount)
		specWarnShatter:Show()
		specWarnShatter:Play("defensive")
		timerShatterCD:Start(nil, self.vb.shatterCount+1)
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 192800 and destGUID == UnitGUID("player") and self:AntiSpam(2.5, 1) then
		specWarnGas:Show(spellName)
		specWarnGas:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
