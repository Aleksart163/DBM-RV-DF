local mod	= DBM:NewMod("CoSTrash", "DBM-Party-Legion", 7)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20231026112110")
--mod:SetModelID(47785)
mod:SetOOCBWComms()
mod:SetMinSyncRevision(20221228000000)
mod:SetZone(1571)

mod.isTrashMod = true

--LW solution, unregister/reregister other addons/WA frames from GOSSIP_SHOW
--This is to prevent things like https://wago.io/M+Timer/114 from breaking clue helper do to advancing
--dialog before we get a chance to read gossipID
local frames = {GetFramesRegisteredForEvent("GOSSIP_SHOW")}
for i = 1, #frames do
	frames[i]:UnregisterEvent("GOSSIP_SHOW")
end
mod:RegisterEvents(
	"SPELL_CAST_START 209027 212031 209485 209410 209413 211470 211464 209404 209495 225100 211299 209378 397892 397897 207979 212784 207980 212773 210261 209033 211473 214697 214692 373364",
	"SPELL_AURA_APPLIED 209033 209512 397907 373552 209413",
	"SPELL_AURA_REMOVED 397907",
	"UNIT_DIED",
	"CHAT_MSG_MONSTER_SAY",
	"GOSSIP_SHOW",
	"UPDATE_MOUSEOVER_UNIT"
)
for i = 1, #frames do
	frames[i]:RegisterEvent("GOSSIP_SHOW")
end

--TODO, at least 1-2 more GTFOs I forgot names of
--TODO, target scan https://www.wowhead.com/beta/spell=397897/crushing-leap ?
--[[
(ability.id = 209033 or ability.id = 209027 or ability.id = 212031 or ability.id = 207979 or ability.id = 209485 or ability.id = 209410
 or ability.id = 209413 or ability.id = 211470 or ability.id = 225100 or ability.id = 211299 or ability.id = 207980 or ability.id = 212773
 or ability.id = 211464 or ability.id = 209404 or ability.id = 209495 or ability.id = 209378 or ability.id = 397892 or ability.id = 397897
 or ability.id = 212784 or ability.id = 211473) and type = "begincast"
--]]

local warnPickingUp					= mod:NewTargetNoFilterAnnounce(214697, 1) --Поднять ключ
local warnSpyFound					= mod:NewAnnounce("pSpyFound", 1, 248732) --Шпион обнаружен
local warnAvailableItems			= mod:NewAnnounce("warnAvailableItems", 1)
local warnImpendingDoom				= mod:NewTargetNoFilterAnnounce(397907, 2) --Надвигающийся рок
local warnSoundAlarm				= mod:NewCastAnnounce(210261, 4) --Сигнал тревоги
local warnSubdue					= mod:NewCastAnnounce(212773, 3) --Подчинение
local warnCrushingLeap				= mod:NewCastAnnounce(397897, 3) --Тяжелый прыжок
local warnEyeStorm					= mod:NewCastAnnounce(212784, 4) --Буря глаз
local warnShadowSlash				= mod:NewCastAnnounce(211473, 4, nil, nil, "Tank|Healer") --Темное рассечение
local warnHypnosisBat				= mod:NewTargetNoFilterAnnounce(373552, 3) --Гипнонетопырь
local warnFelDetonation				= mod:NewCastAnnounce(211464, 4) --Взрыв Скверны
local warnShadowBoltVolley			= mod:NewCastAnnounce(214692, 4) --Залп стрел Тьмы
local warnSuppress					= mod:NewTargetNoFilterAnnounce(209413, 4) --Подавление

