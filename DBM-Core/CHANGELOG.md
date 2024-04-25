# <DBM RV Mod> Raids (DF)

## [10.2.36](https://github.com/Aleksart163/DBM-RV-DF) (2024-04-26)
[Full Changelog](https://github.com/DeadlyBossMods/DeadlyBossMods/compare/10.2.35...10.2.36) [Previous Releases](https://github.com/DeadlyBossMods/DeadlyBossMods/releases)

- Prep tag  
- update M+ loading conditions to remove season 3 dungeons and add war within dungeons  
- Define WOW\_PROJECT\_CATACLYSM\_CLASSIC in luarc.json as well (#1050)  
- Use LuaLS 3.8.3 in ci (#1051)  
- Update zhCN (#1049)  
- forgot the other object  
- Fix a bug where firestorm and swirls used same timer object entire tier. :\ Kinda wish someone had reported this sooner than last day of tier. Think the timers were always right still, just displayed same spell name and made it harder to tell firestorm pools from swirls. At least it'll be fixed for Season 4 week 3 where names are distinct now as intended. Silver lining, our new LuaLS tooling caught the error instantly on open too so in future accidental double object usages won't happen.  
- Fix bad luaLS diagnostic for NewComboYell object  
- Fix bug causing cross realm pull timers not to work in new code  
- luacheck  
- update cata checks  
- Special warning sounds: make first parameter optional  
    I know that announce:Play() has the same problem but that's fixed in my  
    other PR and I don't want these to conflict.  
- Fix self vs. bossModPrototype  
- Remove indirections for TargetScanning and DevTools (#1042)  
- Update luarc.json (#1043)  
- Luals updates v2 (#1041)  
- Be quiet for now  
- Fix real errors, dunno about the others, that probably needs class definition fixes  
- Push some more war within fixes  
- Revert "Luals updates (#1040)"  
- Fix a bug  
- Luals updates (#1040)  
- Add enum for sound files available in voice packs (#1039)  
- fix potential lua error if options table not loaded yet  
- Fix luacheck  
- War within Fixes  
- koKR locale for warwithin prep (#1036)  
- Fix fallback logic in args:IsPlayer()/IsPlayerSource() (#1037)  
- Upd .toc files and add RU locales (#1035)  
- Push warwithin prep  
