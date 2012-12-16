--- Low level timing manager

local socket = require("socket")

local start = socket.gettime()
local offset = 0

local M = {}

M.setOffset = function (dt)
  offset = dt
end

M.getTime = function ()
  return socket.gettime() - start + offset
end

return M