local specWarnHypnosisBat			= mod:NewSpecialWarningYou(373552, nil, nil, nil, 1, 2) --Гипнонетопырь
local specWarnVampiricClaws			= mod:NewSpecialWarningDefensive(373364, nil, nil, nil, 3, 4) --Когти вампира
local specWarnShadowBoltVolley		= mod:NewSpecialWarningMoveTo(214692, "-Tank", nil, nil, 2, 2) --Залп стрел Тьмы
local specWarnFortificationDispel	= mod:NewSpecialWarningDispel(209033, "MagicDispeller", nil, nil, 1, 2)
local specWarnQuellingStrike		= mod:NewSpecialWarningDodge(209027, "Melee", nil, 2, 1, 2)
local specWarnChargedBlast			= mod:NewSpecialWarningDodge(212031, "Tank", nil, nil, 1, 2)
local specWarnChargedSmash			= mod:NewSpecialWarningDodge(209495, "Melee", nil, 2, 1, 2)
local specWarnShockwave				= mod:NewSpecialWarningDodge(207979, nil, nil, nil, 2, 2)
local specWarnSubdue				= mod:NewSpecialWarningInterrupt(212773, "HasInterrupt", nil, nil, 1, 2) --Подчинение
local specWarnFortification			= mod:NewSpecialWarningInterrupt(209033, false, nil, nil, 1, 2)--Opt in. There are still higher prio interrupts in most packs with guards and this can be dispelled after the fact
local specWarnDrainMagic			= mod:NewSpecialWarningInterrupt(209485, "HasInterrupt", nil, nil, 1, 2)
local specWarnNightfallOrb			= mod:NewSpecialWarningInterrupt(209410, "HasInterrupt", nil, nil, 1, 2)
local specWarnSuppress				= mod:NewSpecialWarningInterrupt(209413, "HasInterrupt", nil, nil, 1, 2)
local specWarnBewitch				= mod:NewSpecialWarningInterrupt(211470, "HasInterrupt", nil, nil, 1, 2) --Околдовывание
local specWarnChargingStation		= mod:NewSpecialWarningInterrupt(225100, "HasInterrupt", nil, nil, 1, 2) --Зарядная станция
local specWarnSearingGlare			= mod:NewSpecialWarningInterrupt(211299, "HasInterrupt", nil, nil, 1, 2)
local specWarnDisintegrationBeam	= mod:NewSpecialWarningInterrupt(207980, "HasInterrupt", nil, nil, 1, 2)
local specWarnFelDetonation			= mod:NewSpecialWarningMoveTo(211464, nil, nil, nil, 2, 13) --Взрыв Скверны
local specWarnSealMagic				= mod:NewSpecialWarningRun(209404, false, nil, 2, 4, 2)
local specWarnWhirlingBlades		= mod:NewSpecialWarningRun(209378, "Melee", nil, nil, 4, 2)
local specWarnScreamofPain			= mod:NewSpecialWarningCast(397892, "SpellCaster", nil, nil, 1, 2) --Крик боли
local specWarnImpendingDoom			= mod:NewSpecialWarningMoveAway(397907, nil, nil, nil, 1, 4) --Надвигающийся рок
local specWarnGTFO					= mod:NewSpecialWarningGTFO(209512, nil, nil, nil, 1, 8)

