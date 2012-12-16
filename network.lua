--- Synchronises entities over the network.

local entity = require("entity")
local player = require("player")
local socket = require("socket")
local system = require("system")

local address
local commands = {}
local playerId
local local2net = {}
local net2local = {}
local netTime
local port
local sock
local timeOfLastPacket
local latency

local linkEntity = function (_local, net)
  local2net[_local] = net
  net2local[net] = _local
end

local M = {}

system.add(M)

--- Start client networking.
M.start = function (address, port)
  sock = socket.udp()
  sock:settimeout(0)
  sock:setpeername(address, port)
  
  -- Connect to server
  netTime = 0
  timeOfLastPacket = socket.gettime()
  
  sock:send("hi")
end

--- Stop the client networking.
M.stop = function ()
  sock:close()
  sock = nil
end

--- Handle server messages and send our network updates.
M.step = function (dt, entities)
  netTime = netTime + dt

  -- Handle server messages
  while true do
    local data = sock:receive()

    if data == nil then
      -- no more messages, stop this update step
      break
    end
    
    -- Expects: "[cmd] [args...]"
    local cmd = data:match("^(%S*)")
    local _, args = data:match("^(%S*) (.*)")
    
    -- Split the arguments into table, exclude command name
    args = table.remove(args:split(" "), 1)

    commands[cmd]()
  end
end

-- Change facing of a networked entity
commands.fac = function (args)
  local netId, x, y = args:match("^(%S*) (%S*) (%S*)$")
  netId = tonumber(netId)
  x = tonumber(x)
  y = tonumber(y)
  
  -- Update local entity
  local e = entity.get(net2local[netId])
  e.facing.x = x
  e.facing.y = y
end

-- Server acknowledge
commands.ok = function (args)
  latency = (socket.gettime() - timeOfLastPacket)
  netTime = tonumber(args[1]) + (latency / 2)
  playerId = tonumber(args[2])
end

-- Make a new networked entity
commands.mk = function (args)
  local netId, pid, type = args:match("^(%S*) (%S*) (%S*)")
  netId = tonumber(netId)
  local newPlayer
  if pid == playerId then
    newPlayer = player.newLocal()
  else
    newPlayer = player.newRemote()
  end
  linkEntity(newPlayer.id, netEntityId)
end

-- Move a networked entity
commands.mov = function (args)
  local netId, x, y = args:match("^(%S*) (%S*) (%S*)$")
  netId = tonumber(netId)
  x = tonumber(x)
  y = tonumber(y)
  
  -- Update local entity
  local e = entity.get(net2local[netId])
  e.position.x = x
  e.position.y = y
end

return M
