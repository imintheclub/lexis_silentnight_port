# Lexis Lua API Docs (EmmyLua Stubs)

Typed Lua stub files for the Lexis scripting API, organized by module for editor autocomplete, hover docs, and type hints. This info was scraped on 03/03/2026. Also contains ShillenLua 1.7.1 as reference code, taken from [here](https://discord.com/channels/1181574376727003166/1453814961838231715/1458189966961279263).

## What This Repo Is

This repository is a documentation/stub pack, not a runnable script project by itself. Useful for LLMs to understand the Lexis Lua API.

- Purpose: improve scripting DX in editors (Lua language server, EmmyLua-compatible tooling)
- Format: `---@class`, `---@field`, `---@param`, `---@return` annotations + inline examples
- Scope: Lexis environment modules and game native declarations (`natives.lua`)

Primary upstream references in docs:

- `https://docs.lexis.re/`
- `https://docs.lexis.re/natives.lua`
- `https://docs.lexis.re/example.zip`

## Repository Structure

- `intro.lua`: environment overview (`this.permissions`, `this.unload`, `joaat`) and permission model
- `lexis.lua`: account-level Lexis identity helpers (ex: `lexis.username()`)
- `natives.lua`: large native function declaration set for GTA scripting
- Module stubs by concern:
  - `account.lua`, `players.lua`, `game.lua`
  - `menu.lua`, `gui.lua`, `input.lua`, `notify.lua`
  - `memory.lua`, `invoker.lua`, `scapi.lua`
  - `http.lua`, `json.lua`, `regex.lua`, `math.lua`, `util.lua`
  - `dirs.lua`, `paths.lua`, `file.lua`, `script.lua`, `events.lua`, `constants.lua`, `pools.lua`, `request.lua`
- `lexis_docs_example_console.lua`: example UI/console script demonstrating practical API usage patterns

## Typical Usage

1. Open your Lexis script project in VS Code / Cursor / another Lua LS-based editor.
2. Copy or symlink these `.lua` stubs into a folder your workspace indexes (for example `./.stubs/lexis/`).
3. Ensure your Lua language server includes that folder in workspace library settings.
4. Write your script normally; autocomplete and hover help should now resolve Lexis symbols.

## Minimal Lua LS Setup (VS Code) **(UNTESTED + AI GENERATED)**

Add to `.vscode/settings.json` in your script project:

```json
{
  "Lua.workspace.library": [
    "${workspaceFolder}/.stubs/lexis"
  ],
  "Lua.diagnostics.globals": ["this", "lexis", "menu", "game", "players", "gui", "input", "memory", "invoker", "notify", "http", "json", "regex", "paths", "dirs", "file", "script", "events", "constants", "pools", "request", "account", "scapi", "joaat"]
}
```

Adjust globals to your exact runtime surface.