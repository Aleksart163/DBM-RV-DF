local mod	= DBM:NewMod("AmirdrassilTrash", "DBM-Raids-Dragonflight", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20260630000000")
--mod:SetModelID(47785)
mod.isTrashMod = true

mod:RegisterEvents(
	"SPELL_CAST_START 425062 425149 425995 429180 428023",
	"SPELL_CAST_SUCCESS 429180",
	"SPELL_AURA_APPLIED 428765 425300 425388 425381 428077",
--	"SPELL_AURA_APPLIED_DOSE",
	"SPELL_AURA_REMOVED 428765 425300 425388 428077",
	"CHAT_MSG_MONSTER_YELL",
	"UNIT_DIED"
)

--TODO, kick blazing pulse
--TODO, inferno heart spread
local warnDreamWalk							= mod:NewTargetNoFilterAnnounce(428077, 2) --Хождение во сне
local warnShadowflameBomb					= mod:NewTargetNoFilterAnnounce(425300, 3, nil, nil, 167180) --Бомба пламени Тьмы (Бомбы)
local warnInfernoHeart						= mod:NewTargetNoFilterAnnounce(425388, 3) --Сердце Преисподней
local warnShadowchargedSlam					= mod:NewCastAnnounce(425062, 3, nil, nil, "Melee") --Заряженный Тьмой удар

local specWarnDreamsWrath					= mod:NewSpecialWarningDodge(428023, nil, nil, DBM_COMMON_L.FRONTAL, 2, 2) --Гнев Сна (Фронталка)
local specWarnLumberingSlam					= mod:NewSpecialWarningDodge(429180, nil, nil, DBM_COMMON_L.FRONTAL, 2, 2) --Грузный удар (Фронталка)
local specWarnDreamWalk						= mod:NewSpecialWarningDispel(428077, "RemoveMagic", nil, nil, 1, 2) --Хождение во сне
local specWarnInfernoHeart					= mod:NewSpecialWarningMoveAway(425388, nil, nil, nil, 1, 2) --Сердце Преисподней
local specWarnInfernoHeartDispel			= mod:NewSpecialWarningDispel(425388, "RemoveCurse", nil, nil, 1, 2) --Сердце Преисподней
local specWarnShadowflameBomb				= mod:NewSpecialWarningMoveAway(425300, nil, 174716, nil, 1, 2) --Бомба пламени Тьмы (Бомба)
local specWarnChargedStomp					= mod:NewSpecialWarningRun(425149, "Melee", 363533, nil, 4, 2) --Заряженная поступь (Мощный взрыв)
local specWarnChargedStomp2					= mod:NewSpecialWarningDodge(425149, "-Melee", 363533, nil, 2, 2) --Заряженная поступь (Мощный взрыв)
local specWarnFeatherBomb					= mod:NewSpecialWarningDodge(428765, nil, nil, DBM_COMMON_L.BOMBING, 2, 2) --Перьевая бомба (Обстрел)
local specWarnTranquility					= mod:NewSpecialWarningInterrupt(425995, "HasInterrupt", nil, nil, 1, 2) --Спокойствие
local specWarnBlazingPulse					= mod:NewSpecialWarningInterrupt(425381, "HasInterrupt", nil, nil, 1, 2) --Пламенный импульс

local timerLumberingSlamCD					= mod:NewCDNPTimer(15, 429180, DBM_COMMON_L.FRONTAL, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON)
local timerChargedStompCD					= mod:NewCDNPTimer(14.6, 425149, 363533, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON) --Заряженная поступь (Мощный взрыв) 29.2
local timerFeatherBombCD					= mod:NewNextTimer(22.9, 428765, DBM_COMMON_L.BOMBING, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON) --Перьевая бомба (Обстрел) CD for it starting after RP starts
local timerFeatherBomb						= mod:NewCastTimer(6, 428765, DBM_COMMON_L.BOMBING, nil, nil, 5, nil, DBM_COMMON_L.DEADLY_ICON) --Перьевая бомба (Обстрел) How long it's active and when not to come up

local yellDreamWalk							= mod:NewYell(428077, nil, nil, nil, "YELL") --Хождение во сне
local yellDreamWalkFades					= mod:NewShortFadesYell(428077, nil, nil, nil, "YELL") --Хождение во сне
local yellShadowflameBomb					= mod:NewShortYell(425300, 174716, nil, nil, "YELL") --Бомба пламени Тьмы (Бомба)
local yellShadowflameBombFades				= mod:NewShortFadesYell(425300, nil, nil, nil, "YELL") --Бомба пламени Тьмы (Бомба)
local yellInfernoHeart						= mod:NewShortYell(425388, nil, nil, nil, "YELL") --Сердце Преисподней
local yellInfernoHeartFades					= mod:NewShortFadesYell(425388, nil, nil, nil, "YELL") --Сердце Преисподней

--local playerName = UnitName("player")

--Antispam IDs for this mod: 1 run away, 2 dodge, 3 dispel, 4 incoming damage, 5 you/role, 6 misc
function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 425062 and self:AntiSpam(5, 1) then
		warnShadowchargedSlam:Show()
	elseif spellId == 425995 and self:CheckInterruptFilter(args.sourceGUID, false, true) then
		specWarnTranquility:Show(args.sourceName)
		specWarnTranquility:Play("kickcast")
	elseif spellId == 425149 then
		timerChargedStompCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, "ChargedStomp") then
			if self:IsMelee() then
				specWarnChargedStomp:Show()
				specWarnChargedStomp:Play("justrun")
			else
				specWarnChargedStomp2:Show()
				specWarnChargedStomp2:Play("watchstep")
			end
		end
	elseif spellId == 429180 then
		if self:AntiSpam(4, 5) then
			specWarnLumberingSlam:Show()
			specWarnLumberingSlam:Play("shockwave")
		end
	elseif spellId == 428023 then
		if self:AntiSpam(4, 5) then
			specWarnDreamsWrath:Show()
			specWarnDreamsWrath:Play("shockwave")
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 429180 then
		timerLumberingSlamCD:Start(nil, args.sourceGUID)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 428765 then
		specWarnFeatherBomb:Show()
		specWarnFeatherBomb:Play("watchstep")
		timerFeatherBomb:Start()
	elseif spellId == 425300 then
		warnShadowflameBomb:CombinedShow(0.5, args.destName)
		if args:IsPlayer() then
			specWarnShadowflameBomb:Show()
			specWarnShadowflameBomb:Play("runout")
			yellShadowflameBomb:Yell()
			yellShadowflameBombFades:Countdown(spellId)
		end
	elseif spellId == 425388 then
		warnInfernoHeart:CombinedShow(0.5, args.destName)
		if args:IsPlayer() then
			specWarnInfernoHeart:Show()
			specWarnInfernoHeart:Play("runout")
			yellInfernoHeart:Yell()
			yellInfernoHeartFades:Countdown(spellId)
		elseif self:CheckDispelFilter("curse") then
			specWarnInfernoHeartDispel:Schedule(2, args.destName)
			specWarnInfernoHeartDispel:ScheduleVoice(2, "helpdispel")
		end
	elseif spellId == 425381 and self:CheckInterruptFilter(args.sourceGUID, false, true) then
		specWarnBlazingPulse:Show(args.destName)
		specWarnBlazingPulse:Play("kickcast")
	elseif spellId == 428077 and args:IsDestTypePlayer() then
		warnDreamWalk:CombinedShow(0.5, args.destName)
		if args:IsPlayer() then
			yellDreamWalk:Yell()
			yellDreamWalkFades:Countdown(spellId)
		elseif self:CheckDispelFilter("magic") then
			specWarnDreamWalk:CombinedShow(0.5, args.destName)
			specWarnDreamWalk:Play("helpdispel")
		end
	end
