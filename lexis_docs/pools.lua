-- ============================================================
-- # Pools
-- ============================================================
--
-- ## ped
-- Returns a list of ped memory addresses.
-- function pools.ped(): memory_address[]
--
-- ## object
-- Returns a list of object memory addresses.
-- function pools.object(): memory_address[]
--
-- ## vehicle
-- Returns a list of vehicle memory addresses.
-- function pools.vehicle(): memory_address[]
--
-- ## weapon
-- Returns a list of weapon memory addresses.
-- function pools.weapon(): memory_address[]
--
-- ## Example
-- ```lua
-- for index, address in ipairs(pools.ped()) do
--     local handle = game.guid_from_entity(address)
--     if handle ~= 0 then
--         local coords = invoker.call(0x3FEF770D40960D5A, handle, false).scr_vec3 -- GET_ENTITY_COORDS
--         print('entity: ', tostring(handle), ', address: ', tostring(address.value), ', coords: ', coords)
--     end
-- end
-- ```

---@class pools
pools = {}

--- Returns a list of ped memory addresses.
---@return memory_address[]
function pools.ped() end

--- Returns a list of object memory addresses.
---@return memory_address[]
function pools.object() end

--- Returns a list of vehicle memory addresses.
---@return memory_address[]
function pools.vehicle() end

--- Returns a list of weapon memory addresses.
---@return memory_address[]
function pools.weapon() end
