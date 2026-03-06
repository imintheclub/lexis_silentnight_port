# ShillenSilent Invariants

## 1) Scope and intent
- This repository is a heist-focused Lexis Lua script port (`ShillenSilent`), not a general mod menu project.
- SilentNight under `resources/SilentNight` is behavior/reference input; implementation must follow Lexis APIs and this codebase patterns.
- Default rule: preserve behavior unless explicitly asked to change behavior.

## 2) Canonical source and release policy
- Canonical source is only `src/`.
- Do not hand-edit any `release-v*` directories; they are generated artifacts.
- Build releases from `src/` via `generate_release.sh`.

## 3) Runtime architecture (current, authoritative)
- Entrypoint: `src/ShillenSilent.lua`.
- `ShillenSilent.lua` is a module loader with cache + circular-load protection and file-backed chunk loading.
- Intentional globals exposed by loader:
  - `_G.shillen_require`
  - `_G.require_module`
- `app/main` is the runtime boot target loaded by the loader.
- Module roots are under `src/ShillenSilent_core/`:
  - `core/`
  - `shared/`
  - `heists/`
  - `runtime/`
  - `app/`

## 4) Module ownership boundaries
- `core/bootstrap.lua`: runtime config, state container, path/directory helpers, guarded async job runner.
- `core/ui.lua`: all custom UI rendering, components, layout, and interactions.
- `core/native_api.lua`: small native helper wrappers and control-block list.
- `shared/heist_state.lua`: central mutable per-heist state/config/refs/callback contracts.
- `shared/presets_and_shared.lua`: preset IO/validation/apply flows + shared helpers (cuts, options, payout helpers).
- `shared/danger_groups.lua`: reusable danger-warning UI group builders.
- `shared/coords_teleport.lua`: coordinate teleport helper + cooldown + guarded job wrapper.
- `shared/blip_teleport.lua`: blip-based teleport helper flows for apartment/doomsday.
- `heists/*`: heist-specific logic + tab registration for Cayo, Casino, Apartment, Doomsday, Cluckin.
- `runtime/solo_launch.lua`: all solo-launch setup/reset behavior (not owned by casino logic).
- `runtime/main_loop.lua`: long-running loop, toggle enforcement cadence, input/render/control gating.
- `app/main.lua`: tab discovery/creation, module registration, runtime start.

## 5) Module contract invariants
- Every module under `src/ShillenSilent_core/**/*.lua` must return a table/module value.
- Cross-module access must use `require_module("<module/path>")`.
- Do not create new implicit globals for module state; keep state local or inside exported module tables/shared state.
- If a new module file is added, it must be included in `module_files` in `src/ShillenSilent.lua`.

## 6) State and callback invariants
- `shared/heist_state.lua` is the single source of truth for:
  - per-heist config values
  - flags
  - UI refs
  - callback placeholders
- Modules may populate callback slots (for example in cayo/casino/apartment), but should not duplicate state containers.
- Preset load/apply flows must be nil-safe and validation-gated before mutating game state.

## 7) UI and behavior invariants
- Keep current heist-only tab model and existing subtab organization.
- Preserve light-theme visual system in `core/bootstrap.lua`/`core/ui.lua` unless UI redesign is explicitly requested.
- Preserve control semantics for existing toggles, sliders, dropdowns, and buttons.
- Keep dangerous actions clearly labeled/warned (danger groups + notifications).

## 8) Async and runtime safety invariants
- Use `run_guarded_job` for potentially long or re-entrant actions (teleports, force-ready, instant-finish style actions).
- Keep the main runtime loop non-blocking (`util.yield(0)` cadence preserved).
- Preserve anti-spam guards where present (for example teleport cooldown and guarded job keys).
- Keep clamping/validation around user inputs, preset values, and payout/cut calculations.

## 9) Asset and data path invariants
- Current font path used by config is `ShillenSilent_core\\fonts\\Inter-SemiBold.ttf`.
- Presets live outside core under sibling directory:
  - `ShillenSilent_HeistPresets\\Apartment`
  - `ShillenSilent_HeistPresets\\CayoPerico`
  - `ShillenSilent_HeistPresets\\DiamondCasino`
- Do not relocate preset folders without explicit migration handling.

## 10) Tooling and verification (mandatory workflow)
- Always format Lua changes with Homebrew `stylua`, not cargo/path-preferred alternatives.
- Canonical formatter command:
  - `/opt/homebrew/bin/stylua src`
- Verify the Homebrew binary is being used:
  - `/opt/homebrew/bin/stylua --version`
- Do not rely on plain `stylua` from `PATH` when multiple installs exist.
- After edits, always run syntax checks across all Lua files:
  - `rg --files src -g '*.lua' | while read -r f; do luac -p "$f"; done`
- If available, run `luacheck` as an extra static pass; treat syntax-check pass as required minimum.

## 11) Change management rules
- Keep changes targeted and low-risk unless a broad refactor is explicitly requested.
- Do not move heist behavior between files arbitrarily; keep logic where ownership says it belongs.
- When extracting shared code, preserve behavior and keep call signatures stable at integration points.
- Any claim about behavior/location must be verified against current files, not memory.
