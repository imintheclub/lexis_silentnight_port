Project context:
- I maintain a GTA V heist-focused Lua script for Lexis mod menu.
- Repo root: /Users/shiv/dev/projects/personal/lexis_silentnight_port
- Main script: /Users/shiv/dev/projects/personal/lexis_silentnight_port/src/ShillenSilent.lua

Terminology:
- Cherax: GTA V mod menu with its own Lua API.
- Lexis: GTA V mod menu with a different Lua API.
- Silent Night: a heist script originally for Cherax (source is in this repo under resources).
- My script is a Lexis-focused fork/port direction: heist editing + selected Silent Night features.

Repo layout:
- Silent Night source reference: /Users/shiv/dev/projects/personal/lexis_silentnight_port/resources/SilentNight
- Cherax Lua API docs: /Users/shiv/dev/projects/personal/lexis_silentnight_port/resources/cherax_docs
- Lexis Lua API docs: /Users/shiv/dev/projects/personal/lexis_silentnight_port/resources/lexis_docs
- Core runtime dependency directory: /Users/shiv/dev/projects/personal/lexis_silentnight_port/src/ShillenSilent_core

Core/runtime file model:
- External dependencies for this script should live under `src/ShillenSilent_core` going forward.
- `ShillenSilent.lua` is now a loader/entrypoint that assembles module files from:
- `src\ShillenSilent_core\core`
- `src\ShillenSilent_core\shared`
- `src\ShillenSilent_core\heists`
- `src\ShillenSilent_core\runtime`
- Font loading model in script:
- Primary: `src\ShillenSilent_core\fonts\InterVariable.ttf`
- Preset JSON storage is under:
- `src\ShillenSilent_core\HeistPresets\Apartment`
- `src\ShillenSilent_core\HeistPresets\CayoPerico`
- `src\ShillenSilent_core\HeistPresets\DiamondCasino`

What I want from you:
- Treat Silent Night as behavior/reference, then translate cleanly to Lexis API.
- Before coding, inspect local code and docs in this repo.
- Keep changes pragmatic and minimal-risk; preserve existing behavior unless asked.
- When editing UI, keep the current light-style system consistent.
- When you claim something is missing/present, verify in-file with exact function/line references.
- Run syntax checks after edits (e.g., `luac -p "ShillenSilent.lua"`).
- Give concise summaries: what changed, why, and file/line pointers.

Baseline invariants (generic):
- Keep this as a heist-focused Lexis Lua script; do not broaden scope unless requested.
- Preserve current behavior by default; changes should be additive, not destructive.
- Reuse existing internal patterns/helpers instead of introducing parallel duplicate systems.
- Keep UI structure coherent and consistent with the current menu framework (tabs/subtabs, groups, controls).
- Preserve stable control semantics (buttons/toggles/sliders/dropdowns should continue to behave predictably).
- Keep code changes localized and minimal-risk; avoid wide refactors unless asked.
- Treat Silent Night as behavior/reference only; implement through Lexis APIs and conventions.
- Keep runtime safety guards (clamping/validation) for user-entered or loaded values.
- Do not change core offsets/stat write pathways without explicit approval.
- Keep comments functional/explanatory only; avoid branding/narrative comments.
- Do not manually edit `release-v*` files/directories; make code changes only in root `src/` and generate releases from that source.
- After edits, always run a syntax check and report result.