end
--mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 428765 then
		timerFeatherBomb:Stop()
	elseif spellId == 425300 then
		if args:IsPlayer() then
			yellShadowflameBombFades:Cancel()
		end
	elseif spellId == 425388 then
		if args:IsPlayer() then
			yellInfernoHeartFades:Cancel()
		end
	elseif spellId == 428077 then
		if args:IsPlayer() then
			yellDreamWalkFades:Cancel()
		end
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 210172 then --Закали-исполин
		timerChargedStompCD:Stop(args.destGUID)
	elseif cid == 214075 or cid == 210518 then --Хранитель круговорота
		timerLumberingSlamCD:Stop(args.destGUID)
	end
end

--"<36.78 22:58:03> [CHAT_MSG_MONSTER_YELL] You again. A pity I do not have time to eradicate you myself.#Fyrakk###Omegal##0#0##0#3575#nil#0#false#false#false#false", -- [13]
--"<59.69 22:58:26> [CLEU] SPELL_CAST_SUCCESS#Creature-0-3781-2549-28739-209090-000004F6AC#Tindral Sageswift(100.0%-0.0%)##nil#428765#Feather Bomb#nil#nil", -- [35]
--"<59.69 22:58:26> [CLEU] SPELL_AURA_APPLIED#Creature-0-3781-2549-28739-209090-000004F6AC#Tindral Sageswift#Creature-0-3781-2549-28739-209090-000004F6AC#Tindral Sageswift#428765#Feather Bomb#BUFF#nil", -- [33]
--"<65.75 22:58:32> [CLEU] SPELL_AURA_REMOVED#Creature-0-3781-2549-28739-209090-000004F6AC#Tindral Sageswift#Creature-0-3781-2549-28739-209090-000004F6AC#Tindral Sageswift#428765#Feather Bomb#BUFF#nil", -- [44]
function mod:CHAT_MSG_MONSTER_YELL(msg)
	if (msg == L.FyrakkRP or msg:find(L.FyrakkRP)) then
		self:SendSync("DontDie")
	end
end

function mod:OnSync(event, arg)
	if event == "DontDie" and self:AntiSpam(10, 3) then
		timerFeatherBombCD:Start(22.9)
	end
end
