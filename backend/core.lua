
--
--
--

local log = require('log')
local json = require('json')
local yaml = require('yaml')
local fiber = require('fiber')
local shard = require('shard')


local mt


mt = { __index = {

  tables = {},

  init = function(self, conf)

    local t = self.tables

    box.cfg {
      log_level = 5,
      listen = '*:3113',
      memtx_memory = 1024 * 1024 * 1024 * 10,
      wal_mode = 'write'
    }

    box.schema.user.grant('guest', 'read,write,execute',
                      'universe', nil, {if_not_exists = true})

    t.users = box.schema.space.create('users', {if_not_exists=true})
    t.users:create_index('id', {type='TREE', if_not_exists=true})
    t.users:create_index('account_id', {type='HASH', parts = {2, 'unsigned'},
        if_not_exists=true})
  
    --
    -- table
    --  * id - index uniq
    --  * user_id - index
    --  * ts - index
    --
    t.operations = box.schema.space.create('operations', {
      if_not_exists = true})
    t.operations:create_index('id', {type='TREE', if_not_exists=true})
    t.operations:create_index('user_id', {type='TREE', unique=false,
            if_not_exists = true, parts={2, 'unsigned'}})
    t.operations:create_index('user_and_timestamp', {
            type='TREE',
            unique=false,
            if_not_exists = true,
            parts={2, 'unsigned', 3, 'unsigned'}})
    t.operations:create_index('timestamp', {type='TREE', unique=false,
            if_not_exists=true, parts={3, 'unsigned'}})

    --shard.init {
    --    servers = {
    --        { uri = 'localhost:3111', zone = '0' },
    --        { uri = 'localhost:3112', zone = '0' },
    --        { uri = 'localhost:3113', zone = '1' },
    --        { uri = 'localhost:3114', zone = '1' },
    --    },

    --    login = 'guest',
    --    password = '',
    --    redundancy = 1,
    --}

    --t = shard

  end,


  make_user = function(tuple)
    return {
      id = tuple[1],
      account_id = tuple[2],
      user_name = tuple[3]
    }
  end,


  make_operation = function(tuple)
    return {
      id = tuple[1],
      user_id = tuple[2],
      timestamp = tuple[3],
      type = tuple[4],
      description = tuple[5],
      amount = tuple[6]
    }
  end,


  is_valid_operation_type = function(operation_type)
    return operation_type == 0 or
      operation_type == 1 or
      operation_type == 2
  end,


  add_user = function(self, user)
    return self.make_user(
      self.tables.users:auto_increment{user.account_id, user.user_name}
    )
  end,


  add_operation = function(self, operation)

    if not self.is_valid_operation_type(operation.type) then
      error('operation type should be 0 or 1, ' ..
            'where 0 - \'+\', 1 - \'-\', 2 - \'blocking\'')
    end

    local user = self.tables.users.index.account_id:get{operation.account_id}
    return {self.make_user(user),
          self.make_operation(
              self.tables.operations:auto_increment{
                  user[1],
                  operation.timestamp,
                  operation.type,
                  operation.description,
                  operation.amount}
          )}
  end,


  get_operations_for_period = function(self, args)

    local result = {}
    local user_table = self.tables.users
    local timestamp_index = self.tables.operations.index.timestamp
    local ts_start = tonumber(args.ts_start or 0)
    local ts_end = tonumber(args.ts_end or 0)
    local limit = tonumber(args.limit or 1000)

    box.begin()
    for _, tuple in pairs(
        timestamp_index:select(ts_start, {iterator = 'GE', limit = limit}))
    do
      if ts_end ~= nil and ts_end ~= 0 and tuple[3] >= ts_end then
        break
      end
      local operation = self.make_operation(tuple)
      local user = user_table:get{operation.user_id}
      table.insert(result, {self.make_user(user), operation})
    end

    box.commit()

    return {result}
  end,


  get_last_n_operations = function(self, args)

    local account_id = tonumber(args.account_id)
    local limit = tonumber(args.limit or 1000)
    local user = self.make_user(
      self.tables.users.index.account_id:get{account_id})
    local idx = self.tables.operations.index.user_and_timestamp
    local res = {}

    box.begin()
    for _, op in pairs(idx:select({user.id, math.floor(fiber.time())},
          {limit = limit, iterator='LE'}))
    do
      if op[2] ~= user.id then
        break
      end
      table.insert(res, self.make_operation(op))
    end
    box.commit()

    return {user, res}
  end,

  get_balance = function(self, args)

    local account_id = tonumber(args.account_id)
    local ts_start = tonumber(args.ts_start or 0)
    local ts_end = tonumber(args.ts_end or 0)
    local user = self.make_user(
      self.tables.users.index.account_id:get{account_id})
    local idx = self.tables.operations.index.user_and_timestamp

    local res = {['+'] = 0, ['-'] = 0, blocking = 0, total = 0}

    box.begin()
    for _, op in pairs(idx:select({user.id, ts_start},
          {limit = limit, iterator='GE'}))
    do
      if ts_end ~= nil and ts_end ~= 0
          and op[3] >= ts_end or op[2] ~= user.id then
        break
      end

      local type = op[4]
      local amount = op[6]

      --
      -- '+'
      --
      if type == 0 then
        res['+'] = res['+'] + amount

      --
      -- '-'
      --
      elseif type == 1 then
        res['+'] = res['+'] - amount

      --
      -- 'blocking'
      --
      elseif type == 2 then
        res['blocking'] = res['blocking'] + amount
      end

      res['total'] = res['total'] + amount
    end
    box.commit()

    return res
  end,

  get_stat = function(self)
    return {users = self.tables.users:count(),
            operations = self.tables.operations:count()}
  end,

} }


return {
    new = function(conf)
      local m = setmetatable({}, mt)
      m:init(conf)
      return m
    end
}

