# ShillenSilent
ShillenSilent is a Lexis Lua script for GTA V heist and business-management workflows. It provides a custom click UI and a controller-friendly menu mode for managing heist setups, payout cuts, prep state, teleports, cooldowns, business production, safe collection, and related quality-of-life actions.
- Heist tools for Cayo Perico, Casino, Doomsday, Apartment, Agency, Auto Shop, Salvage Yard, Cluckin Bell, and KnoWay workflows.
- Business tools for Acid Lab, Bunker, Hangar, Special Cargo, Nightclub, MC businesses, Arcade, Garment Factory, Bail Office, and Money Fronts.
- Prep, reset, force-ready, solo-launch, instant-finish, cut, max-payout, cooldown, cutscene-skip, and teleport actions where supported.
- JSON presets for supported heists, with shared save/load UI in click and controller modes.
- Persistent settings for UI mode, theme, language.
- Internationalized UI.


## Screenshots
### Controller UI
<img width="455" height="641" alt="image" src="https://github.com/user-attachments/assets/45286189-c95c-4316-921f-143f95bdb740" />

<img width="499" height="677" alt="image" src="https://github.com/user-attachments/assets/4c95d23b-24d5-49c9-8486-85c8f113fa8e" />


### Click UI
<img width="1408" height="873" alt="image" src="https://github.com/user-attachments/assets/415bf56d-4d52-4032-bda6-bb2b07707662" />

<img width="534" height="1145" alt="image" src="https://github.com/user-attachments/assets/2b5ab75f-41c4-4887-99d3-5f929da3b9e1" />

<img width="1480" height="914" alt="image" src="https://github.com/user-attachments/assets/86b8971f-56d9-416b-9d6e-003c24c81a10" />

<img width="1404" height="839" alt="image" src="https://github.com/user-attachments/assets/ef759aeb-1997-4385-a9dd-f30ac1f30025" />

<img width="1333" height="1060" alt="image" src="https://github.com/user-attachments/assets/2cab64a9-fb1b-4e08-8759-32028886cb76" />

<img width="1518" height="1142" alt="image" src="https://github.com/user-attachments/assets/aa573f49-ad21-431e-b60d-b68f0d4b0b76" />

<img width="2218" height="1219" alt="image" src="https://github.com/user-attachments/assets/f3d5c361-4dba-4c4b-8566-8ec06aaaee67" />

<img width="3381" height="1332" alt="image" src="https://github.com/user-attachments/assets/375034a7-3a84-4bfb-8967-9be253b853ae" />

<img width="1345" height="1036" alt="image" src="https://github.com/user-attachments/assets/f562dd19-1535-493b-abfe-ed79278d983f" />