local timerVampiricClawsCD			= mod:NewCDNPTimer(14, 373364, nil, nil, nil, 3, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.DEADLY_ICON) --Когти вампира
local timerShadowBoltVolleyCD		= mod:NewCDNPTimer(19, 214692, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON, nil, nil, nil, 3, 5) --Залп стрел Тьмы
local timerQuellingStrikeCD			= mod:NewCDNPTimer(10, 209027, nil, "Tank", nil, 3, nil, DBM_COMMON_L.TANK_ICON) --Подавляющий удар
local timerFortificationCD			= mod:NewCDNPTimer(18.1, 209033, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Укрепление
local timerSealMagicCD				= mod:NewCDNPTimer(18.1, 209404, nil, "HasInterrupt", nil, 2) --Подавление магии
local timerChargingStationCD		= mod:NewCDNPTimer(13.3, 225100, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Зарядная станция
local timerSuppressCD				= mod:NewCDNPTimer(16, 209413, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Подавление
local timerSearingGlareCD			= mod:NewCDNPTimer(8.4, 211299, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON)
local timerEyeStormCD				= mod:NewCDNPTimer(20, 212784, nil, nil, nil, 5) --Буря глаз Role color cause it needs a disrupt (stun, knockback) to interrupt.
local timerBewitchCD				= mod:NewCDNPTimer(17, 211470, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Околдовывание
local timerShadowSlashCD			= mod:NewCDNPTimer(18.2, 211473, nil, "Tank|Healer", nil, 5, nil, DBM_COMMON_L.TANK_ICON) --Темное рассечение
local timerFelDetonation			= mod:NewCastTimer(4, 211464, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON, nil, 3, 3) --Взрыв Скверны
local timerFelDetonationCD			= mod:NewCDNPTimer(12, 211464, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON, nil, 3, 3) --Взрыв Скверны
local timerScreamofPain				= mod:NewCastTimer(1.5, 397892, nil, "SpellCaster", nil, 7, nil, nil, nil, 3, 1.5) --Крик боли
local timerScreamofPainCD			= mod:NewCDNPTimer(14, 397892, nil, "SpellCaster", nil, 2, nil, nil, nil, 3, 3) --Крик боли
local timerWhirlingBladesCD			= mod:NewCDNPTimer(18.2, 209378, nil, "Melee", nil, 2, nil, DBM_COMMON_L.DEADLY_ICON) --Крутящиеся клинки
local timerDisintegrationBeamCD		= mod:NewCDNPTimer(6.1, 207980, nil, "HasInterrupt", nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON) --Луч дезинтеграции
local timerShockwaveCD				= mod:NewCDNPTimer(8.4, 207979, nil, nil, nil, 3) --Ударная волна
local timerCrushingLeapCD			= mod:NewCDNPTimer(16.9, 397897, nil, nil, nil, 3) --Тяжелый прыжок

local yellSuppress					= mod:NewYell(209413, nil, nil, nil, "YELL") --Подавление
local yellImpendingDoom				= mod:NewYell(397907, nil, nil, nil, "YELL") --Надвигающийся рок
local yellImpendingDoomFades		= mod:NewShortFadesYell(397907, nil, nil, nil, "YELL") --Надвигающийся рок

mod:AddBoolOption("AGBoat", true)
mod:AddBoolOption("AGDisguise", true)
mod:AddBoolOption("AGBuffs", true)
mod:AddBoolOption("SpyHelper", true)
mod:AddBoolOption("SendToChat2", true)
mod:AddBoolOption("SpyHelperClose2", false)

--Antispam IDs for this mod: 1 run away, 2 dodge, 3 dispel, 4 incoming damage, 5 you/role, 6 generalized, 7 GTFO

function mod:VampiricClawsTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnVampiricClaws:Show()
		specWarnVampiricClaws:Play("defensive")
	end
end

function mod:SPELL_CAST_START(args)
	if not self.Options.Enabled then return end
	if not self:IsValidWarning(args.sourceGUID) then return end
	local spellId = args.spellId
	if spellId == 209027 then
		timerQuellingStrikeCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, 2) then
			specWarnQuellingStrike:Show()
			specWarnQuellingStrike:Play("shockwave")
		end
	elseif spellId == 212031 and self:AntiSpam(3, 2) then
		specWarnChargedBlast:Show()
		specWarnChargedBlast:Play("shockwave")
	elseif spellId == 207979 then
		timerShockwaveCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, 2) then
			specWarnShockwave:Show()
			specWarnShockwave:Play("shockwave")
		end
	elseif spellId == 209033 then
		timerFortificationCD:Start(nil, args.sourceGUID)
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnFortification:Show(args.sourceName)
			specWarnFortification:Play("kickcast")
		end
	elseif spellId == 209485 and self:CheckInterruptFilter(args.sourceGUID, false, true) then
		specWarnDrainMagic:Show(args.sourceName)
		specWarnDrainMagic:Play("kickcast")
	elseif spellId == 209410 and self:CheckInterruptFilter(args.sourceGUID, false, true) then
		specWarnNightfallOrb:Show(args.sourceName)
		specWarnNightfallOrb:Play("kickcast")
	elseif spellId == 209413 then
		timerSuppressCD:Start(nil, args.sourceGUID)
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnSuppress:Show(args.sourceName)
			specWarnSuppress:Play("kickcast")
		end
	elseif spellId == 211470 then
		timerBewitchCD:Start(nil, args.sourceGUID)
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnBewitch:Show(args.sourceName)
			specWarnBewitch:Play("kickcast")
		end
	elseif spellId == 225100 then
		timerChargingStationCD:Start(nil, args.sourceGUID)
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnChargingStation:Show(args.sourceName)
			specWarnChargingStation:Play("kickcast")
		end
	elseif spellId == 211299 then
		timerSearingGlareCD:Start(nil, args.sourceGUID)
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnSearingGlare:Show(args.sourceName)
			specWarnSearingGlare:Play("kickcast")
		end
	elseif spellId == 207980 then
		timerDisintegrationBeamCD:Start(nil, args.sourceGUID)
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnDisintegrationBeam:Show(args.sourceName)
			specWarnDisintegrationBeam:Play("kickcast")
		end
	elseif spellId == 212773 then
		if self.Options.SpecWarn212773interrupt and self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnSubdue:Show(args.sourceName)
			specWarnSubdue:Play("kickcast")
		elseif self:AntiSpam(3, 5) then
			warnSubdue:Show()
		end
	elseif spellId == 211464 then
		timerFelDetonationCD:Start(nil, args.sourceGUID)
		timerFelDetonation:Start()
		if self:AntiSpam(3, 4) then
			warnFelDetonation:Show()
			specWarnFelDetonation:Show(DBM_COMMON_L.BREAK_LOS)
			specWarnFelDetonation:Play("breaklos")
		end
	elseif spellId == 209404 then
		timerSealMagicCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, 5) then
			specWarnSealMagic:Show()
			specWarnSealMagic:Play("runout")
		end
	elseif spellId == 209495 then
		specWarnChargedSmash:Show()
		specWarnChargedSmash:Play("watchstep")
	elseif spellId == 209378 then
		timerWhirlingBladesCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, 1) then
			specWarnWhirlingBlades:Show()
			specWarnWhirlingBlades:Play("runout")
		end
	elseif spellId == 397892 then
		specWarnScreamofPain:Show()
		specWarnScreamofPain:Play("stopcast")
		timerScreamofPainCD:Start(nil, args.sourceGUID)
		timerScreamofPain:Start()
	elseif spellId == 397897 then
		timerCrushingLeapCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, 6) then
			warnCrushingLeap:Show()
		end
	elseif spellId == 212784 then
		timerEyeStormCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, 6) then
			warnEyeStorm:Show()
		end
	elseif spellId == 210261 then--No throttle
		warnSoundAlarm:Show()
	elseif spellId == 211473 then
		timerShadowSlashCD:Start(nil, args.sourceGUID)
		if self:AntiSpam(3, 5) then
			warnShadowSlash:Show()
		end
	elseif spellId == 214697 then --Поднять ключ
		warnPickingUp:Show(args.sourceName)
	elseif spellId == 214692 then --Залп стрел Тьмы
		timerShadowBoltVolleyCD:Start(nil, args.sourceGUID)
		specWarnShadowBoltVolley:Show(DBM_COMMON_L.BREAK_LOS)
		specWarnShadowBoltVolley:Play("breaklos")
	elseif spellId == 373364 then --Когти вампира
		self:BossTargetScanner(args.sourceGUID, "VampiricClawsTarget", 0.1, 2)
		timerVampiricClawsCD:Start(nil, args.sourceGUID)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 209033 and not args:IsDestTypePlayer() and self:CheckDispelFilter("magic") then
		specWarnFortificationDispel:Show(args.destName)
		specWarnFortificationDispel:Play("dispelnow")
	elseif spellId == 209512 and args:IsPlayer() and self:AntiSpam(3, 7) then
		specWarnGTFO:Show(args.spellName)
		specWarnGTFO:Play("watchfeet")
	elseif spellId == 397907 then
		warnImpendingDoom:CombinedShow(0.5, args.destName)
		if args:IsPlayer() then
			specWarnImpendingDoom:Show()
			specWarnImpendingDoom:Play("scatter")
			yellImpendingDoom:Yell()
			yellImpendingDoomFades:Countdown(spellId)
		end
	elseif spellId == 373552 then --Гипнонетопырь
		if args:IsPlayer() then
			specWarnHypnosisBat:Show()
			specWarnHypnosisBat:Play("targetyou")
		else
			warnHypnosisBat:Show(args.destName)
		end
	elseif spellId == 209413 then --Подавление
		if args:IsPlayer() then
			yellSuppress:Yell()
		else
			warnSuppress:CombinedShow(0.5, args.destName)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 397907 and args:IsPlayer() then
		yellImpendingDoomFades:Cancel()
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 104246 then--Duskwatch Guard
		timerQuellingStrikeCD:Stop(args.destGUID)
		timerFortificationCD:Stop(args.destGUID)
	elseif cid == 104247 then--Duskwatch Arcanist
		timerSealMagicCD:Stop(args.destGUID)
	elseif cid == 104270 then--Guardian Construct
		timerChargingStationCD:Stop(args.destGUID)
		timerSuppressCD:Stop(args.destGUID)
	elseif cid == 105715 then--Watchful Inquisitor
		timerSearingGlareCD:Stop(args.destGUID)
		timerEyeStormCD:Stop(args.destGUID)
	elseif cid == 104300 then--Shadow Mistress
		timerBewitchCD:Stop(args.destGUID)
		timerShadowSlashCD:Stop(args.destGUID)
	elseif cid == 104278 then--Felbound Enforcer
		timerFelDetonationCD:Stop(args.destGUID)
		timerFelDetonation:Stop()
	elseif cid == 104275 then--Imacu'tya
		timerScreamofPainCD:Stop(args.destGUID)
		timerWhirlingBladesCD:Stop(args.destGUID)
		timerScreamofPain:Stop()
	elseif cid == 104274 then--Baalgar the Watchful
		timerDisintegrationBeamCD:Stop(args.destGUID)
	elseif cid == 104273 then--Jazshariu
		timerShockwaveCD:Stop(args.destGUID)
		timerCrushingLeapCD:Stop(args.destGUID)
	elseif cid == 108151 or cid == 107435 then --Герент Зловещий
		timerShadowBoltVolleyCD:Stop(args.destGUID)
		timerVampiricClawsCD:Stop(args.destGUID)
	end
