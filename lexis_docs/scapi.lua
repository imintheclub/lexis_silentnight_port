-- ============================================================
-- # SC API
-- ============================================================
--
-- > **Warning:** The `query` function is blocking, it's recommended to
-- > call inside of a thread or job.
--
-- ## Functions
--
-- ### query
-- Fetch data for an account.
-- ---@param rid integer
-- function scapi.query(rid): scapi_rockstar_account
-- ---@param name string
-- ---@param page? integer
-- function scapi.query(name, page?): scapi_account_pagination
--
-- ## Types
--
-- ### scapi_rockstar_account
-- | Type    | Name    |
-- |---------|---------|
-- | string  | name    |
-- | integer | rid     |
-- | bool    | success |
--
-- ### scapi_result_info
-- | Type    | Name      |
-- |---------|-----------|
-- | integer | total     |
-- | integer | next_page |
-- | string  | query     |
--
-- ### scapi_account_pagination
-- | Type                     | Name     |
-- |--------------------------|----------|
-- | scapi_rockstar_account[] | accounts |
-- | scapi_result_info        | paged    |
-- | bool                     | success  |
--
-- ## Example
-- ```lua
-- function query_accounts(name, page)
--     local scinfo = scapi.query(name, page)
--     if scinfo.success then
--         for i, account in ipairs(scinfo.accounts) do
--             print('name: ', account.name)
--         end
--         if scinfo.paged.next_page > 0 then
--             query_accounts(name, scinfo.paged.next_page)
--         end
--     end
-- end
--
-- query_accounts('Rockstar', 0)
--
-- local scinfo = scapi.query(1)
-- if scinfo.success then
--     print('Name:', scinfo.name)
-- end
-- ```

---@class scapi_rockstar_account
---@field name    string
---@field rid     integer
---@field success boolean

---@class scapi_result_info
---@field total     integer
---@field next_page integer
---@field query     string

---@class scapi_account_pagination
---@field accounts scapi_rockstar_account[]
---@field paged    scapi_result_info
---@field success  boolean

---@class scapi
scapi = {}

--- Fetch data for an account by Rockstar ID.
---@param rid integer
---@return scapi_rockstar_account
function scapi.query(rid) end

--- Fetch a paginated list of accounts by name.
---@param name string
---@param page? integer
---@return scapi_account_pagination
function scapi.query(name, page) end