## Install
1. Download the latest release file from the [release page](https://github.com/imintheclub/lexis_silentnight_port/releases) and unzip it. You will see a folder called `src/`.
2. Press `Windows + R` and type `%USERPROFILE%/Lexis/Grand Theft Auto V/Scripts` and press Enter.
3. Copy ***the contents*** of the `src` folder (not the WHOLE `src` FOLDER ITSELF) into that `Scripts` folder.
4. Load `ShillenSilent.lua` from Lexis scripts.

## Usage
- Press `T` to open or close the click UI.
- Use the drawer to switch between Info, heist features, and business features.
- Change UI mode, theme, and language from the Settings feature. UI mode and language changes apply on the next script load.
- Use controller mode from Lexis if you prefer the native menu-style interface.

## FAQ
1. **Is this open source?**

   Yes. ShillenSilent is open source, and pull requests are welcome at <https://github.com/imintheclub/lexis_silentnight_port>.

2. **Is this free?**

   Yes. This project is based on code that cannot be monetized, and it will not be monetized. If someone charged you for it, you got scammed.

3. **Where do I download it?**

   Use the latest release from the download channel, or download it from the GitHub Releases page: <https://github.com/imintheclub/lexis_silentnight_port/releases>.

4. **How do I install it?**

   Follow the install steps in this README, either here on the repo page or in the `README.md` included with the release zip.

5. **How do I use it?**

   Check the how-to channel for walkthroughs and current usage notes.

6. **It will not show up after I load it. What should I do?**

   If you are using the Click UI version, press `T`. If you are using the controller/no-click version, open the Lexis menu and check `Scripts` > `Loaded Scripts`.

7. **How do I switch from Click UI to controller mode?**

   Go to the Settings tab, change the `UI Mode` dropdown to `controller`, and reload the script. After reloading, open the Lexis menu and go to `Scripts` > `Loaded Scripts` > `ShillenSilent`.

8. **My mouse is not working. What should I do?**

   Turn off frame generation in GTA graphics settings, then try switching mouse input mode to the opposite of your current setting, such as `Raw Input` or `Windows`.

   If that does not work, open `%USERPROFILE%\Lexis\Grand Theft Auto V\scripts\ShillenSilent_core`, open `config.json` in a text editor, and set `"ui_mode"` to `"controller"` (e.g. `{"ui_mode": "controller"}`). If `config.json` does not exist, create it with that content. Reload the script and then use the controller/keyboard menu from `Lexis` > `Scripts` > `Loaded Scripts` > `ShillenSilent`.

   More context on GTA V mouse input modes: <https://www.reddit.com/r/GrandTheftAutoV_PC/comments/32v7kb/psa_raw_mouse_input_may_not_be_the_best_option/>

9. **Is this safe? Will I get banned?**

   Nothing is 100% safe, but heist editing is known to be among the safer money methods as long as you stay conservative:

   - Do not use the skip cooldown feature.
   - Do not go over `$25MM` per day.
   - Do not go over about `$150MM` per week.
   - Respect the transaction cooldown timings listed on each heist tab.

10. **How do I use the max payout function?**

    Many heists have a `Max Payout` switch. When enabled, it keeps rescanning your selected inputs and tries to apply the appropriate cut for the loot, difficulty, and other options you selected. It should work for the main heists, but it may not be perfect. Please report bugs in the bug-report channel.

11. **How do I get the 12 million bonus on Pacific Standard heist? Can I share it with friends?**

    You cannot share the full bonus. Other players will only get up to 3 million dollars. Use this walkthrough: <https://www.youtube.com/watch?v=7mJ6niU-A3Q>

12. **I got a "Transaction Error" or "Price Data Invalid" error. What happened?**

    If Rockstar blocks the money with a transaction failure or invalid price data message, the value was too high or your session desynced. Lower the value, wait, and try again after about 30 minutes to be sure.

13. **Something does not work. How do I report it?**

    Please report it in the bug-report channel and include all of the following:

    - What you were doing, with specifics. For example: `Apartment heist with 250% cuts, Fleeca job did not pay out, and I got a transaction error`.
    - What you expected to happen.
    - What actually happened.
    - A short clip or screenshot.
    - Logs, if available. Check `%USERPROFILE%/Lexis/Crash.log` and `%USERPROFILE%/Lexis/log.txt`.

14. **Can you add a feature?**

    Probably, but please use the suggestions channel instead of sending direct messages.

# Attribution
## SilentNight
Portions of heist logic/data are adapted from SilentNight by SilentSalo.
- Source: [SilentNight](https://github.com/SilentSalo/SilentNight)
- License: [CC BY-NC 4.0](https://raw.githubusercontent.com/SilentSalo/SilentNight/refs/heads/main/LICENSE.md)

This repository contains modified upstream content (Lexis port + additional changes). Keep attribution and license notice with redistributions; non-commercial use only.

## ShillenLua
Made by Shillen#0000 on the Lexis discord. Originally found [here](https://discord.com/channels/1181574376727003166/1453814961838231715).

# Changelog
## v0.1.5
- **FAQ section under General** — Built-in answers covering setup, controller switching, mouse/input troubleshooting, safety, payouts, Discord, and common transaction errors.
- **Teleport to Arcade** — Direct teleport to your owned arcade.
- **Teleport to Acid Lab vehicle** — Teleports you to the spawned Acid Lab truck wherever it currently is, instead of a fixed coord.
- **Cayo Perico: Go Offline / Go Online** — Quickly drop to a solo session and re-enter an invite-only session without leaving the menu.
- **Apartment Heist selector** — Pick which Apartment heist (Fleeca, Prison Break, Humane Labs, Series A, Pacific Standard) the "Complete Preps" button targets, instead of guessing from your active mission. Selection is saved into presets.
- **Money Fronts: overall heat controls** — One slider, apply/max/min buttons, and a lock toggle that drive heat across every front at once. Controls for fronts you don't own are now grayed out, and teleports to fronts you don't own no longer silently misfire.
- **Chinese language support** — New Simplified Chinese locale, plus a proper CJK font so Chinese, Japanese, and Korean text render correctly.
- **Splash screen on load** — Briefly shows "Press T to open the window" (or controller-mode equivalent) so first-time users aren't stuck wondering how to open the menu.
- **Info panels added** — Acid Lab and Special Cargo now have dedicated info panels explaining what each toggle/loop actually does. Payout and cooldown info added to Cayo, Apartment, Agency, Salvage Yard, Auto Shop, Cluckin Bell, Doomsday, and Casino. Force Ready behavior is now explained on every heist that supports it.
- General menu reorganization, cleaner grouping of teleports/tools/danger actions, paired cut sliders, better text wrapping, dropdown sizing fixes, and click/controller parity cleanup.
- Faster locale loading (only the active language stays in memory), lighter background-job system that skips work for the inactive UI mode, and various rendering optimizations.


## v0.1.4
- **v0 LEGACY SUPPORT IS HERE**
- **Added i18n; English, Spanish, German, French, Italian, Polish, Portuguese (Brazil), Russian.**
  - The localization for Chinese, Japanese, and Korean are present, but I cannot get the font to render them.
- **Added hella themes.**
- MADE APP SKINNIER BY DEFAULT AND MADE ALL CARDS SKINNIER TOO **TO TAKE LESS SPACE ON SCREEN** 
- Added hints on each tab for what some of the non-obvious functionality does.
- Expanded business manager functionality:
  - Added more Bunker, Hangar, Nightclub, and Special Cargo controls for max sale price, supplier loops, cooldown removal, and optional no XP on instant sells.
  - Added Hangar instant sell, plus Special Cargo instant buy/sell, crate amount, max crates, and get crates.
  - Added more business laptop/computer shortcuts and teleports for Bunker, Hangar, Nightclub, Special Cargo, Bail Office, Garment Factory, and Money Fronts.
  - Money Fronts now have separate heat controls for Car Wash, Weed Shop, and Heli Tours, with apply, max/min, and lock options.
  - Added Nightclub setup skip and min popularity, plus a Garment Factory computer unbrick button.
- JSON settings file for UI mode, theme, and language, all configurable from the Settings tab.
- Fixed issue where dropdowns clip off of page by making the long ones scrollable.
- Moved to hamburger menu.
- Added JSON preset support to controller menu.
- Fixed safe collection transaction error bug when empty.
- Unified production tick UI/status behavior across Hangar, Special Cargo, Nightclub, and MC business controls.

## v0.1.3-beta
- MC businesses — Production ticks, refills, fast-production, and new teleport all should be fixed now.
- Special Cargo — Production tick should be fixed.
- Hangar — Production tick should be fixed.
- Nightclub — filling products fixed; fast prod / tick now use a per-slot cap table (Cargo 50, Sporting 100, …) instead of a uniform 360.
- New Collect Safe actions for Car Wash (money fronts), Garment Factory, Bail Office, and Arcade.
- Apartment cuts — MAX PAYOUT SHOULD BE FIXED +AUTOMATIC NOW. TURN IT ON AND APPLY CUTS
- Casino & Cayo cuts — MAX PAYOUT SHOULD BE FIXED +AUTOMATIC NOW. TURN IT ON AND APPLY CUTS
- Doomsday — MAX PAYOUT SHOULD BE FIXED +AUTOMATIC NOW. TURN IT ON AND APPLY CUTS
- UI — added themes + fixed centering of dropdowns + labels + hopefully made font render less blurry

## v0.1.2
- UI fixes for consistency
- fix production tick to be on a loop
- Business Manager updates:
  - Money Fronts:
    - Added heat editor controls (`Heat`, `Apply Heat`, `Set Heat 0`) in click UI + controller menu
    - Added `Lock Heat at 0` with threshold-based behavior (Sylo-style: only resets when heat is above threshold)
    - Added `Reset Safe Production State`
  - Moto Club:
    - Added `Disable Raids`
    - Added `Kill MC Black Screen`
  - Nightclub:
    - Added `Unbrick Safe`
    - Added popularity editor flow (`Popularity` value, `Apply Popularity`, `Lock Popularity`)
  - Salvage Yard:
    - Added `Tow Truck Instant Finish` (separate from the existing general instant finish)
    - Added popularity editor flow (`Popularity` value, `Apply Popularity`, `Lock Popularity`)
  - Runtime services:
    - Added business lock enforcement ticks for Money Front heat lock, Nightclub popularity lock, and Salvage Yard popularity lock

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
