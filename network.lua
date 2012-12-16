--- Synchronises entities over the network.

local entity = require("entity")
local player = require("player")
local socket = require("socket")
local system = require("system")
local util = require("util")

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

local linkEntity(_local, net)
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
    local cmd, args = data:match("^(%S*) (.*)")
    
    -- Split the arguments into table, exclude command name
    args = table.remove(args:split(" "), 1)

    commands[cmd]()
  end
end

-- Change facing of a networked entity
commands.fac = function (args)
  local netId, x, y, vx, vy = args:match("^(%S*) (%S*) (%S*) (%S*) (%S*)")
  assert(netId and x and y and vx and vy)
  netId = tonumber(netId)
  x = tonumber(x)
  y = tonumber(y)
  vx = tonumber(vx)
  vy = tonumber(vy)
  local e = entity.get(net2local[netId])
  e.position.x = x
  e.position.y = y
end

-- Server acknowledge
commands.ok = function (args)
  latency = (socket.gettime() - timeOfLastPacket)
  netTime = tonumber(args[1]) + (latency / 2)
  playerId = tonumber(args[2])
end

-- Make a new networked entity
commands.mk = function (args)
  local theirPlayerId, netEntityId = args:match("^(%S*) (%S*)")
  assert(theirPlayerId and netEntityId)
  theirPlayerId = tonumber(theirPlayerId)
  netEntityId = tonumber(netEntityId)
  local newPlayer
  if theirPlayerId == playerId then
    newPlayer = player.newLocal()
  else
    newPlayer = player.newRemote()
  end
  local2net[newPlayer.id] = netEntityId
  net2local[netEntityId] = newPlayer.id
end

-- Move a networked entity
commands.mov = function (args)
  local netId, x, y, vx, vy = args:match("^(%S*) (%S*) (%S*) (%S*) (%S*)")
  assert(netId and x and y and vx and vy)
  netId = tonumber(netId)
  x = tonumber(x)
  y = tonumber(y)
  vx = tonumber(vx)
  vy = tonumber(vy)
  local e = entity.get(net2local[netId])
  e.position.x = x
  e.position.y = y
  
  if playerId then
    -- Send our updates
    if timer >= UPDATE_TIME then
      timer = 0
      for _,e in ipairs(entities) do
        if e.network and e.position and e.velocity then
          local netId = local2net[e.id]
          packet = string.format(
            "mov %u %f %f %f %f",
            netId,
            e.position.x,
            e.position.y,
            e.velocity.x,
            e.velocity.y
          )
          sock:send(packet)
        end
      end
    end
  end
end

return M
