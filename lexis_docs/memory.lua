-- ============================================================
-- # Memory
-- ============================================================
--
-- ## Functions
--
-- ### base
-- Returns the base address of the game.
-- function memory.base(): integer
--
-- ### size
-- Returns the size (in memory) of the game.
-- function memory.size(): integer
--
-- ### alloc
-- Allocates memory.
-- ---@param size integer
-- function memory.alloc(size): memory_allocated
--
-- ### scan
-- Scans memory for a signature.
-- ---@param signature string
-- ---@param module? string
-- function memory.scan(signature, module?): memory_address
--
-- ## Types
--
-- ### pointer_int
-- | Type    | Name  |
-- |---------|-------|
-- | integer | value |
-- ---@param count? integer
-- function pointer_int(count?): pointer_int
-- function pointer_int:free(): nil
-- function pointer_int:address(): memory_address
--
-- ### pointer_bool
-- | Type | Name  |
-- |------|-------|
-- | bool | value |
-- ---@param count? integer
-- function pointer_bool(count?): pointer_bool
-- function pointer_bool:free(): nil
-- function pointer_bool:address(): memory_address
--
-- ### pointer_float
-- | Type   | Name  |
-- |--------|-------|
-- | number | value |
-- ---@param count? integer
-- function pointer_float(count?): pointer_float
-- function pointer_float:free(): nil
-- function pointer_float:address(): memory_address
--
-- ### pointer_scr_value
-- | Type      | Name  |
-- |-----------|-------|
-- | scr_value | value |
-- ---@param count? integer
-- function pointer_scr_value(count?): pointer_scr_value
-- function pointer_scr_value:free(): nil
-- function pointer_scr_value:address(): memory_address
--
-- ### memory_address
-- | Type           | Name        |
-- |----------------|-------------|
-- | integer        | value       |
-- | integer        | int8        |
-- | integer        | as_int8     |
-- | integer        | int16       |
-- | integer        | as_int16    |
-- | integer        | int32       |
-- | integer        | as_int32    |
-- | integer        | int64       |
-- | integer        | as_int64    |
-- | integer        | uint8       |
-- | integer        | as_uint8    |
-- | integer        | uint16      |
-- | integer        | as_uint16   |
-- | integer        | uint32      |
-- | integer        | as_uint32   |
-- | integer        | uint64      |
-- | integer        | as_uint64   |
-- | number         | float       |
-- | number         | as_float    |
-- | number         | double      |
-- | number         | as_double   |
-- | bool           | bool        |
-- | bool           | as_bool     |
-- | memory_address | ptr         |
-- | memory_address | as_ptr      |
-- | scr_vec3       | scr_vec3    |
-- | scr_vec3       | as_scr_vec3 |
-- | vec2           | vec2        |
-- | vec2           | as_vec2     |
-- | vec3           | vec3        |
-- | vec3           | as_vec3     |
-- | string         | str         |
-- | string         | as_str      |
-- ---@param count? integer
-- function memory_address:nop(count?): nil
-- ---@param offset integer
-- function memory_address:add(offset): memory_address
-- ---@param offset integer
-- function memory_address:sub(offset): memory_address
-- ---@param op_size? integer
-- ---@param insn_size? integer
-- function memory_address:rip(op_size?, insn_size?): memory_address
--
-- ### scr_value
-- | Type    | Name   |
-- |---------|--------|
-- | integer | int32  |
-- | integer | uint32 |
-- | integer | uint64 |
-- | number  | float  |
-- | bool    | bool   |
-- | string  | str    |
--
-- ### memory_allocated
-- function memory_allocated:free(): nil

---@class pointer_int
---@field value integer
pointer_int = {}

---@param count? integer
---@return pointer_int
function pointer_int(count) end

---@return nil
function pointer_int:free() end

---@return memory_address
function pointer_int:address() end

---@class pointer_bool
---@field value boolean
pointer_bool = {}

---@param count? integer
---@return pointer_bool
function pointer_bool(count) end

---@return nil
function pointer_bool:free() end

---@return memory_address
function pointer_bool:address() end

---@class pointer_float
---@field value number
pointer_float = {}

---@param count? integer
---@return pointer_float
function pointer_float(count) end

---@return nil
function pointer_float:free() end

---@return memory_address
function pointer_float:address() end

---@class pointer_scr_value
---@field value scr_value
pointer_scr_value = {}

---@param count? integer
---@return pointer_scr_value
function pointer_scr_value(count) end

---@return nil
function pointer_scr_value:free() end

---@return memory_address
function pointer_scr_value:address() end

---@class memory_address
---@field value     integer
---@field int8      integer
---@field as_int8   integer
---@field int16     integer
---@field as_int16  integer
---@field int32     integer
---@field as_int32  integer
---@field int64     integer
---@field as_int64  integer
---@field uint8     integer
---@field as_uint8  integer
---@field uint16    integer
---@field as_uint16 integer
---@field uint32    integer
---@field as_uint32 integer
---@field uint64    integer
---@field as_uint64 integer
---@field float     number
---@field as_float  number
---@field double    number
---@field as_double number
---@field bool      boolean
---@field as_bool   boolean
---@field ptr       memory_address
---@field as_ptr    memory_address
---@field scr_vec3    scr_vec3
---@field as_scr_vec3 scr_vec3
---@field vec2      vec2
---@field as_vec2   vec2
---@field vec3      vec3
---@field as_vec3   vec3
---@field str       string
---@field as_str    string
memory_address = {}

--- NOP bytes at this address.
---@param count? integer
---@return nil
function memory_address:nop(count) end

--- Returns address offset forward by count bytes.
---@param offset integer
---@return memory_address
function memory_address:add(offset) end

--- Returns address offset backward by count bytes.
---@param offset integer
---@return memory_address
function memory_address:sub(offset) end

--- Resolves a RIP-relative address.
---@param op_size? integer
---@param insn_size? integer
---@return memory_address
function memory_address:rip(op_size, insn_size) end

---@class scr_value
---@field int32  integer
---@field uint32 integer
---@field uint64 integer
---@field float  number
---@field bool   boolean
---@field str    string

---@class memory_allocated
memory_allocated = {}

---@return nil
function memory_allocated:free() end

---@class memory
memory = {}

--- Returns the base address of the game.
---@return integer
function memory.base() end

--- Returns the size (in memory) of the game.
---@return integer
function memory.size() end

--- Allocates memory.
---@param size integer
---@return memory_allocated
function memory.alloc(size) end

--- Scans memory for a signature.
---@param signature string
---@param module? string
---@return memory_address
function memory.scan(signature, module) end
