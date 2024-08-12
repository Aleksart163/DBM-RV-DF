local mod	= DBM:NewMod(2095, "DBM-Party-BfA", 2, 1001)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20230804233648")
mod:SetCreatureID(126983)
mod:SetEncounterID(2096)
mod:SetUsedIcons(8, 7, 6, 5, 4)
mod:SetHotfixNoticeRev(20240610070000)
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 257402 257458 413145 413147 413131 413136",
	"SPELL_CAST_SUCCESS 257316",--257278
	"SPELL_AURA_APPLIED 257314 257305 413131",
	"SPELL_AURA_REMOVED 257314 257305",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

--[[
(ability.id = 257402 or ability.id = 257458 or ability.id = 413145 or ability.id = 413147 or ability.id = 413131 or ability.id = 413136) and type = "begincast"
 or (ability.id = 257316 or ability.id = 257278 or ability.id = 257453 or ability.id = 257304) and type = "cast"
 or (ability.id = 257305 or ability.id = 257314) and type = "applydebuff"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
 --]]
local warnPhase						= mod:NewPhaseChangeAnnounce(2, nil, nil, nil, nil, nil, nil, 2)
local warnBlackPowder				= mod:NewTargetNoFilterAnnounce(257314, 4, nil, nil, 174716) --Бомба с черным порохом (Бомба)
local warnCannonBarrage				= mod:NewTargetNoFilterAnnounce(257305, 4) --Обстрел
local warnWhirlingDagger			= mod:NewSpellAnnounce(413131, 3) --Вращающийся кинжал

local specWarnWhirlingDagger		= mod:NewSpecialWarningYou(413131, nil, nil, nil, 1, 4) --Вращающийся кинжал
local specWarnWhirlingDagger2		= mod:NewSpecialWarningTarget(413131, "Healer", nil, nil, 1, 4) --Вращающийся кинжал
local specWarnBlackPowderBomb		= mod:NewSpecialWarningRun(257314, nil, 174716, nil, 4, 4) --Бомба с черным порохом (Бомба)
local specWarnSwiftwindSaber		= mod:NewSpecialWarningDodge(257278, nil, nil, nil, 2, 2) --Сабля повелителя пассатов
local specWarnCannonBarrage			= mod:NewSpecialWarningDodge(257305, nil, nil, nil, 3, 2) --Обстрел

local timerBlackPowderBombCD		= mod:NewCDTimer(13, 257314, 174716, nil, nil, 1, nil, DBM_COMMON_L.DAMAGE_ICON..DBM_COMMON_L.DEADLY_ICON, nil, 2, 3) --Бомба с черным порохом (Бомба)
local timerSwiftwindSaberCD			= mod:NewCDTimer(15.8, 257278, nil, nil, nil, 3) --Сабля повелителя пассатов Swap option key to 413147 if non M+ version also is changed
local timerCannonBarrageCD			= mod:NewCDTimer(17.4, 257305, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 5) --Обстрел
local timerWhirlingDaggerCD			= mod:NewCDCountTimer(18.8, 413131, nil, nil, nil, 5, nil, DBM_COMMON_L.HEALER_ICON..DBM_COMMON_L.BLEED_ICON) --Вращающийся кинжал

local yellBlackPowder				= mod:NewShortYell(257314, nil, nil, nil, "YELL") --Бомба с черным порохом (Бомба)
local yellBlackPowder2				= mod:NewShortFadesYell(257314, nil, nil, nil, "YELL") --Бомба с черным порохом (Бомба)
local yellCannonBarrage				= mod:NewShortYell(257305, nil, nil, nil, "YELL") --Обстрел
local yellCannonBarrage2			= mod:NewShortFadesYell(257305, nil, nil, nil, "YELL") --Обстрел


mod:AddSetIconOption("SetIconOnBlackPowder", 257314, true, 0, {8}) --Бомба с черным порохом
mod:AddSetIconOption("SetIconOnCannonBarrage", 257305, true, 0, {7, 6, 5, 4}) --Обстрел

mod.vb.daggerCount = 0
mod.vb.cannonBarrageIcon = 7
mod.vb.blackPowderBombCount = 0
mod.vb.cannonBarrageCount = 0

function mod:OnCombatStart(delay)
	self.vb.daggerCount = 0
	self.vb.cannonBarrageIcon = 7
	self.vb.blackPowderBombCount = 0
	self.vb.cannonBarrageCount = 0
	self:SetStage(1)
	timerSwiftwindSaberCD:Start(10.9-delay) --Сабля повелителя пассатов
	timerCannonBarrageCD:Start(20.6-delay, 1) --Обстрел
	timerBlackPowderBombCD:Start(32.7-delay, 1) --Бомба с черным порохом (Бомба)
	if self:IsMythicPlus() then
		timerWhirlingDaggerCD:Start(14.1-delay, 1) --Вращающийся кинжал
	end
end
--02.19.21.029 (фаза 1)
--Обстрел
--02.19.41.664 (20.6 с фазы 1)
--02.20.07.076 (25.4 с 1 по 2)
--Бомба
--02.19.53.766 (32.7 с фазы 1)
--02.20.19.283 (25.5 с 1 по 2)
--02.20.30.991 (фаза 2)
--Обстрел
--02.20.46.685 (15.6 с фазы 2)
--02.21.12.125 (25.4 с 1 по 2)
--02.21.38.935 (26.8 с 2 по 3)
--Бомба
--02.20.52.809 1 бомба (21.8 с фазы 2)
--02.21.20.816 2 бомба (28 с 1 по 2)

