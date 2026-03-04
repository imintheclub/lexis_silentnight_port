-- ============================================================
-- # HTTP
-- ============================================================
--
-- > **Warning:** The `fetch` function is blocking.
--
-- ## Functions
--
-- ### fetch
-- Fetch data from a URL.
-- ---@param url string
-- ---@param options { method: string, headers: table<string, string>[], body: string|integer[]|json }
-- function http.fetch(url, options): http_result
--
-- ### fetch_async
-- Fetch data from a URL async.
-- ---@param url string
-- ---@param options { method: string, headers: table<string, string>[], body: string|integer[]|json }
-- ---@param callback function(http_result)
-- function http.fetch_async(url, options, callback): bool
--
-- ## Types
--
-- ### http_result
-- | Type                    | Name    |
-- |-------------------------|---------|
-- | bool                    | success |
-- | integer                 | status  |
-- | integer                 | error   |
-- | table<string, string>[] | headers |
-- | integer[]               | body    |
-- | string                  | text    |
-- | table                   | json    |
--
-- ## Example
-- ```lua
-- local result = http.fetch('https://pastebin.com/raw/kNAcSPLC', { method='GET' })
-- if result.success then
--     print(result.text)
-- end
--
-- http.fetch_async('https://pastebin.com/raw/kNAcSPLC', { method='GET' }, function(data)
--     print('data:' .. data.text)
-- end)
-- ```

---@class http_result
---@field success boolean
---@field status  integer
---@field error   integer
---@field headers table<string, string>[]
---@field body    integer[]
---@field text    string
---@field json    table

---@class http
http = {}

--- Fetch data from a URL. Blocking.
---@param url string
---@param options { method: string, headers: table<string, string>[], body: string|integer[]|table }
---@return http_result
function http.fetch(url, options) end

--- Fetch data from a URL async.
---@param url string
---@param options { method: string, headers: table<string, string>[], body: string|integer[]|table }
---@param callback fun(result: http_result)
---@return boolean
function http.fetch_async(url, options, callback) end
