-- ============================================================
-- # Account
-- ============================================================
--
-- ## Functions
--
-- ### character
-- Returns your active character.
-- function account.character(): integer
--
-- ### name
-- Returns your account name.
-- function account.name(): string
--
-- ### rockstar_id
-- Returns your account rockstar ID.
-- function account.rockstar_id(): integer
--
-- ### stats
-- Creates an instance of stat.
-- ---@param name string|integer
-- function account.stats(name): stat
--
-- ## Types
--
-- ### stat
-- | Type    | Name   |
-- |---------|--------|
-- | string  | str    |
-- | integer | int32  |
-- | integer | int64  |
-- | integer | uint8  |
-- | integer | uint16 |
-- | integer | uint32 |
-- | integer | uint64 |
-- | number  | float  |
-- | bool    | bool   |
--
-- ## Example
-- ```lua
-- local stat = account.stats('MP' .. tostring(account.character()) .. '_CHAR_SET_RP_GIFT_ADMIN')
-- print('current: ', stat.int32)
-- stat.int32 = 1555800 -- level 99
-- ```

---@class stat
---@field str    string
---@field int32  integer
---@field int64  integer
---@field uint8  integer
---@field uint16 integer
---@field uint32 integer
---@field uint64 integer
---@field float  number
---@field bool   boolean

---@class account
account = {}

--- Returns your active character.
---@return integer
function account.character() end

--- Returns your account name.
---@return string
function account.name() end

--- Returns your account Rockstar ID.
---@return integer
function account.rockstar_id() end

--- Creates an instance of stat.
---@param name string|integer
---@return stat
function account.stats(name) end