end

do
	--Court notable NPC stuff
	--Old professions icon Ids/skill levels maintained in case classic ever gets up to legion
	--Parts of code modified from littlewigs with permission for max intermod operability and no wheel re-inventing
	local professionCache = {}

	local notableBuffNPCs = {
		--Buffs
		[105160] = { -- Сфера Скверны
			["name"] = DBM:GetSpellInfo(208275),
			["buffid"] = 211081,
			["class"] = {
				["PALADIN"] = true,
				["PRIEST"] = true,
				["WARLOCK"] = true,
				["DEMONHUNTER"] = true
			}
		},
		[105249] = { -- Закуски ночной тени
			["name"] = L.Nightshade,
			["buffid"] = 211102,
			["races"] = {
				["Pandaren"] = true
			},
			["professionicons"] = {
--				[133971] = 800,--Cooking (old)
				[4620671] = 1,--Cooking (DF)
--				[136246] = 800,--Herbalist (old)
				[4620675] = 1--Herbalist (DF)
			}
		},
		[105340] = { -- Теневой цветок
			["name"] = L.UmbralBloom,
			["buffid"] = 211110,
			["class"] = {
				["DRUID"] = true
			},
			["professionicons"] = {
--				[133971] = 800,--Cooking (old)
				[4620671] = 1,--Cooking (DF)
--				[136246] = 800,--Herbalist (old)
				[4620675] = 1--Herbalist (DF)
			}
		},
		[105831] = { -- Инфернальный фолиант
			["name"] = L.InfernalTome,
			["buffid"] = 211080,
			["class"] = {
				["PALADIN"] = true,
				["PRIEST"] = true,
				["DEMONHUNTER"] = true
			}
		},
		[106024] = { -- Магический светильник
			["name"] = L.MagicalLantern,
			["buffid"] = 211093,
			["class"] = {
				["MAGE"] = true
			},
			["races"] = {
				["BloodElf"] = true,
				["NightElf"] = true,
				["Dracthyr"] = true
			},
			["professionicons"] = {
--				[136244] = 800,--Enchanting (Old)
				[4620672] = 1--Enchanting (New)
			}
		},
		[106108] = { -- Отвар из звездной розы
			["name"] = L.StarlightRoseBrew,
			["buffid"] = 211071,
			["class"] = {
				["DEATHKNIGHT"] = true,
				["MONK"] = true
			},
		},
		[106110] = { -- Промокший свиток
			["name"] = L.WaterloggedScroll,
			["buffid"] = 211084,
			["class"] = {
				["SHAMAN"] = true
			},
			["professionicons"] = {
--				[134366] = 800,--Skinning (Old)
				[4620680] = 1,--Skinning (New)
--				[237171] = 800,--Inscription (Old)
				[4620676] = 1--Inscription (New)
			}
		},
		--Debuffs
		[105117] = { -- Настой священной ночи
			["name"] = DBM:GetSpellInfo(207815),
			["class"] = {
				["ROGUE"] = true
			},
			["professionicons"] = {
--				[136240] = 800, -- Alchemy (old)
				[4620669] = 1 -- Alchemy (DF)
			}
		},
		[105157] = {-- Проводник магической энергии
			["name"] = DBM:GetSpellInfo(210466),
			["races"] = {
				["Gnome"] = true,
				["Goblin"] = true
			},
			["professionicons"] = {
--				[136243] = 800, -- Engineering (old)
				[4620673] = 1 -- Engineering (DF)
			}
		}
	}

	local notableNonBuffNPCs = {
		--Alerts
		[105215] = { -- Выброшенный хлам
			["name"] = L.DiscardedJunk,
			["class"] = {
				["HUNTER"] = true
			},
			["professionicons"] = {
--				[136241] = 800, -- Blacksmithing (old)
				[4620670] = 1 -- Blacksmithing (DF)
			},
		},
		[106018] = { -- Рыночные товары
			["name"] = L.BazaarGoods,
			["class"] = {
				["WARRIOR"] = true,
				["ROGUE"] = true,
			},
			["professionicons"] = {
--				[136247] = 800, -- Leatherworking (old)
				[4620678] = 1 -- Leatherworking (DF)
			}
		},
		[106112] = { -- Раненый ночнорожденный
			["name"] = L.WoundedNightborneCivilian,
			["professionicons"] = {
--				[136249] = 800, -- Tailoring (old)
				[4620681] = 1 -- Tailoring (DF)
			},
			["roles"] = {
				["Healer"] = true,
			}
		},
		[106113] = { -- Статуя ночнорожденного в натуральную величину
			["name"] = L.LifesizedNightborneStatue,
			["professionicons"] = {
--				[134708] = 800, -- Mining (old)
				[4620679] = 1, -- Mining (DF)
--				[134071] = 800, -- JC (old)
				[4620677] = 1 -- JC (DF)
			}
		}
	}

	local raceIcons = {
		["NightElf"] = "|T236449:0|t",
		["Gnome"] = "|T236445:0|t",
		["Goblin"] = "|T632354:0|t",
		["BloodElf"] = "|T236439:0|t",
		["Pandaren"] = "|T626190:0|t",
		["Dracthyr"] = "|T4696175:0|t"
	}

	local function getClassIcon(class)
		return ("|TInterface/Icons/classicon_%s:0|t"):format(strlower(class))
	end

	local function getIconById(id)
		return ("|T%d:0|t"):format(id)
	end

	local roleIcons = {
		["Healer"] = "|T337497:0:0:0:0:64:64:20:39:1:20|t",
	}

	local function alertUsable(self, cid, item)
		self:SendBigWigsSync("itemAvailable", cid)
		local players = {} -- who can use the item
		local icons = {}
		if item.professionicons then
			for profIcon, requiredSkill in pairs(item.professionicons) do
				if professionCache[profIcon] then
					for _,v in pairs(professionCache[profIcon]) do
						if v.skill >= requiredSkill then
							players[v.name] = true
						end
					end
				end
				icons[#icons+1] = getIconById(profIcon)
			end
		end
		if item.races then
			for race, _ in pairs(item.races) do
				for unit in DBM:GetGroupMembers() do
					local _, _, unitRace = UnitRace(unit)
					if unitRace == race then
						players[DBM:GetUnitFullName(unit)] = true
					end
				end
				icons[#icons+1] = raceIcons[race]
			end
		end
		if item.class then
			for class, _ in pairs(item.class) do
				for unit in DBM:GetGroupMembers() do
					local _, unitClass = UnitClass(unit)
					if unitClass == class then
						players[DBM:GetUnitFullName(unit)] = true
					end
				end
				icons[#icons+1] = getClassIcon(class)
			end
		end
		if item.roles then
			for role, _ in pairs(item.roles) do
				for unit in DBM:GetGroupMembers() do
					if UnitGroupRolesAssigned(unit) == role then
						players[DBM:GetUnitFullName(unit)] = true
					end
				end
				icons[#icons+1] = roleIcons[role]
			end
		end

		local message = (L.Available):format(table.concat(icons, ""), item.name)

		if next(players) then
			local list = ""
			for player in pairs(players) do
				if UnitInParty(player) then -- don't announce players from previous groups
					list = list .. ">" .. player .. "<, "
				end
			end
			if list:len() > 0 then
				message = message .. " - ".. L.UsableBy:format(list:sub(0, list:len()-2))
			end
		end
		warnAvailableItems:Show(message)
	end

	local function assessUsable(self, cid, item)
		--Don't alert if buff already active
		if notableBuffNPCs[cid] and notableBuffNPCs[cid].buffid and DBM:UnitBuff("player", notableBuffNPCs[cid].buffid) then return end
		--Don't alert if we alerted within last 5 minutes
		if self:AntiSpam(90, "CoS"..cid) then
			local delayAnnouncement = false
			if item.professionicons then
				if self:AntiSpam(90, "CoSProf") then
					self:SendBigWigsSync("getProfessions")
					delayAnnouncement = true
				end
			end
			if delayAnnouncement then
				self:Schedule(0.5, alertUsable, self, cid, item)
			else
				alertUsable(self, cid, item)
			end
		end
	end

	function mod:UPDATE_MOUSEOVER_UNIT()
		local cid = DBM:GetUnitCreatureId("mouseover")
		local item = notableBuffNPCs[cid] or notableNonBuffNPCs[cid]
		if item then
			assessUsable(self, cid, item)
		end
	end

	--Court Clue Stuff
	local clueTotal = 0
	local hintTranslations = {
		[1] = L.Cape or "cape",
		[2] = L.Nocape or "no cape",
		[3] = L.Pouch or "pouch",
		[4] = L.Potions or "potions",
		[5] = L.LongSleeve or "long sleeves",
		[6] = L.ShortSleeve or "short sleeves",
		[7] = L.Gloves or "gloves",
		[8] = L.NoGloves or "no gloves",
		[9] = L.Male or "male",
		[10] = L.Female or "female",
		[11] = L.LightVest or "light vest",
		[12] = L.DarkVest or "dark vest",
		[13] = L.NoPotions or "no potions",
		[14] = L.Book or "book",
	}
	local hints = {}
	local clueIds = {
		[45674] = 1,--Cape
		[45675] = 2,--No Cape
		[45660] = 3,--Pouch
		[45666] = 4,--Potions
		[45676] = 5,--Long Sleeves
		[45677] = 6,--Short Sleeves
		[45673] = 7,--Gloves
		[45672] = 8,--No Gloves
		[45657] = 9,--Male
		[45658] = 10,--Female
		[45636] = 11,--Light Vest
		[45635] = 12,--Dark Vest
		[45667] = 13,--No Potions
		[45659] = 14--Book
	}

	local function updateInfoFrame()
		local lines = {}
		for hint, _ in pairs(hints) do
			local text = hintTranslations[hint]
			lines[text] = ""
		end
		return lines
	end

	local function callUpdate(clue)
		clueTotal = clueTotal + 1
		DBM.InfoFrame:SetHeader(L.CluesFound:format(clueTotal))
		DBM.InfoFrame:Show(5, "function", updateInfoFrame)
		local text = hintTranslations[clue]
		DBM:AddMsg(L.ClueShort:format(clueTotal, text))
	end

	function mod:ResetGossipState()--/run DBM:GetModByName("CoSTrash"):ResetGossipState()
		table.wipe(hints)
		clueTotal = 0
		DBM.InfoFrame:Hide()
	end

	function mod:CHAT_MSG_MONSTER_SAY(msg, _, _, _, target)
		if msg:find(L.Found) or msg == L.Found then
			self:SendSync("Finished", target)
			if self.Options.SpyHelper and self.Options.SendToChat2 and target == UnitName("player") then
				local text = L.SpyFoundP
				if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
					DBM:Debug("INSTANCE_CHAT (LE_PARTY_CATEGORY_INSTANCE) "..text)
					SendChatMessage("[DBM RV] "..text, "INSTANCE_CHAT")
				elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
					DBM:Debug("PARTY (LE_PARTY_CATEGORY_HOME) "..text)
					SendChatMessage("[DBM RV] "..text, "PARTY")
				elseif IsInRaid() then
					DBM:Debug("RAID "..text)
					SendChatMessage("[DBM RV] "..text, "RAID")
				end
			end
		end
	end

	function mod:GOSSIP_SHOW()
		local cid = DBM:GetUnitCreatureId("npc")
		if self.Options.AGBuffs and notableBuffNPCs[cid] then
			self:SelectGossip(1)
			return
		end
		local gossipOptionID = self:GetGossipID()
		if gossipOptionID then
			if self.Options.AGBoat and gossipOptionID == 45624 then -- Boat
				self:SelectGossip(gossipOptionID)
			elseif self.Options.AGDisguise and gossipOptionID == 45656 then -- Disguise
				self:SelectGossip(gossipOptionID)
			elseif clueIds[gossipOptionID] then -- SpyHelper
				if not self.Options.SpyHelper then return end
				local clue = clueIds[gossipOptionID]
				if not hints[clue] then
					if self.Options.SendToChat2 then
						local text = hintTranslations[clue]
						if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
							SendChatMessage("[DBM RV] "..text, "INSTANCE_CHAT")
						elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
							SendChatMessage("[DBM RV] "..text, "PARTY")
						end
					end
					hints[clue] = true
					self:SendSync("CoS", clue)
					callUpdate(clue)
					--Still required to advance dialog or demon hunters can't use spectral sight
					--We try to delay it by .1 so other mods can still parse gossip ID in theory
					C_Timer.After(0.1, function() self:SelectGossip(gossipOptionID) end)
				end
				if self.Options.SpyHelperClose2 then
					--Delay used so DBM doesn't prevent other mods or WAs from parsing data
					C_Timer.After(0.2, function() C_GossipInfo.CloseGossip() end)
				end
			end
		end
	end

	function mod:OnSync(msg, clue)
		if not self.Options.SpyHelper then return end
		if msg == "CoS" and clue then
			clue = tonumber(clue)
			if clue and not hints[clue] then
				hints[clue] = true
				callUpdate(clue)
			end
		elseif msg == "Finished" then
			warnSpyFound:Show()
			self:ResetGossipState()
			if clue then
				local targetname = DBM:GetUnitFullName(clue) or clue
				DBM:AddMsg(L.SpyFound:format(targetname))
			end
		end
	end
	function mod:OnBWSync(msg, extra, sender)
		if self.Options.SpyHelper and msg == "clue" then
			extra = tonumber(extra)
			if extra and extra > 0 and extra < 15 and not hints[extra] then
				hints[extra] = true
				callUpdate(extra)
			end
		elseif msg == "itemAvailable" and extra then
			extra = tonumber(extra)
			local item = notableBuffNPCs[extra] or notableNonBuffNPCs[extra]
			if item then
				assessUsable(self, extra, item)
			end
		elseif msg == "getProfessions" then
			--Answer BW profession requests using BW comms
			local professions = {}
			for _,id in pairs({GetProfessions()}) do
				local _, icon, skill = GetProfessionInfo(id) -- name is localized, so use icon instead
				professions[icon] = skill
			end
			local profString = ""
			for k,v in pairs(professions) do
				profString = profString .. k .. ":" .. v .. "#"
			end
			self:SendBigWigsSync("professions", profString)
		elseif msg == "professions" and extra then
			--DBM and BW will both just parse the bigiwgs comms for profession data
			for icon, skill in extra:gmatch("(%d+):(%d+)#") do
				icon = tonumber(icon)
				skill = tonumber(skill)
				if not professionCache[icon] then
					professionCache[icon] = {}
				end
				professionCache[icon][#professionCache[icon]+1] = {name=sender, skill=skill}
			end
			self:AntiSpam(90, "CoSProf")
		end
	end
end
