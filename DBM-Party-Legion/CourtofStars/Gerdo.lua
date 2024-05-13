local mod	= DBM:NewMod(1718, "DBM-Party-Legion", 7, 800)
local L		= mod:GetLocalizedStrings()

mod.statTypes = "heroic,mythic,challenge,timewalker"

mod:SetRevision("20230504231118")
mod:SetCreatureID(104215)
mod:SetEncounterID(1868)
mod:SetHotfixNoticeRev(20221127000000)
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 207261 207815",
	"SPELL_CAST_SUCCESS 207278 219488 207806"
)

--[[
(ability.id = 207261 or ability.id = 207815 or ability.id = 207806) and type = "begincast"
 or (ability.id = 219488 or ability.id = 207278) and type = "cast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
local warnPhase						= mod:NewPhaseChangeAnnounce(2, 2, nil, nil, nil, nil, nil, 2)
local warnStreetsweeper				= mod:NewTargetNoFilterAnnounce(219488, 2, nil, false)

local specWarnResonantSlash			= mod:NewSpecialWarningDodge(207261, nil, nil, nil, 2, 2)
local specWarnArcaneLockdown		= mod:NewSpecialWarningJump(207278, nil, nil, nil, 2, 6)
local specWarnBeacon				= mod:NewSpecialWarningSwitch(207806, nil, nil, nil, 1, 2)

local timerStreetsweeperCD			= mod:NewCDTimer(6, 219488, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Дворник
local timerResonantSlashCD			= mod:NewCDTimer(12.1, 207261, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Резонирующий удар сплеча
local timerArcaneLockdownCD			= mod:NewCDCountTimer(27.9, 207278, nil, nil, nil, 7) --Чародейская изоляция

mod.vb.arcaneLockdownCount = 0

function mod:OnCombatStart(delay)
	self.vb.arcaneLockdownCount = 0
	self:SetStage(1)
	timerResonantSlashCD:Start(6.2-delay)
	timerStreetsweeperCD:Start(11.1)
	timerArcaneLockdownCD:Start(15-delay, 1)
	--Allow trash mod to enable in combat since it's not uncommon to pull boss with some trash (usually by accident)
	local trashMod = DBM:GetModByName("CoSTrash")
	if trashMod then
		trashMod.isTrashModBossFightAllowed = true
	end
end

function mod:OnCombatEnd()
	local trashMod = DBM:GetModByName("CoSTrash")
	if trashMod then
		trashMod.isTrashModBossFightAllowed = false
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 207261 then
		specWarnResonantSlash:Show()
		specWarnResonantSlash:Play("watchstep")
		if self:GetStage(2) then
			timerResonantSlashCD:Start(10)
		else
			timerResonantSlashCD:Start()
		end
	elseif spellId == 207815 then --Настой священной ночи
		self.vb.arcaneLockdownCount = 0
		self:SetStage(2)
		warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(2))
		warnPhase:Play("ptwo")
		timerResonantSlashCD:Start(6.2)
		timerArcaneLockdownCD:Start(15, 1)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 207278 then--Success since jumping on cast start too early
		self.vb.arcaneLockdownCount = self.vb.arcaneLockdownCount + 1
		specWarnArcaneLockdown:Show()
		specWarnArcaneLockdown:Play("keepjump")
		if self:GetStage(2) then
			timerArcaneLockdownCD:Start(26.7, self.vb.arcaneLockdownCount+1)
		else
			timerArcaneLockdownCD:Start(27.9, self.vb.arcaneLockdownCount+1)
		end
	elseif spellId == 219488 then
		warnStreetsweeper:Show(args.destName)
		timerStreetsweeperCD:Start()
	elseif spellId == 207806 then
		specWarnBeacon:Show()
		specWarnBeacon:Play("mobsoon")
	end
end
