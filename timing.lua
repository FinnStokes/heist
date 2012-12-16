--- Low level timing manager

local socket = require("socket")

local start = socket.gettime()
local offset = 0
local netTime = 0

local M = {}

M.setOffset = function (dt)
  offset = dt
end

M.update = function (dt)
  netTime = socket.gettime() - start + offset
end

M.getTime = function ()
  return netTime
end

return M