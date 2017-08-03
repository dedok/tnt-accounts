
account_id_counter = 0

request = function()
  path = "/api/get/account/operations&account_id=" .. tostring(account_id_counter)
  account_id_counter = account_id_counter + 1
  return wrk.format(nil, path)
end

