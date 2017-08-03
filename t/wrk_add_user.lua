
account_id_counter = 0

request = function()
  path = "/api/add/user"
  wrk.method = "POST"
  wrk.body = string.format('{"params":[{"account_id": %d,"user_name":"%s" }]}',
    account_id_counter, 'Mr. Cool! ' .. tostring(account_id_counter))
  account_id_counter = account_id_counter + 1
  return wrk.format(nil, path)
end

