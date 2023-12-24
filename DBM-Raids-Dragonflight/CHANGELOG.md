# <DBM Mod> Raids (DF)

## [10.2.12](https://github.com/DeadlyBossMods/DBM-Retail/tree/10.2.12) (2023-12-22)
[Full Changelog](https://github.com/DeadlyBossMods/DBM-Retail/compare/10.2.11...10.2.12) [Previous Releases](https://github.com/DeadlyBossMods/DBM-Retail/releases)

- prep new retail tag  
- forgot to comment old object out  
- Enable target messages on polymorph private aura since RBW bug still not fixed yet and I think several months is long enough to sit on a known bug before it's fair game, especially when other addons/auras already doing it, which puts DBM in a tough spot of doing it too or getting left behind.  
- Update some spell keys to match recent changes on BW side so weak auras don't break (well besides fact changing them mid tier at all is kinda bad and shouldn't be done IMO)  
- Use more fluid bar animations on large bars, so they don't look janky if started with shorter times  
- throttle multiple bramble on same player on larodar to avoid spam  
- switch auerostor to encounter event for win detection. although the unit flags check did work wonderfully and was clever, it's no longer needed  
- add a note  
- add note  
- Fixed a bug where two countdowns would play if :Update was called on a timer that already expired. It'd unschedule the non existing countdown, schedule 1 at start, then a 2nd one on Update.. This is a regression caused when fixing a separate bug when AddTime and RemoveTime were fixed. the correction was also incorrectly applied to :update  
- guessed fix for mythic blaze on intermission, but blue note is vague enough that it's just a guess and needs to be confirmed  
- fix spellkey mismatch with igniting growth and add missing message for it  
- Add missing orbs timer to larodar for heroic+  
- Update koKR (#346)  
- Update localization.ru.lua (#345)  
- Update localization.tw.lua (#344)  
- Fix layout  
- more tiny tweaks  
- refine down PBC panel some more  
- First pass on panel restructuring for easier finding of things  
- Update commonlocal.es.lua (#342)  
- Update localization.es.lua (#341)  
- Fix layout of buttons in Core options (#340)  
- Add LuaLS annotations to DBM-GUI (#339) Frames are a bit messy because they are classes, so if you want a frame with a custom field in it you need to declare a new subclass. Also, frames using templates have to declare a new class inheriting from the frame and template(s). That's why the diff is relatively large.  
- Add basic type annotations to DBT and fix all LuaLS warnings (#338) This uncovered some small bugs, but all of them are in functions that effectively aren't used at the moment  
- allow \"isTanking\" api to run against boss unit in wrath (as well as cata) classic  
- Add @class annotation on timer/announce/warning/... objects (#337)  
- Only show DBM-PvP info message if DBM-PvP is not installed (#336)  
- Update localization.ru.lua (#968)  
- one small revert from last PR, use upvalue for the VERY frequently called GetNamePlates api  
- Add PvP mod hint in Ashenvale in SoD. (#335)  
- Put failsafe into volcoross that prevents a high stack tank from being told to take jaws if there was an early swap.  
- Update version check  
- Sync searing aftermath name  
- Micro timer tweaks  
- tweak one timer  
- Optimize some Lua for loops preventing garbage tables.  
- missed one line  
- Vastly improve accuracy of igira timers in LFR by account for fact that torment can go into overtime (due to a "no failure allowed" protection it has that lets it go beyond initial 20 second cast time and affect all timers)  
    This new method will more accurately start most timers in applied instead of removed, and then, in addition, adjust weapon timers (which also get affected by overtime even though weapon isn't picked til after overtime)  
    Also changed tindral staging to match latest BW  
- bump alpha  
- Prep classic version for tag  
- bump alpha  