--02.21.40.221 (фаза 3)
--02.21.55.967 (обстрел)
--02.22.02.059 (бомба)

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 257402 then--Шулерские кости: аврал! (2 фаза)
		self:SetStage(2)
		warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(2))
		warnPhase:Play("ptwo")
		timerSwiftwindSaberCD:Stop()
		timerBlackPowderBombCD:Stop()
		timerCannonBarrageCD:Stop()
		timerWhirlingDaggerCD:Stop()
		--1-ые таймеры с начала фазы 2 (всё ок)--
		timerSwiftwindSaberCD:Start(10.8) --
		timerCannonBarrageCD:Start(15.6, self.vb.cannonBarrageCount+1) --
		timerBlackPowderBombCD:Start(21.8, self.vb.blackPowderBombCount+1) --
		if self:IsMythicPlus() then
			timerWhirlingDaggerCD:Start(13.9, self.vb.daggerCount+1) --
		end
	elseif spellId == 257458 then--Шулерские кости: линкор (3 фаза)
		self:SetStage(3)
		warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(3))
		warnPhase:Play("pthree")
		timerSwiftwindSaberCD:Stop()
		timerBlackPowderBombCD:Stop()
		timerCannonBarrageCD:Stop()
		timerWhirlingDaggerCD:Stop()
		--1-ые таймеры с начала фазы 3 (всё ок)--
		timerSwiftwindSaberCD:Start(10.8) --
		timerCannonBarrageCD:Start(15.7, self.vb.cannonBarrageCount+1) --
		timerBlackPowderBombCD:Start(21.8, self.vb.blackPowderBombCount+1) --
		if self:IsMythicPlus() then
			timerWhirlingDaggerCD:Start(14, self.vb.daggerCount+1) --
		end
	elseif spellId == 413145 or spellId == 413147 then--Shadowlands S2 version
		specWarnSwiftwindSaber:Show()
		specWarnSwiftwindSaber:Play("watchwave")
		if self:GetStage(3) then
			timerSwiftwindSaberCD:Start(12.5)--12.5-14
		else
			timerSwiftwindSaberCD:Start(18)--18-20
		end
	elseif spellId == 413131 or spellId == 413136 then
		self.vb.daggerCount = self.vb.daggerCount + 1
		warnWhirlingDagger:Show()
		if self:GetStage(3) then
			timerWhirlingDaggerCD:Start(11.7, self.vb.daggerCount+1)--11.7-15
		else
			timerWhirlingDaggerCD:Start(17.6, self.vb.daggerCount+1)
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 257316 then
		self.vb.blackPowderBombCount = self.vb.blackPowderBombCount + 1
		if self:GetStage(3) then
			timerBlackPowderBombCD:Start(20.6, self.vb.blackPowderBombCount+1)--20.6-23.1
		else
			timerBlackPowderBombCD:Start(25.5, self.vb.blackPowderBombCount+1)--25.5--27
		end
--	elseif spellId == 257278 then--Legacy version
--		specWarnSwiftwindSaber:Show()
--		specWarnSwiftwindSaber:Play("watchwave")
--		timerSwiftwindSaberCD:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 257314 and args:IsDestTypePlayer() then --Бомба с черным порохом
		if args:IsPlayer() then
			specWarnBlackPowderBomb:Show()
			specWarnBlackPowderBomb:Play("bombrun")
			yellBlackPowder:Yell()
			yellBlackPowder2:Countdown(spellId)
		else
			warnBlackPowder:Show(args.destName)
		end
		if self.Options.SetIconOnBlackPowder then
			self:SetIcon(args.destName, 8)
		end
	elseif spellId == 257305 then --Обстрел
		local icon = self.vb.cannonBarrageIcon
		if self.Options.SetIconOnCannonBarrage then
			self:SetIcon(args.destName, icon)
		end
		if args:IsPlayer() then
			specWarnCannonBarrage:Show()
			specWarnCannonBarrage:Play("watchstep")
			yellCannonBarrage:Yell()
			yellCannonBarrage2:Countdown(spellId)
		else
			if self:GetStage(1) then
				warnCannonBarrage:Show(args.destName)
			end
		end
		self.vb.cannonBarrageIcon = self.vb.cannonBarrageIcon - 1
	elseif spellId == 413131 then --Вращающийся кинжал
		if args:IsPlayer() then
			specWarnWhirlingDagger:Show()
			specWarnWhirlingDagger:Play("targetyou")
		else
			if self:GetStage(1) then
				specWarnWhirlingDagger2:Show(args.destName)
				specWarnWhirlingDagger2:Play("healall")
			end
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 257314 then --Бомба с черным порохом
		if args:IsPlayer() then
			yellBlackPowder2:Cancel()
		end
		if self.Options.SetIconOnBlackPowder then
			self:SetIcon(args.destName, 0)
		end
	elseif spellId == 257305 then --Обстрел
		if args:IsPlayer() then
			yellCannonBarrage2:Cancel()
		end
		if self.Options.SetIconOnCannonBarrage then
			self:SetIcon(args.destName, 0)
		end
		self.vb.cannonBarrageIcon = self.vb.cannonBarrageIcon + 1
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, spellId)
	if spellId == 257453 or spellId == 257304 then--Cannon Barrage (Stage 1), Cannon Barrage (Stage 2/3)
		self.vb.cannonBarrageCount = self.vb.cannonBarrageCount + 1
		DBM:Debug("Murchal proshlyap", 2)
		if self:GetStage(3) then
			DBM:Debug("Murchal proshlyap 3", 2)
			timerCannonBarrageCD:Start(15.5, self.vb.cannonBarrageCount+1)
		else
			DBM:Debug("Murchal proshlyap 1 and 2", 2)
			timerCannonBarrageCD:Start(25, self.vb.cannonBarrageCount+1)
		end
	end
end
