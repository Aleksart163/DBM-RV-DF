local mod	= DBM:NewMod(2494, "DBM-Party-Dragonflight", 4, 1199)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240412191704")
mod:SetCreatureID(181861)
mod:SetEncounterID(2610)
mod:SetHotfixNoticeRev(20230507000000)
--mod:SetMinSyncRevision(20211203000000)
--mod.respawnTime = 29
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 374365 375068 375251 375439",
	"SPELL_CAST_SUCCESS 375436",
	"SPELL_PERIODIC_DAMAGE 375204",
	"SPELL_PERIODIC_MISSED 375204"
)

--[[
(ability.id = 374365 or ability.id = 375068 or ability.id = 375251 or ability.id = 375439) and type = "begincast"
 or (ability.id = 376169 or ability.id = 375436) and type = "cast"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
--NOTE, target scan for lava spray is veru slow, so only used for yell and target announce, everyone will get shockwave warning right away.
--NOTE: Magma Lob is cast by EACH tentacle, it's downgraded to normal warning by default and timer disabled because it gets spammy later fight

local warnMagmaLob								= mod:NewSpellAnnounce(375068, 3) --Бросок магмы
local warnVolatileMutation						= mod:NewCountAnnounce(374365, 3) --Неустойчивая мутация
local warnLavaSpray								= mod:NewTargetNoFilterAnnounce(375251, 3) --Поток лавы

local specWarnVolatileMutation					= mod:NewSpecialWarningDefensive(374365, "-Tank", 70311, nil, 2, 2) --Неустойчивая мутация
local specWarnMagmaLob							= mod:NewSpecialWarningDodge(375068, false, nil, 2, 2, 2) --Бросок магмы
local specWarnLavaSpray							= mod:NewSpecialWarningDodge(375251, nil, nil, nil, 2, 2) --Поток лавы
local specWarnLavaSpray2						= mod:NewSpecialWarningDefensive(375251, nil, nil, nil, 3, 4) --Поток лавы
local specWarnBlazingCharge						= mod:NewSpecialWarningDodge(375436, nil, nil, nil, 2, 4) --Пылающий рывок
local specWarnGTFO								= mod:NewSpecialWarningGTFO(375204, nil, nil, nil, 1, 8) --Жидкая магма

local timerRP									= mod:NewRPTimer(30)
--local timerMagmaLobCD							= mod:NewCDTimer(6.5, 375068, nil, nil, nil, 3)--8 unless delayed by other casts
local timerLavaSrayCD							= mod:NewCDCountTimer(90, 375251, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Поток лавы
local timerBlazingChargeCD						= mod:NewCDCountTimer(90, 375436, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Пылающий рывок
local timerVolatileMutationCD					= mod:NewCDCountTimer(90, 374365, 70311, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON..DBM_COMMON_L.HEALER_ICON, nil, 2, 5) --Неустойчивая мутация Can get spell queued behind other abilities

local yellLavaSpray								= mod:NewYell(375251, nil, nil, nil, "YELL") --Поток лавы
local yellBlazingCharge							= mod:NewYell(375436, nil, nil, nil, "YELL") --Пылающий рывок

mod.vb.mutationCount = 0
mod.vb.lavaSrayCount = 0
mod.vb.blazingChargeCount = 0

local allProshlyapationsOfMurchal = {
	--Поток лавы
	[375251] = {7.2, 19.4, 58.4, 19.4, 19.4, 19.4, 79.6, 19.4, 38.9, 19.4},
	--Пылающий рывок
	[375436] = {19.3, 23, 69.6, 45.1, 69.1, 33, 46.3},
	--Мутация
	[374365] = {30.8, 31.1, 31.4, 30.2, 37.3, 31, 31, 30.9, 31.1, 33.2},
}

function mod:LavaSprayTarget(targetname)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnLavaSpray2:Show()
		specWarnLavaSpray2:Play("defensive")
		yellLavaSpray:Yell()
	else
		warnLavaSpray:Show(targetname)
		specWarnLavaSpray:Show()
		specWarnLavaSpray:Play("shockwave")
	end
end

function mod:OnCombatStart(delay)
	self.vb.mutationCount = 0
	self.vb.lavaSrayCount = 0
	self.vb.blazingChargeCount = 0
	timerLavaSrayCD:Start(7.2-delay, 1)--
--	timerMagmaLobCD:Start(8-delay)
	timerBlazingChargeCD:Start(19.3-delay, 1)--
	timerVolatileMutationCD:Start(30.8-delay, 1)--
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 374365 then --Неустойчивая мутация
		self.vb.mutationCount = self.vb.mutationCount + 1
		warnVolatileMutation:Show(self.vb.mutationCount)
		specWarnVolatileMutation:Show()
		specWarnVolatileMutation:Play("defensive")
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.mutationCount+1)
		if timer then
			timerVolatileMutationCD:Start(timer, self.vb.mutationCount+1)
		end
	--	timerVolatileMutationCD:Start(nil, self.vb.mutationCount+1)
	elseif spellId == 375068 and self:AntiSpam(2, "MagmaLob") then --Бросок магмы
		if self.Options.SpecWarn375068dodge then
			specWarnMagmaLob:Show()
			specWarnMagmaLob:Play("watchstep")
		else
			warnMagmaLob:Show()
		end
--		timerMagmaLobCD:Start()
	elseif spellId == 375251 then --Поток лавы
		self.vb.lavaSrayCount = self.vb.lavaSrayCount + 1
	--	self:BossUnitTargetScanner("boss1", "LavaSprayTarget", 2.4, true)--Allow tank true
		self:BossTargetScanner(args.sourceGUID, "LavaSprayTarget", 0.1, 2)
--		self:ScheduleMethod(0.2, "BossTargetScanner", args.sourceGUID, "LavaSprayTarget", 0.2, 12, true)
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, spellId, self.vb.lavaSrayCount+1)
		if timer then
			timerLavaSrayCD:Start(timer, self.vb.lavaSrayCount+1)
		end
	--	timerLavaSrayCD:Start(nil, self.vb.lavaSrayCount+1)
	elseif spellId == 375439 then --Пылающий рывок
		self.vb.blazingChargeCount = self.vb.blazingChargeCount + 1
		specWarnBlazingCharge:Show()
		specWarnBlazingCharge:Play("chargemove")
		local timer = self:GetFromTimersTable(allProshlyapationsOfMurchal, false, false, 375436, self.vb.blazingChargeCount+1)
		if timer then
			timerBlazingChargeCD:Start(timer, self.vb.blazingChargeCount+1)
		end
	--	timerBlazingChargeCD:Start(nil, self.vb.blazingChargeCount+1)
	end
end

--[[
function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 375436 then--Blazing Charge trigger with target information (Although pretty sure it's always on the tank)
		specWarnBlazingCharge:Show()
		specWarnBlazingCharge:Play("chargemove")
		timerBlazingChargeCD:Start()
		if args:IsPlayer() then
			yellBlazingCharge:Yell()
		end
	end
end]]

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 375204 and destGUID == UnitGUID("player") and self:AntiSpam(3, 2) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE

function mod:OnSync(msg)
	---@diagnostic disable-next-line: dbm-sync-checker
	if msg == "TuskRP" and self:AntiSpam(10, 9) then--Sync sent from trash mod since trash mod is already monitoring out of combat CLEU events
		timerRP:Start(6.5)
	end
end
