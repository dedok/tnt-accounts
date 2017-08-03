#!/usr/bin/env tarantool
--
--
--

local yaml = require('yaml')
local core = require('core').new({listen='*:3112'})
local util = require('util')
--local shard = require('shard')


local methods = {
    ['POST'] = {
      ['/add/user'] = core.add_user,
      ['/add/operation'] = core.add_operation,
    },
    ['GET'] = {
      ['/get/operations'] = core.get_operations_for_period,
      ['/get/account/operations'] = core.get_last_n_operations,
      ['/get/account/balance'] = core.get_balance,
      ['/get/stat'] = core.get_stat,
    }
}


local function get_method_name(req)
  local r = ''
  local m = util.split(req.uri, '?')[1]
  for _, k in pairs(util.split(m, '/')) do
    if _ ~= 1 then
      r = r .. '/' .. k
    end
  end
  return r
end

--
-- Entry point
--
function api(req, ...)

  local method_name = get_method_name(req)
  local requested_methods = methods[req.method][method_name]
  if req.method == 'GET' then
    return requested_methods(core, req.args)
  elseif req.method == 'POST' then
    return requested_methods(core, ...)
  end

  error('Not allowed!')
end

