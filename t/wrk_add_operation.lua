
account_id_counter = 0
amount = 100

request = function()
  path = "/api/add/operation"
  wrk.method = "POST"
  wrk.body = string.format(
    '{"params":[{"account_id": %d, "timestamp": %d, "type": 0, "description": "Payment from WRK!","amount": %d}]}',
    account_id_counter, require('os').time(), amount)
  amount = amount + 1000
  account_id_counter = account_id_counter + 1
  if (account_id_counter > 100) then
      account_id_counter = 0
  end
  return wrk.format(nil, path)
end

