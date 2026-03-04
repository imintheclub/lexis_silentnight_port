-- ============================================================
-- # File
-- ============================================================
--
-- > **Warning:** Paths are limited to the Lexis folder, trying to use a
-- > path in another directory will fail.
--
-- ## Functions
--
-- ### exists
-- If a file exists.
-- ---@param path string
-- function file.exists(path): bool
--
-- ### remove
-- Deletes a file.
-- ---@param path string
-- function file.remove(path): bool
--
-- ### open
-- Deletes a file.  [sic — opens a file]
-- ---@param path string
-- ---@param options { append: bool, create_if_not_exists: bool }
-- function file.open(path, options): file
--
-- ## Types
--
-- ### file
-- | Type   | Name  |
-- |--------|-------|
-- | bool   | valid |
-- | string | text  |
-- | json   | json  |
--
-- ## Example
-- ```lua
-- local handle = file.open(paths.cheat .. 'test.txt', { create_if_not_exists: true })
-- if handle.valid then
--     handle.text = 'this is test text'
-- end
-- ```

---@class file_handle
---@field valid boolean
---@field text  string
---@field json  json

---@class file
file = {}

--- If a file exists.
---@param path string
---@return boolean
function file.exists(path) end

--- Deletes a file.
---@param path string
---@return boolean
function file.remove(path) end

--- Opens a file and returns a file handle.
---@param path string
---@param options { append: boolean, create_if_not_exists: boolean }
---@return file_handle
function file.open(path, options) end
