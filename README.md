# About
ShillenSilent is a heist-focused Lexis Lua script, based on ShillenLua and adapted with SilentNight heist logic/data.

- Press `T` to open/close the menu.

This project currently:
- focuses on heist workflows and removes non-heist top-level tabs (INFO, SPAWNER, VEHICLE, OBJECTS) originally present in ShillenLua
- has a resizable custom Click UI with animations
- includes 1-click, loot-aware max payout preset buttons for Casino/Cayo/Doomsday
- expands Cayo/Casino prep controls to SilentNight-level depth
- includes JSON presets for Apartment, Cayo, and Casino (save/load/remove/refresh/copy path, keyboard/clipboard naming)


# Attribution
## SilentNight
Portions of heist logic/data are adapted from SilentNight by SilentSalo.
- Source: [SilentNight](https://github.com/SilentSalo/SilentNight)
- License: [CC BY-NC 4.0](https://raw.githubusercontent.com/SilentSalo/SilentNight/refs/heads/main/LICENSE.md)

This repository contains modified upstream content (Lexis port + additional changes). Keep attribution and license notice with redistributions; non-commercial use only.

## ShillenLua
Made by Shillen#0000 on the Lexis discord. Originally found [here](https://discord.com/channels/1181574376727003166/1453814961838231715).

# Install Instructions
1. press windows + R to open the run dialog and paste in `%USERPROFILE%/Lexis/Grand Theft Auto V/Scripts` (without the enclosing backticks)
2. Copy everything from the src folder into the folder you opened in step 1)
3. Load the script in Lexis

# Changelog
## v0.1.1
- Added missing teleports:
  - Casino: `Teleport to Arcade` (click UI + controller menu)
- Added strict interior-gating for board/computer/screen teleports so they only work in the correct property interior:
  - Agency: `Teleport to Computer` now requires Agency interior
  - Auto Shop: `Teleport to Board` now requires Auto Shop interior
  - Salvage Yard: `Teleport to Screen & Board` now requires Salvage Yard interior
  - Doomsday: `Teleport to Screen` now requires Facility interior
  - Apartment: `Teleport to Heist Board` now requires Apartment interior context (excludes Kosatka/Arcade/Facility/Agency/Auto Shop/Salvage Yard interiors)
- Improved Agency computer teleport behavior:
  - Added stronger interior detection logic and periodic refresh for its UI visibility state
- Added missing `Skip Cutscene` actions across newer heists and modes:
  - Agency, Auto Shop, Salvage Yard, Cluckin, KnoWay
- Reorganized/paired several heist action buttons for cleaner, more consistent tab layout
- Added Business Manager v0 — new Businesses section with tabs for:
  - **Acid Lab**: Production tick, refill supplies, instant sell, fast production toggle
  - **Bunker**: Production tick, refill supplies, instant sell, disable raids/reminders toggles, teleport
  - **Hangar**: Fill cargo (max), teleport
  - **Moto Club**: Refill all supplies, instant sell, fast production/disable reminders toggles; per-sub-business production tick and refill supplies (teleports temporarily removed until working)
  - **Nightclub**: Production tick (all), fill all products, collect safe, fill safe ($250K), set popularity max, disable raids/reminders toggles, teleport
  - **Special Cargo**: Instant sell, fill cargo (max 111), disable raids/reminders toggles, teleport with location dropdown
  - **Misc**: Grouped teleports for Money Fronts (with location dropdown), Garment Factory, and Bail Office
- Added `Unlock GTA+` button to Intensity Settings tab (temporarily unlocks GTA+ for the session)
- Fix maximum payout not auto-applying. 

## v0.1.0
- Added no-click menu mode (controller/keyboard-friendly alternative UI) 
- Added dark mode (on by default, hot refresh)
- Fixed Cayo and Casino logic bugs
- Performance improvements: UI rendering refactor, improved services runtime, reduced overhead in bootstrap, fix apartment modularization


## v0.0.9
- major upgrade to doomsday heist tab
- added presets, added teleports, added new instant finish to avoid that glitch of getting stuck in a session from before
- Added v0 of new heists
	- Thanks shillen and silentsalo for the code for this literally
	- Agency
	- Salvage Yard
	- Auto Shop
	- KnoWay

## v0.0.8
- thanks DustyIdeas for the patch
- fixed game crash sometimes when loading script
- fixed broken casino autograbber
- fixed some doomsday heist issues 

## v0.0.7
- changed from the dogshit custom ai slop bullshit loader code to real modules with proper scoping and requires
- made notifications more consistent + present for every action which commits a state change of any kind + all missing error cases

## v0.0.6
- I didn't even realize this, but the custom font was not working, so made that work
- Made it easier to "update" the script by moving the heist preset directory outside. So from now on, you'll be able to just directly delete the core folder and the main script and just copy in the new one. 
- Basic animations on resize/dropdown
- Remove dud toggle on Cayo preps

## v0.0.5
- make responsive + resizable. menu (controller + kb) alternate layout coming next

## v0.0.4
- modularize and refactor code so it's less fucking wack

## v0.0.3
- fixed algorithm for kosatka teleport
- remove broken cayo perico teleport to drainage tunnel button for now
- memory fixes
- some blocking operations moved to jobs

## v0.0.2
- Added cutscene skip button for 4 major heists
- Added skip cooldown button WITH WARNING NOT TO USE IT !!! for Casino, Cayo, Doomsday
- remove 1500% cap on apartment and change to 300%
	- 1) tbh idk why it was that high on silentnight. maybe i will find out later if someone complains
	- 2) it seems to be confusing people into thinking they CAN put the cut that high so i will clip it lower lol
- add teleport to kosatka button to cayo preps
- some more styling tweaks
- refactor to keep all script related files (including heists preset folder) within ShillenSilent_core folder within scripts
- some code cleanup

## v0.0.1
- Improve Doomsday Heist instant finish button to autodetect all difficulty permutations across all doomsday heist acts
- restyle the menu away from ShillenLua's base look

## v0.0.0
- add the ability to create heist setup presets for Cayo and Casino (as found in Silent Night)
- More granular prep for Cayo and Casino (as found in Silent Night)
- Removed all non-heist portions of ShillenLua
- Added max payout button for Cayo and Casino, crap version for Doomsday Heist too
- Accidentally fixed the bug from ShillenLua cayo prep (i think) where sometimes Cayo has no escape routes and you are forced to do the gather Intel again before being able to start finale
