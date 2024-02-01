# <DBM Mod> Raids (DF)

## [10.2.20](https://github.com/DeadlyBossMods/DBM-Retail/tree/10.2.20) (2024-02-01)
[Full Changelog](https://github.com/DeadlyBossMods/DBM-Retail/compare/10.2.19...10.2.20) [Previous Releases](https://github.com/DeadlyBossMods/DBM-Retail/releases)

- prep new retail tag  
- change flamebound and shadowbound to non private aura alerts  
- Fix garrison logic in refactor. In instance should ignore garrisons, those should only be touched by \"anywhere\" power user option  
- Auto name mods for raids dungeon and world bosses.  
- fix encoding/renderring error  
- More LuaLS annotations (#403)  
- Locale syncs: All core localizations finished.  
- bump alpha  
- bump classic era version  
- note  
- Update localization.es.lua (#402)  
- Locale syncs: Core br.  
- Locale syncs; Finished commonlocal  
- remove unused spellids  
- Update koKR (#400)  
- Fix French translation of UPDATEREMINDER\_DISABLE (#401)  
- another minor fix  
- Make sure color type is always set to 0 if nil  
- Slight performance tweak to last.  
- Allow CINEMATIC\_START to block...well..blocking when outside of intended scope  
- disable UI for HideMovieNonInstanceAnywhere . scope it to just power users to enable via script only.  
- Update localization.tw.lua (Core) (#397)  
- Update localization.ru.lua (#398)  
- Update commonlocal.ru.lua (#399)  
- Update localization.ru.lua (#985)  
- CC spelldata update  
- further throttle full roster updating to reduce cpu waste when roster is constant changing during forming (and reduce debug too so icon elect debug doesn't spam excessively). In contrast though, removed throttle in combat to avoid those niche race conditions in LFR where someone drops raid mid fight and the roster data is out of date when accessing it due to the old 1.5 delay.  
- Update commonlocal.tw.lua (Core) (#396)  
- Update localization.tw.lua (GUI) (#395)  
-  - Fixed a bug where taunt alert on smolderon could get you killed because it would tell you to taunt boss for second brand if other tank got overheat, even though you had first brand due to other tank messing up rotation and not tanking boss on first brand even though you had overheat (thus causing you to have overheat AND brand 1. In english, if you had first brand, it won't tell you to taunt second one even if the tank has overheat, cause it is in fact their fault for not doing first brand correctly.  
     - Also lowered taunt threshold on tindral to swap boss more often.  
- tweak option defaults  
- Rework the blizzard feature block panel - New options to auto disable Ambiance and Music sound channels during boss fights - Much cleaner and clearer options for cut scene blocking - Fixed bug where sound effects could get turned on even if they weren't on at combat start, if music had option to disable SFX enabled. - Organized options to better sub categories - The option to hide objectives tracker is now hidden on retail, since that feature is exclusive to classic due to UI taint without a full rework of feature - Removed unused texts - NOTE: All options will need updated translations Also updated Raid Leader Options to hide all the NYI stuff  
- bump alpha  
