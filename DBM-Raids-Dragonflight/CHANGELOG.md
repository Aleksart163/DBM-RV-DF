# <DBM Mod> Raids (DF)

## [10.2.28](https://github.com/DeadlyBossMods/DBM-Retail/tree/10.2.28) (2024-03-05)
[Full Changelog](https://github.com/DeadlyBossMods/DBM-Retail/compare/10.2.27...10.2.28) [Previous Releases](https://github.com/DeadlyBossMods/DBM-Retail/releases)

- Bump versions for new tags  
- Add LuaLS checker workflow (#999)  
- Fix LuaLS warnings (#1000)  
- Fix accessing Enum.SeasonID if it doesn't exist (#452)  
- cleanup  
- Fix inference of locale table (#451) This exposed a few minor bugs in locales, most are likely in effectively unused code. But the raid lead override notification message not working was a real bug :)  
- Fix some locale bugs (#1001)  
- Merge IsSeasonal with IsSeasonOfDiscovery (#450) The new arg is optional and the behavior without it matches the old behavior. The delayed loading/caching is not longer necessary.  
- Add overload annotations for warning constructors (#449) But unlike for the timer constructors I couldn't be bothered to reverse- engineer the exact types of these parameters. This is just to make auto- complete work better.  
- Add DBM:IsSeasonOfDiscovery() (#448)  
- Don't override customized timer option descriptions with auto-generated onse (#447)  
- Update localization.tw.lua (#444)  
- Fix LuaLS warnings (#446) Only one real bug though: Unknown vs. UNKNOWN  
- Fix bad count on counitl on non mythic difficulties  
    Fix bad object type on cast on nymue  
- Update koKR (Retail) (#997)  
- Update localization.ru.lua (#995)  
- Update commonlocal.br.lua (#442)  
- Update localization.br.lua (#438)  
- Update localization.es.lua (#441)  
- Update localization.es.lua (#439)  
- Advertise DBM-PvP in Stranglethorn (#443)  
- update constants  
- tweak wipe stuff  
- Improve checkWipe function to more accurately honor SetWipeTime defined in many modules over the years to require a more strict \"must be out of combat this long for it to be a wipe\"  
- Detect earlier p1 pushes better on Sarkareth due to massive overgearing of fight and cancel timer sequences earlier (and show updated P1 ends timer)  
- Locale syncs (cdcombo, nextcombo)  
- Update commonlocal.es.lua (#440)  
- Update commonlocal.fr.lua (#436)  
- Update commonlocal.br.lua (#437)  
- Update localization.fr.lua (#435)  
- Update commonlocal.es.lua (#434)  
- bump alpha  
