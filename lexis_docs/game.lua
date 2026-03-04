-- ============================================================
-- # Game
-- ============================================================
--
-- ## is_session_free_roam
-- If you're in a free roam session (i.e, not in a mission).
-- function game.is_session_free_roam(): bool
--
-- ## in_game
-- If you're loaded into a game.
-- function game.in_game(): bool
--
-- ## net_obj_from_id
-- Net object memory address retrieved via an entity net id.
-- ---@param net_id integer
-- function game.net_obj_from_id(net_id): memory_address
--
-- ## net_obj_from_entity
-- Net object memory address retrieved via an entity handle.
-- ---@param entity integer
-- function game.net_obj_from_entity(entity): memory_address
--
-- ## update_net_obj_owner
-- Updates the owner of an entity.
-- ---@param entity integer
-- ---@param new_owner_player_id integer
-- function game.update_net_obj_owner(entity, new_owner_player_id): bool
--
-- ## entity_from_guid
-- Entity memory address retrieved via an entity handle.
-- ---@param entity integer
-- function game.entity_from_guid(entity): memory_address
--
-- ## guid_from_entity
-- Entity handle retrieved via an entity address.
-- ---@param entity integer|memory_address
-- function game.guid_from_entity(entity): integer
--
-- ## send_friend_request
-- Sends a friend request to an account.
-- ---@param rockstar_id integer
-- function game.send_friend_request(rockstar_id): nil
--
-- ## is_sc_ui_showing
-- If the Social Club UI is open.
-- function game.is_sc_ui_showing(): bool
--
-- ## is_transaction_busy
-- If there's an active basket transaction processing.
-- function game.is_transaction_busy(): bool
--
-- ## sync_tree
-- Sync tree memory address retrieved via a net object type (0-13).
-- ---@param type net_object|integer
-- function game.sync_tree(type): memory_address
--
-- ## state
-- The current state of the game.
-- function game.state(): integer
--
-- ## resolution
-- The game window resolution.
-- function game.resolution(): vec2
--
-- ## delta
-- The game delta.
-- function game.delta(): number
--
-- ## host
-- The session host as a player.
-- function game.host(): player
--
-- ## basket_transaction
-- Processes a basket transaction.
-- ---@param category integer
-- ---@param action integer
-- ---@param destination integer
-- ---@param items table[] { id, extra_inventory_id, price, stat, quantity }
-- function game.basket_transaction(category, action, destination, items): nil
--
-- ## invite_rockstar_id
-- Invites a player to your session.
-- ---@param rockstar_id integer|integer[]
-- function game.invite_rockstar_id(rockstar_id): nil
--
-- ## get_model_info
-- Model info memory address retrieved via the model.
-- ---@param model string|integer
-- function game.get_model_info(model): memory_address
--
-- ### Example
-- ```lua
-- -- add $15M to the bank (2 for bank, 1 for wallet) !! detected !!
-- game.basket_transaction(joaat('CATEGORY_SERVICE_WITH_THRESHOLD'), joaat('NET_SHOP_ACTION_EARN'), 2, {
--     { joaat('SERVICE_EARN_BEND_JOB'), 1, 15000000, 0, 1 }
-- })
--
-- -- print your ped address
-- print('CPed: ' .. tostring(game.entity_from_guid(players.me().ped)).value)
-- ```
---@class game
game = {}
--- If you're in a free roam session (i.e, not in a mission).
---@return boolean
function game.is_session_free_roam() end
--- If you're loaded into a game.
---@return boolean
function game.in_game() end
--- Net object memory address retrieved via an entity net id.
---@param net_id integer
---@return memory_address
function game.net_obj_from_id(net_id) end
--- Net object memory address retrieved via an entity handle.
---@param entity integer
---@return memory_address
function game.net_obj_from_entity(entity) end
--- Updates the owner of an entity.
---@param entity integer
---@param new_owner_player_id integer
---@return boolean
function game.update_net_obj_owner(entity, new_owner_player_id) end
--- Entity memory address retrieved via an entity handle.
---@param entity integer
---@return memory_address
function game.entity_from_guid(entity) end
--- Entity handle retrieved via an entity address.
---@param entity integer|memory_address
---@return integer
function game.guid_from_entity(entity) end
--- Sends a friend request to an account.
---@param rockstar_id integer
---@return nil
function game.send_friend_request(rockstar_id) end
--- If the Social Club UI is open.
---@return boolean
function game.is_sc_ui_showing() end
--- If there's an active basket transaction processing.
---@return boolean
function game.is_transaction_busy() end
--- Sync tree memory address retrieved via a net object type (0-13).
---@param type net_object|integer
---@return memory_address
function game.sync_tree(type) end
--- The current state of the game.
---@return integer
function game.state() end
--- The game window resolution.
---@return vec2
function game.resolution() end
--- The game delta.
---@return number
function game.delta() end
--- The session host as a player.
---@return player
function game.host() end
--- Processes a basket transaction.
---@param category integer
---@param action integer
---@param destination integer
---@param items table[]
---@return nil
function game.basket_transaction(category, action, destination, items) end
--- Invites a player to your session.
---@param rockstar_id integer|integer[]
---@return nil
function game.invite_rockstar_id(rockstar_id) end
--- Model info memory address retrieved via the model.
---@param model string|integer
---@return memory_address
function game.get_model_info(model) end
