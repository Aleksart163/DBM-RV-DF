# <DBM Mod> Raids (DF)

## [10.2.13](https://github.com/DeadlyBossMods/DBM-Retail/tree/10.2.13) (2023-12-27)
[Full Changelog](https://github.com/DeadlyBossMods/DBM-Retail/compare/10.2.12...10.2.13) [Previous Releases](https://github.com/DeadlyBossMods/DBM-Retail/releases)

- Prep new tag  
- fix regression that caused all initial weapon timers to be 0 (ie never start) after a recent code change  
- update version check  
- also add debug  
- code cleanup and even add failsafe code that for some reason the api for M+ season fails, the fallback is always the current live season  
- Fix another private aura that got missed in spell key changes  
- Fix missed spell key cyange with ashen devestation private aura option  
- slight size tweak  
- fix another misleading voice on fyrakk  
- Support private aura icons on spells that don't have icons as well (so far there are 0 private auras like that, but just in case)  
- Fix a line that got accidentally deleted  
- Fix private aura icons not showing if first event registered wasn't the private aura sound  
- that texture is not compatible with WoW, so just use a generic stealth icon that's really hard to see in GUI for now  
- few fixes to make that alpha stable, still gotta fix icon rendering  
- Begin work on private aura icons in GUI  
- Fix another bug that could cuase affix mod events to unregister and stay unregistered  
- Revert \"Add UI option to select chat frame for DBM messages (#349)\" This reverts commit 63814e1ecc9f9c67e2bc14f247c1e0937873fc20.  
- Update commonlocal.tw.lua (#347)  
- Update commonlocal.ru.lua (#348)  
- Add UI option to select chat frame for DBM messages (#349)  
- Update DBM-Affixes.toc (#972)  
- Update DBM-Affixes.toc (#971)  
- Update DBM-Affixes.toc (zhTW) (#970)  
- Update koKR (Retail) (#969)  
- Allow a mod to load without a sub tab if subtab ID is 0  
- Missed a rename  
- Affixes Update:  
     - Rework affixes module to be dungeon only (Shadowlands fated affixes mod is being relocated to Shadowlands Raids module)  
     - Only load in season 3 dungeons instead of season 2 and 3  
     - Fix a possible race condition that sometimes caused affix timers/alerts not to show in M+ Dungeons  
- Sync common locales  
- Add feather bomb bomb to trash mod which includes  
     - Timer for the Fyrakk RP/activation of feather bomb  
     - Timer for Feather Bomb channel starting/ending  
     - Alert when Feather Bomb starts.  
    TL/DR, don't get trolled by Tindral  
- item checks on nymue just don't work, period, it's not blocked anymore, but it never returns anything so go back to antispam throttle  
- bump alpha  
