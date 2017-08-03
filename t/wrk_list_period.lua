
request = function()
  os = require('os')
  path = string.format("/api/get/operations?ts_start=%d&ts_end=%d",
      0, os.time())
  return wrk.format(nil, path)
end

