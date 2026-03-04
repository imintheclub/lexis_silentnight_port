-- ============================================================
-- # JSON
-- ============================================================
--
-- ## Functions
--
-- ### encode
-- Encodes a table into an instance of json.
-- ---@param data table
-- function json.encode(data): json
--
-- ### decode
-- Decodes an instance of json into a table.
-- ---@param json json
-- function json.decode(json): table
--
-- ## Types
--
-- ### dump
-- ---@param indent? integer
-- function json:dump(indent?): string
--
-- ## Example
-- ```lua
-- local data = {a=1, name='test'}
-- local json = json.encode(data)
-- print(json:dump()) -- '{ "a": 1, "name": "test" }'
-- ```

---@class json
json = {}

--- Encodes a table into an instance of json.
---@param data table
---@return json
function json.encode(data) end

--- Decodes an instance of json into a table.
---@param j json
---@return table
function json.decode(j) end

--- Dumps the json object to a formatted string.
---@param indent? integer
---@return string
function json:dump(indent) end
