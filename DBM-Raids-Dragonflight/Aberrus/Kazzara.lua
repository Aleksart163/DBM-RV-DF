local mod	= DBM:NewMod(2522, "DBM-Raids-Dragonflight", 2, 1208)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20231120131222")
mod:SetCreatureID(201261)
mod:SetEncounterID(2688)
mod:SetUsedIcons(1, 2, 3, 4, 5)
mod:SetHotfixNoticeRev(20230619000000)
mod:SetMinSyncRevision(20230510000000)
mod.respawnTime = 30

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 401316 401318 401319 406516 407198 407199 407200 407069 400430 403326 404744",
	"SPELL_AURA_APPLIED 406525 402253 404743",
	"SPELL_AURA_REMOVED 406525",
	"SPELL_PERIODIC_DAMAGE 406530 402207 402420",
	"SPELL_PERIODIC_MISSED 406530 402207 402420"
)

--[[
(ability.id = 401316 or ability.id = 401318 or ability.id = 401319 or ability.id = 406516 or ability.id = 407198 or ability.id = 407199 or ability.id = 407200 or ability.id = 407069 or ability.id = 400430 or ability.id = 403326 or ability.id = 404744) and type = "begincast"
--]]
local warnDreadRifts								= mod:NewTargetCountAnnounce(407196, 3) --Ужасные разломы
local warnDreadRayofAnguish							= mod:NewTargetCountAnnounce(407069, 4)
local warnTerrorClaws								= mod:NewTargetNoFilterAnnounce(404743, 4, nil, "Tank|Healer") --Ужасные когти

local specWarnHellsteelCarnage						= mod:NewSpecialWarningDodgeCount(401319, nil, nil, nil, 2, 2)
local specWarnDreadRift								= mod:NewSpecialWarningYou(407196, nil, nil, nil, 4, 2) --Ужасные разломы
local specWarnRayofAnguish							= mod:NewSpecialWarningYou(402253, nil, nil, nil, 4, 4) --Луч жестокой боли
local specWarnHellbeam								= mod:NewSpecialWarningDodgeCount(400430, nil, 18357, nil, 2, 2)
local specWarnWindsofExtinction						= mod:NewSpecialWarningCount(403326, nil, nil, nil, 2, 13)
local specWarnTerrorClaws							= mod:NewSpecialWarningDefensive(404743, nil, nil, nil, 1, 2) --Ужасные когти
local specWarnTerrorClawsTaunt						= mod:NewSpecialWarningTaunt(404743, nil, nil, nil, 1, 2) --Ужасные когти
local specWarnGTFO									= mod:NewSpecialWarningGTFO(406530, nil, nil, nil, 1, 8)
--
local timerDreadRiftsCD								= mod:NewCDCountTimer(34, 407196, nil, nil, nil, 3) --Ужасные разломы
local timerRaysofAnguishCD							= mod:NewCDCountTimer(34, 407069, nil, nil, nil, 3)
local timerHellbeamCD								= mod:NewCDCountTimer(35.5, 400430, 18357, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON)--"Breath"
local timerWingsofExtinctionCD						= mod:NewCDCountTimer(34, 403326, nil, nil, nil, 2, nil, DBM_COMMON_L.HEALER_ICON)
local timerTerrorClawsCD							= mod:NewCDTimer(15.6, 404743, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON) --Ужасные когти
--local berserkTimer								= mod:NewBerserkTimer(600)

local yellTerrorClaws								= mod:NewShortYell(404743, nil, nil, nil, "YELL") --Ужасные когти
local yellDreadRift									= mod:NewShortPosYell(407196, nil, nil, nil, "YELL") --Ужасные разломы
local yellDreadRiftFades							= mod:NewIconFadesYell(407196, nil, nil, nil, "YELL") --Ужасные разломы
local yellRayofAnguish								= mod:NewShortYell(402253, nil, nil, nil, "YELL") --Луч жестокой боли

mod:AddSetIconOption("SetIconOnDreadRifts", 407196, false, 0, {1, 2, 3, 4, 5, 6, 7, 8})--Default to off, players need to get used to this not existing
mod:GroupSpells(407196, 406525)--Group Dread Rifts with Dread Rift
mod:GroupSpells(407069, 402253)--Group Rays with Ray

mod.vb.carnageCount = 0
mod.vb.riftsCount = 0
mod.vb.riftIcon = 1
mod.vb.rayCount = 0
mod.vb.hellCount = 0
mod.vb.wingsCount = 0

