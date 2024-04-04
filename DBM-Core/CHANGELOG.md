# <DBM RV Mod> Raids (DF)

## [10.2.32](https://github.com/Aleksart163/DBM-RV-DF) (2024-04-02)
[Full Changelog](https://github.com/DeadlyBossMods/DeadlyBossMods/compare/10.2.31...10.2.32) [Previous Releases](https://github.com/DeadlyBossMods/DeadlyBossMods/releases)

- Bump vanilla tocs and version  
- Fix icons in boss health frame with customized names (#1023)  
- Update M+ Affixes module to support Season 4  
- Update core for detecting the new new new id for 20 man raids (because the existing IDs apparently weren't good enough)  
- also fix reason it's being sent in first place  
- fix another place that stores classic sub version to not store it on retail  
- update strings  
- fix typo  
- fix a bug where retail was sending the vanilla classic subversion, subversion should be ignored on retail  
- Core Updates:  
     - Fixed bug where new unified core wasn't sending update available notifications to older versions of DBM pre unified, due to changed prefixes. For a short while, newer DBM will also similcast version info to old comms prefixes for classic until at least next major patch for classic wrath and classic vanilla.  
     - The news message will now show every login instead of only first, until user has loaded an appropriate classic raids module.  
- Fix regression from #1020  
- Add icons to boss health info frame (#1021)  
- Reduce number of locals in DBM-Core (#1020)  
- Update zh-CN (#1019)  
- Update koKR (#1015)  
- Fix news items for br, es and fr  
- Fix IsItemInRange in rangecheck  
- Update localization.tw.lua (#1014)  
- bump alpha  
