# <DBM Mod> Raids (DF)

## [10.2.14](https://github.com/DeadlyBossMods/DBM-Retail/tree/10.2.14) (2024-01-09)
[Full Changelog](https://github.com/DeadlyBossMods/DBM-Retail/compare/10.2.13...10.2.14) [Previous Releases](https://github.com/DeadlyBossMods/DBM-Retail/releases)

- bump versions, prepare new tag for all  
- begin, and stop work on adding missing strings to other files. That's probably all I'm gonna do cause it's way too much work with how crappy and disorganized files are. Makes me appreciate the localizers that do update these even more. I certainly don't have time or patience for it.  
- further tweaks  
- minor code tweak  
- Update koKR (Retail) (#978)  
- Update koKR (#363)  
- Update localization.tw.lua (#362)  
- Update localization.ru.lua (#361)  
- Update dropdowns with groupings  
- Fix dropdown autopositioning if no previous element.  
- Fix description parsing for dropdown options.  
- Fix https://github.com/DeadlyBossMods/DBM-Retail/issues/976  
- Brood keeper Diurna update  
     - Some LFR timer tweaks  
     - All add timers changed to nameplate only  
- Fix a bug that caused boss distance checks to fail when out of range, due to a bad logic check for success. It needs to be specifically a nil check and not a nil and false check  
- Fix https://github.com/DeadlyBossMods/DBM-Retail/issues/973  
- update last checkout  
- Add a nice simple reset button to chat frame selection  
- Bracket struggles.  
- Add UI option to select chat frame for DBM messages v2 (#360)  
- Remove the Raid boss whisper exploiting from nymue now that blizzard has fixed the bug we reported ON THE PTR  
- update versioncheck  
- fix bad replace  
- reclassify world boss mod (again?, god forbid sourcetree work for once)  
- Correctly sort World Boss tab and other tab  
- reclassify world boss mod  
- Fix another removed change, hopefully without deleting entire repo due to sourcetree bug  
- sourcetree is fucking stupid  
- GUI Updates (#354) Co-authored-by: Adam <MysticalOS@users.noreply.github.com>  
- note fix  
- Couple minor timer fixes  
- Fix two more mismatching spell keys  
- Update localization.ru.lua (#357)  
- Update koKR (#358)  
- Fix lfr and normal supernova cd bar (enrage) for tindral  
- Missed this too (BTW, verify your localized text cause I did my best guesswork with editing them)  
- These options no longer control combat timers, since they are no longer hacked/dummy objects they follow normal timer conventions (meaning you enable/disable the countdown via GUI option within individual mods)  
- Tweaked stage 3 tank swaps on fyrakk to be less frequent after 4 stacks  
    Downgraded Flesh Mortification from special warning to regular one since it's more of an info warning than a "this is urgent"  
- Locale-BR: correct combat text tense (#356)  
- Fix moonfang options  
- Revert some of combat to RP timer changes, since I reworked and restored object and I do still want distinction of combat auto starts from rp "this doesn't auto engage" timers  
- Reconstructed NewCombatTimer in standard auto timer texts so it's not injected into old enrage object.  
- Fix another bad charge case, this time on normal, which was still executing the heroic/mythic timer path incorrectly  
- Obliterate the NewCombatTimer object. It hasn't worked in the entire 9 or so years it existed, so no reason to start using it now, RP timer serves same function and actually works  
- replace all uses of NewCombatTimer with NewRPTimer  
- use the season 3 dungeon ids, not season 1, oops  
- Fixed a bug where available mod notice would show every time you enter a dragonflight dungeon, it should only show once Fixed a different bug where it would NOT show when you entered a non dragonflight seasonal dungeon.  
- add a feature that plays debug sound for timer debug messages, can be toggled off/on with /dbm debugsound  
- Fix LFR nextspecial times  
- Update localization.ru.lua (#355)  
- bump hotfix revisions  
- inverse special logic to hopefully eliminate remaining cases of wrong charge timer being started and resulting in timer being off. This should fix the remaining case where sometimes a 20 second timer started when it should start a 26 second timer on mythic difficulty.  
- another changed spell key update  
- It's about time to change this text to not say twitter, and just say \"most socials\" instead  
- two minor timer adjustments  
- make the countdown option a healer only default though, still tones down afflicted audio spam further  
- disable afflicted warning for those who don't have means to actually deal with adds. timer is still on for all since it still informs dungeon movements  
- Re-enable .5 stage api for intermissions  
    Fixed supernova cast bar so it starts in correctp lace.  
- scope ashenvale pvp mod alert to only alert if level 25 and walking in zone. This will prevent message showing if leveling in zone or just flying over it.  
- update luacheck  
- Revert \"Switch callback debug\" This reverts commit 6fa2a9e908e738eb3fa5a7ca7b91ea137db23862.  
- Fix several objects using incorrect arg placements, for most part none of them errored because having "prewarn" set when it's unused doesn't do anything and having missing voice version on non special announces also didn't error cause it uses a 1 default if nil. However a good number of objects had voice version in wrong place.  
- attempt to fix bug  on assault of the Zaqali where cudgel timers can become wrong if boss doesn't finish a cast (and subsiquently recasts it) because tank died before cast finished  
- Update koKR (#350)  
- Update localization.es.lua (#352)  
- Update localization.es.lua (#351)  
- bump alpha  
- update version check  
- Prep new classic era tag  
- Remove ability to ungroup private aura sounds, since it breaks private aura icons in GUI  
- Update trash mod with more abilities  
     - Run out and say bubbles for Shadowflame Bomb  
     - Run out for Charged stomp for Melee  
     - General announce for shadowcharged slam (leaves fire patches on ground)  
     - Interrupt warning for Tranquility  
- bump alpha  
