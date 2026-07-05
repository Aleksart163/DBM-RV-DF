local mod	= DBM:NewMod(2532, "DBM-Raids-Dragonflight", 2, 1208)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240420001330")
mod:SetCreatureID(202375)
mod:SetEncounterID(2689)
mod:SetUsedIcons(8, 7, 6, 5, 4, 3, 2, 1)
mod:SetHotfixNoticeRev(20230718000000)
--mod:SetMinSyncRevision(20221215000000)
mod.respawnTime = 30

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 406678 405812 405919 403978 405886",
	"SPELL_CAST_SUCCESS 404007 406725 405736 181113 405812",
	"SPELL_AURA_APPLIED 405592 404010 404942 404955",
	"SPELL_AURA_APPLIED_DOSE 404942",
	"SPELL_AURA_REMOVED 404010 404942",
	"SPELL_DAMAGE 404955",
	"SPELL_MISSED 404955",
--	"SPELL_PERIODIC_DAMAGE",
--	"SPELL_PERIODIC_MISSED",
	"UNIT_DIED",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

--[[
(ability.id = 406678 or ability.id = 406725 or ability.id = 403978 or ability.id = 405812 or ability.id = 405919 or ability.id = 405886) and type = "begincast"
 or (ability.id = 404007 or ability.id = 406725 or ability.id = 405736) and type = "cast"
--]]
--TODO, icon method for golems will likely be changed to broodkeeper method since that's what BW is likely to use, but for testing purposes a basic incremental apply per set is probably fine
--TODO, GTFO for standing in fire traps
local warnSoakedShrapnal						= mod:NewAddsLeftAnnounce(404955, 2) --Шрапнельная бомба
local warnScatterTraps							= mod:NewCountAnnounce(404955, 2, nil, nil, 167180) --Шрапнельная бомба (Бомбы)
local warnSalvageParts							= mod:NewTargetNoFilterAnnounce(405592, 1) --Сбор запчастей
local warnSearingClaws							= mod:NewStackAnnounce(404942, 2, nil, "Tank|Healer") --Обжигающие когти

local specWarnTacticalDestruction				= mod:NewSpecialWarningDodgeCount(406678, nil, 309852, nil, 4, 2) --Тактическое разрушение (Разрушение)
local specWarnDragonDeezTraps					= mod:NewSpecialWarningCount(405736, nil, nil, DBM_COMMON_L.TRAPS, 1, 2) --Ловушки драконьего огня
local specWarnAnimateGolems						= mod:NewSpecialWarningCount(405812, nil, nil, nil, 1, 2) --Оживление големов
local specWarnAnimateGolems2					= mod:NewSpecialWarningSwitch(405812, nil, nil, DBM_COMMON_L.ADDS, 1, 2) --Оживление големов (Адды)
local specWarnActivateTrap						= mod:NewSpecialWarningInterruptCount(405919, "HasInterrupt", nil, DBM_COMMON_L.TRAPS, 1, 2) --Активация ловушки драконьего огня
local specWarnBlastWave							= mod:NewSpecialWarningCount(403978, nil, nil, DBM_COMMON_L.PUSHBACK, 2, 2) --Взрывная волна (Отталкивание)
local specWarnUnstableEmbers					= mod:NewSpecialWarningMoveAway(404010, nil, 264364, nil, 1, 2) --Нестабильные угли
local specWarnSearingClaws						= mod:NewSpecialWarningStack(404942, nil, 9, nil, nil, 1, 4) --Обжигающие когти
local specWarnSearingClawsTaunt					= mod:NewSpecialWarningTaunt(404942, nil, nil, nil, 1, 4) --Обжигающие когти
--local specWarnGTFO								= mod:NewSpecialWarningGTFO(370648, nil, nil, nil, 1, 8)

