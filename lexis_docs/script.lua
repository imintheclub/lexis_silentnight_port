-- ============================================================
-- # Script
-- ============================================================
--
-- ## Functions
--
-- ### running
-- If a script is running.
-- ---@param name string|integer
-- function script.running(name): bool
--
-- ### globals
-- Creates an instance of script_global.
-- ---@param base integer
-- function script.globals(base): script_global
--
-- ### tunables
-- Creates an instance of tunables.
-- ---@param name string|integer
-- function script.tunables(name): tunables
--
-- ### locals
-- Creates an instance of script_local.
-- ---@param name string|integer
-- ---@param base integer
-- function script.locals(name, base): script_local
--
-- ### program
-- Script program memory address retrieved via the script name.
-- ---@param name string|integer
-- function script.program(name): memory_address
--
-- ### host
-- Returns a player for the host of the given script.
-- ---@param name string
-- function script.host(name): player
--
-- ### force_host
-- Force host of a script.
-- ---@param script string|integer
-- function script.force_host(script): bool
--
-- ### call
-- Calls a script function via its function offset.
-- ---@param name string|integer
-- ---@param position integer
-- ---@param args table
-- function script.call(name, position, args): memory_address
--
-- ### patch
-- Creates a script patch.
-- ---@param name string|integer
-- ---@param position integer
-- ---@param offset integer
-- ---@param bytes integer[]
-- function script.patch(name, position, offset, bytes): script_patch
--
-- ## Types
--
-- ### script_global
-- | Type           | Name    |
-- |----------------|---------|
-- | memory_address | address |
-- | vec2           | vec2    |
-- | scr_vec3       | vec3    |
-- | integer        | int8    |
-- | integer        | int16   |
-- | integer        | int32   |
-- | integer        | int64   |
-- | integer        | uint8   |
-- | integer        | uint16  |
-- | integer        | uint32  |
-- | integer        | uint64  |
-- | number         | float   |
-- | number         | double  |
-- | bool           | bool    |
-- | string         | str     |
-- ---@param index integer
-- function script_global:at(index): script_global
-- ---@param index integer
-- ---@param size integer
-- function script_global:at(index, size): script_global
--
-- ### script_local
-- | Type           | Name    |
-- |----------------|---------|
-- | memory_address | address |
-- | vec2           | vec2    |
-- | scr_vec3       | vec3    |
-- | integer        | int8    |
-- | integer        | int16   |
-- | integer        | int32   |
-- | integer        | int64   |
-- | integer        | uint8   |
-- | integer        | uint16  |
-- | integer        | uint32  |
-- | integer        | uint64  |
-- | number         | float   |
-- | number         | double  |
-- | bool           | bool    |
-- | string         | str     |
-- ---@param index integer
-- function script_local:at(index): script_local
-- ---@param index integer
-- ---@param size integer
-- function script_local:at(index, size): script_local
--
-- ### script_patch
-- | Type      | Name     |
-- |-----------|----------|
-- | bool      | enabled  |
-- | integer[] | original |
-- | integer[] | patch    |
-- function script_patch:enable(): nil
-- function script_patch:disable(): nil
--
-- ### tunables
-- | Type    | Name   |
-- |---------|--------|
-- | integer | int8   |
-- | integer | int16  |
-- | integer | int32  |
-- | integer | int64  |
-- | integer | uint8  |
-- | integer | uint16 |
-- | integer | uint32 |
-- | integer | uint64 |
-- | number  | float  |
-- | number  | double |
-- | bool    | bool   |
--
-- ## Example
-- ```lua
-- function get_owned_property(index, character)
--     local result = script.call('freemode', 0xAA7B7, {index, character})
--     return result and result.int32 or 0
-- end
--
-- script.globals(2672741):at(3694).bool = true
-- script.locals('am_mp_drone', 197):at(245).int32 = 0
-- ```

---@class script_global
---@field address memory_address
---@field vec2    vec2
---@field vec3    scr_vec3
---@field int8    integer
---@field int16   integer
---@field int32   integer
---@field int64   integer
---@field uint8   integer
---@field uint16  integer
---@field uint32  integer
---@field uint64  integer
---@field float   number
---@field double  number
---@field bool    boolean
---@field str     string
script_global = {}

---@overload fun(self: script_global, index: integer): script_global
---@overload fun(self: script_global, index: integer, size: integer): script_global
---@param index integer
---@param size? integer
---@return script_global
function script_global:at(index, size) end

---@class script_local
---@field address memory_address
---@field vec2    vec2
---@field vec3    scr_vec3
---@field int8    integer
---@field int16   integer
---@field int32   integer
---@field int64   integer
---@field uint8   integer
---@field uint16  integer
---@field uint32  integer
---@field uint64  integer
---@field float   number
---@field double  number
---@field bool    boolean
---@field str     string
script_local = {}

---@overload fun(self: script_local, index: integer): script_local
---@overload fun(self: script_local, index: integer, size: integer): script_local
---@param index integer
---@param size? integer
---@return script_local
function script_local:at(index, size) end

---@class script_patch
---@field enabled  boolean
---@field original integer[]
---@field patch    integer[]
script_patch = {}

---@return nil
function script_patch:enable() end

---@return nil
function script_patch:disable() end

---@class tunables
---@field int8   integer
---@field int16  integer
---@field int32  integer
---@field int64  integer
---@field uint8  integer
---@field uint16 integer
---@field uint32 integer
---@field uint64 integer
---@field float  number
---@field double number
---@field bool   boolean

---@class script
script = {}

--- If a script is running.
---@param name string|integer
---@return boolean
function script.running(name) end

--- Creates an instance of script_global.
---@param base integer
---@return script_global
function script.globals(base) end

--- Creates an instance of tunables.
---@param name string|integer
---@return tunables
function script.tunables(name) end

--- Creates an instance of script_local.
---@param name string|integer
---@param base integer
---@return script_local
function script.locals(name, base) end

--- Script program memory address retrieved via the script name.
---@param name string|integer
---@return memory_address
function script.program(name) end

--- Returns a player for the host of the given script.
---@param name string
---@return player
function script.host(name) end

--- Force host of a script.
---@param scr string|integer
---@return boolean
function script.force_host(scr) end

--- Calls a script function via its function offset.
---@param name string|integer
---@param position integer
---@param args table
---@return memory_address
function script.call(name, position, args) end

--- Creates a script patch.
---@param name string|integer
---@param position integer
---@param offset integer
---@param bytes integer[]
---@return script_patch
function script.patch(name, position, offset, bytes) end
