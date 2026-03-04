-- ============================================================
-- # Dirs
-- ============================================================
--
-- > **Warning:** Paths are limited to the Lexis folder, trying to use a
-- > path in another directory will fail.
--
-- ## list
-- Returns a list of files in the directory.
-- ---@param path string
-- ---@param extension? string
-- function dirs.list(path, extension?): string[]
--
-- ## exists
-- If a directory exists.
-- ---@param path string
-- function dirs.exists(path): bool
--
-- ## remove
-- Deletes a directory.
-- ---@param path string
-- function dirs.remove(path): bool
--
-- ## create
-- Creates a directory.
-- ---@param path string
-- function dirs.create(path): bool

---@class dirs
dirs = {}

--- Returns a list of files in the directory.
---@param path string
---@param extension? string
---@return string[]
function dirs.list(path, extension) end

--- If a directory exists.
---@param path string
---@return boolean
function dirs.exists(path) end

--- Deletes a directory.
---@param path string
---@return boolean
function dirs.remove(path) end

--- Creates a directory.
---@param path string
---@return boolean
function dirs.create(path) end
