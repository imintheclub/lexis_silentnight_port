# Install Instructions
1. press windows + R to open the run dialog and paste in `%USERPROFILE%/Lexis/Grand Theft Auto V/Scripts` (without the enclosing backticks)
2. Copy everything from the src folder into the folder you opened in step 1)
3. Load the script in Lexis

# Changelog
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