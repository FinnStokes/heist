--- Synchronises entities over the network.

local LISTEN_PORT = 44000
local UPDATE_TIME = 0.1

local socket = require("socket")

local M = {}

local address
local playerId
local local2net = {}
local net2local = {}
local port
local sock
local timer

system.add(M)

M.start = function (address, port)
  sock = socket.udp
  sock:settimeout(0)
  sock:setpeername(address, port)
  
  -- Connect to server
  sock:send("connect")
  
  timer = 0
end

M.step = function (dt, entities)
  timer = timer + dt

  -- Handle server updates
  while true do
    local data = sock:receive()

    if data == nil then
      if msg_or_ip == "timeout" then
        -- No more packets, so finish this update
        break
      else
        -- Something bad happened, print message to error
        error("E: " .. tostring(msg))
      end
    end
    
    -- Expects: "[cmd] [args...]"
    local cmd, args = data:match("^(%S*) (.*)")
    
    if cmd == "connected" then
      -- We are connected
      playerId = tonumber(args:match("^(%S*) "))
    elseif cmd == "pos" then
      local netId, x, y = args:match("^(%S*) (%S*) (%S*) ")
      local e = entity.get(net2local[netId])
      e.position.x = x
      e.position.y = y
    end
  end

  if playerId then
    -- Send our updates
    if timer >= UPDATE_TIME then
      timer = 0
      for _,e in ipairs(entities) do
        if e.network then
          packet = string.format(
            "pos %f %f %f",
            netId,
            e.position.x,
            e.position.y
          )
          sock:send(packet)
        end
      end
    end
  end
end

return M