local timerTacticalDestructionCD				= mod:NewCDCountTimer(61.5, 406678, 309852, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Тактическое разрушение (Разрушение)
local timerShrapnalBombCD						= mod:NewCDCountTimer(42.5, 404955, 167180, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Шрапнельная бомба (Бомбы)
local timerShrapnalBomb							= mod:NewCastTimer(30, 404955, 185824, nil, nil, 7, nil, DBM_COMMON_L.DEADLY_ICON, nil, 2, 5) --Шрапнельная бомба (Взрыв)
local timerAnimateGolemsCD						= mod:NewCDCountTimer(60.2, 405812, DBM_COMMON_L.ADDS.." (%s)", nil, nil, 1, nil, DBM_COMMON_L.DAMAGE_ICON) --Оживление големов (Адды)
local timerBlastWaveCD							= mod:NewCDCountTimer(34, 403978, DBM_COMMON_L.PUSHBACK.." (%s)", nil, nil, 2) --Взрывная волна (Отталкивание)
local timerUnstableEmbersCD						= mod:NewCDCountTimer(20.7, 404010, 264364, nil, nil, 3, nil, DBM_COMMON_L.HEALER_ICON) --Нестабильные угли (Угли)
local timerEliminationProtocol					= mod:NewCastTimer(10, 409942, 207544, nil, nil, 3, nil, DBM_COMMON_L.MYTHIC_ICON) --Протокол устранения (Лучи)
local timerDragonDeezTrapsCD					= mod:NewCDCountTimer(32.2, 405736, DBM_COMMON_L.TRAPS.." (%s)", nil, nil, 3) --Ловушки драконьего огня
local berserkTimer								= mod:NewBerserkTimer(600)

local yellUnstableEmbers						= mod:NewShortYell(404010, 264364, nil, nil, "YELL") --Нестабильные угли (Угли)
local yellUnstableEmbersFades					= mod:NewShortFadesYell(404010, 264364, nil, nil, "YELL") --Нестабильные угли (Угли)

mod:AddInfoFrameOption(404942, "Tank|Healer")
mod:AddSetIconOption("SetIconOnGolems", 405812, true, 5, {8, 7, 6, 5})
mod:AddSetIconOption("SetIconOnEmbers", 404010, false, 0, {1, 2, 3, 4})

mod.vb.destructionCount = 0
mod.vb.shrapnalSoakCount = 0
mod.vb.trapCastCount = 0
mod.vb.golemsCount = 0
mod.vb.blastWaveCount = 0
mod.vb.embersCount = 0
mod.vb.dragonCount = 0
mod.vb.expectedBombs = 3
mod.vb.addIcon = 8
mod.vb.proshlyapBombCount = 0

local murchalProshlyapStacks = {}
local castsPerGUID = {}
local proshlyaptionMythicTimers = {34, 30.5, 30, 30, 30, 30, 30, 30, 30, 30, 30} --Первые 3 точно
local proshlyaptionHeroicTimers = {35, 30.5, 30, 30, 30, 30, 30, 30, 30, 30, 30} --Последние 4 возможно неточно
local proshlyaptionNormalTimers = {46, 31, 34, 31, 31, 31, 31, 31, 31, 31, 31} --Должно быть точно
local proshlyaptionDestructionMythicTimers = {31, 74.5, 75, 75, 75, 75, 75} --Первые 3 точно, дальше на проверке

local function checkBombProshlyap(self)
	self.vb.proshlyapBombCount = self.vb.proshlyapBombCount + 1
	self.vb.shrapnalSoakCount = 0
	local timer
	if self:IsMythic() then
		timer = proshlyaptionMythicTimers[self.vb.proshlyapBombCount+1]
	elseif self:IsHeroic() then
		timer = proshlyaptionHeroicTimers[self.vb.proshlyapBombCount+1]
	elseif self:IsNormal() then
		timer = proshlyaptionNormalTimers[self.vb.proshlyapBombCount+1]
	end
	warnScatterTraps:Show(self.vb.proshlyapBombCount)
	timerShrapnalBombCD:Start(timer, self.vb.proshlyapBombCount+1)
	timerShrapnalBomb:Start()
	self:Schedule(timer, checkBombProshlyap, self)
	DBM:Debug("Murchal Proshlyap (Проверка бомб)", 2)
end

function mod:OnCombatStart(delay)
	table.wipe(murchalProshlyapStacks)
	table.wipe(castsPerGUID)
	self.vb.destructionCount = 0
	self.vb.shrapnalSoakCount = 0
	self.vb.trapCastCount = 0
	self.vb.golemsCount = 0
	self.vb.blastWaveCount = 0
	self.vb.embersCount = 0
	self.vb.dragonCount = 0
	self.vb.proshlyapBombCount = 0
	timerBlastWaveCD:Start(10.7-delay, 1)--Same in All
	if self:IsMythic() then--Recheck
		self.vb.expectedBombs = 3
		timerUnstableEmbersCD:Start(9.1-delay, 1)
		timerDragonDeezTrapsCD:Start(19.2-delay, 1)
		timerAnimateGolemsCD:Start(26.2-delay, 1)
		timerTacticalDestructionCD:Start(31-delay, 1)
		timerShrapnalBombCD:Start(34-delay, 1) --Бомбы
		self:Schedule(34-delay, checkBombProshlyap, self) --Проверка бомб
	elseif self:IsHeroic() then--Validated
		self.vb.expectedBombs = 3
		timerUnstableEmbersCD:Start(7-delay, 1)
		timerDragonDeezTrapsCD:Start(19.3-delay, 1)
		timerShrapnalBombCD:Start(35-delay, 1) --Бомбы
		self:Schedule(35-delay, checkBombProshlyap, self) --Проверка бомб
		timerAnimateGolemsCD:Start(54.6-delay, 1)
		timerTacticalDestructionCD:Start(60.7-delay, 1)
	elseif self:IsNormal() then--Validated
		self.vb.expectedBombs = 2
		timerDragonDeezTrapsCD:Start(15.7-delay, 1)
		timerAnimateGolemsCD:Start(35-delay, 1)
		timerShrapnalBombCD:Start(46-delay, 1) --Бомбы
		self:Schedule(46-delay, checkBombProshlyap, self) --Проверка бомб
		timerTacticalDestructionCD:Start(70-delay, 1)
	else--Validated
		self.vb.expectedBombs = 2
		timerDragonDeezTrapsCD:Start(20.3-delay, 1)
		timerAnimateGolemsCD:Start(35-delay, 1)
		timerTacticalDestructionCD:Start(70-delay, 1)
	end
	if self.Options.InfoFrame then
		DBM.InfoFrame:SetHeader(DBM:GetSpellInfo(404942))
		DBM.InfoFrame:Show(3, "table", murchalProshlyapStacks, 1)
	end
	berserkTimer:Start(510-delay)--Confirm in LFR
end

function mod:OnCombatEnd()
	table.wipe(murchalProshlyapStacks)
	self:Unschedule(checkBombProshlyap)
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 406678 then
		self.vb.destructionCount = self.vb.destructionCount + 1
		specWarnTacticalDestruction:Show(self.vb.destructionCount)
		specWarnTacticalDestruction:Play("watchstep")
		local timer
		if self:IsMythic() then
			timer = proshlyaptionDestructionMythicTimers[self.vb.destructionCount+1]
		else
			timer = 71.6 --По старой информации в героике, обычке и лфр
		end
		timerTacticalDestructionCD:Start(timer, self.vb.destructionCount+1)
	elseif spellId == 405812 then --Оживление големов
		self.vb.addIcon = 8
		self.vb.golemsCount = self.vb.golemsCount + 1
		specWarnAnimateGolems:Show(self.vb.golemsCount)
		if self:IsTank() or self:IsHealer() then
			specWarnAnimateGolems:Play("bigmobsoon")
		else
			specWarnAnimateGolems:Play("bigmobsoon")
		end
		timerAnimateGolemsCD:Start(73, self.vb.golemsCount+1)--Can get spell queued up to 78
	elseif spellId == 405919 or spellId == 405886 then
		if not castsPerGUID[args.sourceGUID] then
			castsPerGUID[args.sourceGUID] = 0
		end
		castsPerGUID[args.sourceGUID] = castsPerGUID[args.sourceGUID] + 1
		local count = castsPerGUID[args.sourceGUID]
		if self:CheckInterruptFilter(args.sourceGUID, false, false) then--Count interrupt, so cooldown is not checked
			specWarnActivateTrap:Show(args.sourceName, count)
			if count < 6 then
				specWarnActivateTrap:Play("kick"..count.."r")
			else
				specWarnActivateTrap:Play("kickcast")
			end
		end
	elseif spellId == 403978 then
		self.vb.blastWaveCount = self.vb.blastWaveCount + 1
		specWarnBlastWave:Show(self.vb.blastWaveCount)
		specWarnBlastWave:Play("carefly")
		timerBlastWaveCD:Start(self:IsEasy() and 38 or 33.2, self.vb.blastWaveCount+1)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 404007 then
		self.vb.embersCount = self.vb.embersCount + 1
		timerUnstableEmbersCD:Start(15.7, self.vb.embersCount+1)
		if self:IsMythic() then
			timerEliminationProtocol:Start()
		end
	elseif spellId == 406725 then --Шрапнельная бомба (Сломано на сервере)
--		self.vb.shrapnalSoakCount = 0
--		self.vb.trapCastCount = self.vb.trapCastCount + 1
--		warnScatterTraps:Show(self.vb.trapCastCount)
--		timerShrapnalBombCD:Start(self:IsMythic() and 45.3 or 30.3, self.vb.trapCastCount+1)
--		timerShrapnalBomb:Start()
		DBM:Debug("Murchal proshlyap (Случился каст активации бомб)", 2)
	elseif spellId == 405736 then
		self.vb.dragonCount = self.vb.dragonCount + 1
		specWarnDragonDeezTraps:Show(self.vb.dragonCount)
		specWarnDragonDeezTraps:Play("watchstep")
		timerDragonDeezTrapsCD:Start(self:IsMythic() and 34 or self:IsEasy() and 35 or 30.4, self.vb.dragonCount+1)
	elseif spellId == 181113 then--Encounter Spawn
		if self.Options.SetIconOnGolems then
			self:ScanForMobs(args.sourceGUID, 2, self.vb.addIcon, 1, nil, 12, "SetIconOnGolems")
		end
		self.vb.addIcon = self.vb.addIcon - 1
	elseif spellId == 405812 then --Оживление големов
		specWarnAnimateGolems2:Show()
		if self:IsDps() then
			specWarnAnimateGolems2:Play("killmob")
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 405592 then
		warnSalvageParts:CombinedShow(1, args.destName) --Сбор запчастей
	elseif spellId == 404010 then
		if args:IsPlayer() then
			specWarnUnstableEmbers:Show()
			specWarnUnstableEmbers:Play("range5")
			yellUnstableEmbers:Yell()
			yellUnstableEmbersFades:Countdown(spellId)
		end
		if self.Options.SetIconOnEmbers then
			self:SetUnsortedIcon(0.3, args.destName, 1, 4, false)
		end
	elseif spellId == 404942 then --Обжигающие когти
		local amount = args.amount or 1
		murchalProshlyapStacks[args.destName] = amount
		if amount >= 9 and amount % 2 == 0 then
			if args:IsPlayer() then
				specWarnSearingClaws:Show(amount)
				specWarnSearingClaws:Play("stackhigh")
			else
				if not DBM:UnitDebuff("player", spellId) and not UnitIsDeadOrGhost("player") and not self:IsHealer() then
					specWarnSearingClawsTaunt:Show(args.destName)
					specWarnSearingClawsTaunt:Play("tauntboss")
				else
					warnSearingClaws:Show(args.destName, amount)
				end
			end
		end
		if self.Options.InfoFrame then
			DBM.InfoFrame:UpdateTable(murchalProshlyapStacks)
		end
	elseif spellId == 404955 then --Шрапнельная бомба
--[[		self.vb.shrapnalSoakCount = self.vb.shrapnalSoakCount + 1
		if self.vb.shrapnalSoakCount == self.vb.expectedBombs then
			timerShrapnalBomb:Stop()
		end]]
		DBM:Debug("Murchal proshlyap (На игрока наложилась аура бомбы)", 2)
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 404010 then
		if self.Options.SetIconOnEmbers then
			self:SetIcon(args.destName, 0)
		end
	elseif spellId == 404942 then --Обжигающие когти
		murchalProshlyapStacks[args.destName] = nil
		if self.Options.InfoFrame then
			DBM.InfoFrame:UpdateTable(murchalProshlyapStacks)
		end
	end
end

function mod:SPELL_DAMAGE(_, _, _, _, _, _, _, _, spellId)
	if spellId == 404955 then
		self.vb.shrapnalSoakCount = self.vb.shrapnalSoakCount + 1
		warnSoakedShrapnal:Show(self.vb.expectedBombs - self.vb.shrapnalSoakCount)
		if self.vb.shrapnalSoakCount == self.vb.expectedBombs then
			timerShrapnalBomb:Stop()
		end
		DBM:Debug("Murchal proshlyap (Игрок схватил урон от бомбы)", 2)
	end
end
mod.SPELL_MISSED = mod.SPELL_DAMAGE

--[[
function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 370648 and destGUID == UnitGUID("player") and self:AntiSpam(2, 2) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
--]]

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 203230 then--Dragonfire Golem
		castsPerGUID[args.destGUID] = nil
	end
end

--[[function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, spellId)
	if spellId == 402746 then --Парящие угли
		DBM:Debug("Check Murchal proshlyap 2", 2)
	end
end]]