function mod:TerrorClawsTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnTerrorClaws:Show()
		specWarnTerrorClaws:Play("defensive")
		yellTerrorClaws:Yell()
	else
		warnTerrorClaws:Show(targetname)
	end
end

function mod:OnCombatStart(delay)
	self.vb.carnageCount = 0
	self.vb.riftsCount = 0
	self.vb.riftIcon = 1
	self.vb.rayCount = 0
	self.vb.hellCount = 0
	self.vb.wingsCount = 0
	timerTerrorClawsCD:Start(3.4)
	timerDreadRiftsCD:Start(7, 1)
	timerWingsofExtinctionCD:Start(14.3, 1)
	timerRaysofAnguishCD:Start(24, 1)
	timerHellbeamCD:Start(29.2, 1)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if args:IsSpellID(401316, 401318, 401319) then
		self.vb.carnageCount = self.vb.carnageCount + 1
		specWarnHellsteelCarnage:Show(self.vb.carnageCount)
		specWarnHellsteelCarnage:Play("watchstep")
		--Add 9 seconds to all timers. May be diff in other difficulties so needs review
		timerDreadRiftsCD:AddTime(9, self.vb.riftsCount+1)
		timerRaysofAnguishCD:AddTime(9, self.vb.rayCount+1)
		timerHellbeamCD:AddTime(9, self.vb.hellCount+1)
		timerWingsofExtinctionCD:AddTime(9, self.vb.wingsCount+1)
	elseif args:IsSpellID(406516, 407198, 407199, 407200) then--Each Id adds 1 additional rift, base Id starts at 2 or 3
		self.vb.riftsCount = self.vb.riftsCount + 1
		self.vb.riftIcon = 1
		timerDreadRiftsCD:Start(nil, self.vb.riftsCount+1)
	elseif spellId == 407069 then
		self.vb.rayCount = self.vb.rayCount + 1
		timerRaysofAnguishCD:Start(nil, self.vb.rayCount+1)
	elseif spellId == 400430 then
		self.vb.hellCount = self.vb.hellCount + 1
		specWarnHellbeam:Show(self.vb.hellCount)
		specWarnHellbeam:Play("watchstep")
		timerHellbeamCD:Start(nil, self.vb.hellCount+1)
	elseif spellId == 403326 then
		self.vb.wingsCount = self.vb.wingsCount + 1
		specWarnWindsofExtinction:Show(self.vb.wingsCount)
		specWarnWindsofExtinction:Play("pushbackincoming")
		timerWingsofExtinctionCD:Start(nil, self.vb.wingsCount+1)
	elseif spellId == 404744 then --Ужасные когти
		self:BossTargetScanner(args.sourceGUID, "TerrorClawsTarget", 0.1, 2)
		timerTerrorClawsCD:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 406525 then
		local icon = self.vb.riftIcon
		if self.Options.SetIconOnDreadRifts then
			self:SetIcon(args.destName, icon)
		end
		if args:IsPlayer() then
			specWarnDreadRift:Show()
			specWarnDreadRift:Play("targetyou")
			yellDreadRift:Yell(icon, icon)
			yellDreadRiftFades:Countdown(spellId, nil, icon)
		end
		warnDreadRifts:CombinedShow(1.1, self.vb.riftsCount, args.destName)--Needs to be 1.1 for the 5 set
		self.vb.riftIcon = self.vb.riftIcon + 1
	elseif spellId == 402253 then
		if args:IsPlayer() then
			specWarnRayofAnguish:Show()
			specWarnRayofAnguish:Play("laserrun")
			yellRayofAnguish:Yell()
		end
		warnDreadRayofAnguish:CombinedShow(1.1, self.vb.rayCount, args.destName)
	elseif spellId == 404743 and not args:IsPlayer() then
		specWarnTerrorClawsTaunt:Show(args.destName)
		specWarnTerrorClawsTaunt:Play("tauntboss")
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 406525 then
		if self.Options.SetIconOnDreadRifts then
			self:SetIcon(args.destName, 0)
		end
		if args:IsPlayer() then
			yellDreadRiftFades:Cancel()
		end
	end
end


function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if (spellId == 406530 or spellId == 402207 or spellId == 402420) and destGUID == UnitGUID("player") and self:AntiSpam(2, 2) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
