local mod	= DBM:NewMod(664, "DBM-Party-MoP", 1, 313)
local L		= mod:GetLocalizedStrings()

mod.statTypes = "normal,heroic,challenge,timewalker"

mod:SetRevision("20230410103707")
mod:SetCreatureID(59051, 59726, 58826)--59051 (Strife), 59726 (Anger), 58826 (Zao Sunseeker). This event has a random chance to be Zao (solo) or Anger and Strife (together)
mod:SetEncounterID(1417)
mod:SetUsedIcons(8)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 113315 113309 396150 396152",
	"SPELL_AURA_APPLIED_DOSE 113315 396150",
	"SPELL_AURA_REMOVED 113315 113309 396150",
	"SPELL_CAST_SUCCESS 122714",
	"UNIT_DIED"
)

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL"
)

--Stuff that might be used with more data--
--4/6 12:57:22.825  UNIT_DISSIPATES,0x0000000000000000,nil,0x80000000,0x80000000,0xF130DEF800005B63,"Corrupted Scroll",0xa48,0x0
-------------------------------------------
local warnFeelingSuperiority		= mod:NewTargetNoFilterAnnounce(396150, 4) --Чувство превосходства
local warnFeelingSuperiority2		= mod:NewStackAnnounce(396150, 4) --Чувство превосходства
local warnUltimatePower				= mod:NewTargetNoFilterAnnounce(113309, 2) --Первичная мощь

local specWarnFeelingSuperiority	= mod:NewSpecialWarningYou(396150, nil, nil, nil, 3, 6) --Чувство превосходства
local specWarnFeelingSuperiority2	= mod:NewSpecialWarningStack(396150, nil, 4, nil, nil, 1, 4) --Чувство превосходства
local specWarnFeelingInferiority	= mod:NewSpecialWarningYou(396152, nil, nil, nil, 1, 2) --Чувство неполноценности
local specWarnIntensity				= mod:NewSpecialWarningTargetCount(113315, "-Healer", nil, nil, 3, 6) --Напряженность
local specWarnUltimatePower			= mod:NewSpecialWarningTarget(113309, nil, nil, nil, 1, 2) --Первичная мощь

local timerRP						= mod:NewRPTimer(17.4)
local timerUltimatePower			= mod:NewTargetTimer(15, 113309, nil, nil, nil, 5)
local timerFeelingInferiority		= mod:NewBuffActiveTimer(20, 396152, nil, nil, nil, 3) --Чувство неполноценности

local yellFeelingSuperiority		= mod:NewYell(396150, nil, nil, nil, "YELL") --Чувство превосходства

mod:AddInfoFrameOption(113315, true)
mod:AddSetIconOption("SetIconOnFeelingSuperiority", 396150, true, false, {8}) --Чувство превосходства

mod.vb.bossesDead = 0

local murchalProshlyapStacks = {}

function mod:OnCombatStart(delay)
	table.wipe(murchalProshlyapStacks)
	self.vb.bossesDead = 0
	if self.Options.InfoFrame then
		DBM.InfoFrame:SetHeader(DBM:GetSpellInfo(113315))
		DBM.InfoFrame:Show(3, "table", murchalProshlyapStacks, 1)
	end
end

function mod:OnCombatEnd()
	table.wipe(murchalProshlyapStacks)
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 122714 then --Расторопность хранителей истории
		DBM:EndCombat(self)--Alternte win detection, UNIT_DIED not fire for 59051 (Strife), 59726 (Anger)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 113309 then --Первичная мощь
		warnUltimatePower:Show(args.destName)
		specWarnUltimatePower:Show(args.destName)
		specWarnUltimatePower:Play("aesoon")
		timerUltimatePower:Start(args.destName)
	elseif spellId == 396150 then --Чувство превосходства
		local amount = args.amount or 1
		if amount == 1 then
			if args:IsPlayer() then
				specWarnFeelingSuperiority:Show()
				specWarnFeelingSuperiority:Play("targetyou")
				yellFeelingSuperiority:Yell()
			else
				warnFeelingSuperiority:Show(args.destName)
			end
			if self.Options.SetIconOnFeelingSuperiority then
				self:SetIcon(args.destName, 8)
			end
		elseif amount >= 4 and amount % 2 == 0 then
			if args:IsPlayer() then
				specWarnFeelingSuperiority2:Show(amount)
				specWarnFeelingSuperiority2:Play("stackhigh")
			else
				warnFeelingSuperiority2:Show(args.destName, amount)
			end
		end
	elseif spellId == 396152 then --Чувство неполноценности
		if args:IsPlayer() then
			specWarnFeelingInferiority:Show()
			specWarnFeelingInferiority:Play("targetyou")
			timerFeelingInferiority:Start()
		end
	elseif spellId == 113315 then --Напряженность
		local amount = args.amount or 1
		murchalProshlyapStacks[args.destName] = amount
		if amount == 7 then--Start point of special warnings subject to adjustment based on live tuning.
			specWarnIntensity:Show(amount, args.destName)
			specWarnIntensity:Play("targetchange")
		end
		if self.Options.InfoFrame then
			DBM.InfoFrame:UpdateTable(murchalProshlyapStacks)
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 113309 then
		timerUltimatePower:Stop(args.destName)
	elseif spellId == 396150 then --Чувство превосходства
		if self.Options.SetIconOnFeelingSuperiority then
			self:SetIcon(args.destName, 0)
		end
	elseif spellId == 113315 then --Напряженность
		murchalProshlyapStacks[args.destName] = nil
		if self.Options.InfoFrame then
			DBM.InfoFrame:UpdateTable(murchalProshlyapStacks)
		end
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 59051 or cid == 59726 then--These 2 both have to die for fight to end
		self.vb.bossesDead = self.vb.bossesDead + 1
		if self.vb.bossesDead == 2 then
			DBM:EndCombat(self)
		end
	elseif cid == 58826 then--This one is by himself so we don't need special rules
		DBM:EndCombat(self)
	end
end

--"<19.62 23:24:18> [CHAT_MSG_MONSTER_YELL] Ah, it is not yet over. From what I see, we face the trial of the yaungol. Let me shed some light...#Lorewalker Stonestep#####0#0##0#4721#nil#0#false#false#false#false", -- [23]
--"<28.33 23:24:27> [CHAT_MSG_MONSTER_YELL] As the tale goes, the yaungol was traveling across the Kun'lai plains when suddenly he was ambushed by two strange creatures!#Lorewalker Stonestep#####0#0##0#4722#nil#0#false#false#false#false", -- [29]
--"<37.08 23:24:35> [ENCOUNTER_START] 1417#Lorewalker Stonestep#1#5", -- [32]
--
--"<21.88 20:20:20> [CHAT_MSG_MONSTER_YELL] Oh, my. If I am not mistaken, it appears that the tale of Zao Sunseeker has come to life before us.#Lorewalker Stonestep#####0#0##0#1161#nil#0#false#false#false#false", -- [17]
--"<53.36 20:20:52> [ENCOUNTER_START] 1417#Lorewalker Stonestep#2#5", -- [22]
function mod:CHAT_MSG_MONSTER_YELL(msg, npc, _, _, target)
	if (msg == L.Event1 or msg:find(L.Event1)) then
		self:SendSync("LibraryRP1")
	elseif (msg == L.Event2 or msg:find(L.Event2)) then
		self:SendSync("LibraryRP2")
	end
end

function mod:OnSync(msg, targetname)
	if msg == "LibraryRP1" then
		timerRP:Start(17.4)
	elseif msg == "LibraryRP2" then
		timerRP:Start(21)
	end
end

