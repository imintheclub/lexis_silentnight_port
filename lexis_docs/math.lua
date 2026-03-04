-- ============================================================
-- # Math
-- ============================================================
--
-- ## Functions
--
-- ### vec2
-- Different ways to create a vec2.
-- function vec2(): vec2
-- ---@param xy number
-- function vec2(xy): vec2
-- ---@param x number
-- ---@param y number
-- function vec2(x, y): vec2
--
-- ### vec3
-- Different ways to create a vec3.
-- function vec3(): vec3
-- ---@param xyz number
-- function vec3(xyz): vec3
-- ---@param x number
-- ---@param y number
-- ---@param z number
-- function vec3(x, y, z): vec3
--
-- ### scr_vec3
-- Different ways to create a scr_vec3.
-- function scr_vec3(): scr_vec3
-- ---@param xyz number
-- function scr_vec3(xyz): scr_vec3
-- ---@param x number
-- ---@param y number
-- ---@param z number
-- function scr_vec3(x, y, z): scr_vec3
--
-- ## Types
--
-- ### vec2
-- | Type   | Name |
-- |--------|------|
-- | number | x    |
-- | number | y    |
-- function vec2:normalize(): vec2
-- ---@param other vec2
-- function vec2:dot(other): number
--
-- ### vec3
-- | Type   | Name |
-- |--------|------|
-- | number | x    |
-- | number | y    |
-- | number | z    |
-- function vec3:normalize(): vec3
-- function vec3:dir(): vec3
-- ---@param other vec3
-- function vec3:dot(other): number
-- ---@param other vec3
-- function vec3:distance3d(other): number
--
-- ### scr_vec3
-- | Type   | Name |
-- |--------|------|
-- | number | x    |
-- | number | y    |
-- | number | z    |
-- function scr_vec3:normalize(): scr_vec3
-- function scr_vec3:dir(): scr_vec3
-- ---@param other scr_vec3
-- function scr_vec3:dot(other): number
-- ---@param other scr_vec3
-- function scr_vec3:distance3d(other): number
--
-- ## Example
-- ```lua
-- local coords = vec3(-76.09, -818.93, 326.17) -- maze bank top
-- print('distance: ', tostring(coords.distance3d(players.me().coords)))
-- ```

---@class vec2
---@field x number
---@field y number
vec2 = {}

---@return vec2
function vec2:normalize() end

---@param other vec2
---@return number
function vec2:dot(other) end

---@overload fun(): vec2
---@overload fun(xy: number): vec2
---@overload fun(x: number, y: number): vec2
---@param x number
---@param y number
---@return vec2
function vec2(x, y) end

---@class vec3
---@field x number
---@field y number
---@field z number
vec3 = {}

---@return vec3
function vec3:normalize() end

---@return vec3
function vec3:dir() end

---@param other vec3
---@return number
function vec3:dot(other) end

---@param other vec3
---@return number
function vec3:distance3d(other) end

---@overload fun(): vec3
---@overload fun(xyz: number): vec3
---@overload fun(x: number, y: number, z: number): vec3
---@param x number
---@param y number
---@param z number
---@return vec3
function vec3(x, y, z) end

---@class scr_vec3
---@field x number
---@field y number
---@field z number
scr_vec3 = {}

---@return scr_vec3
function scr_vec3:normalize() end

---@return scr_vec3
function scr_vec3:dir() end

---@param other scr_vec3
---@return number
function scr_vec3:dot(other) end

---@param other scr_vec3
---@return number
function scr_vec3:distance3d(other) end

---@overload fun(): scr_vec3
---@overload fun(xyz: number): scr_vec3
---@overload fun(x: number, y: number, z: number): scr_vec3
---@param x number
---@param y number
---@param z number
---@return scr_vec3
function scr_vec3(x, y, z) end
