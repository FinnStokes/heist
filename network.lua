--- Synchronises entities over the network.

local action = require("action")
local entity = require("entity")
local event = require("event")
local player = require("player")
local socket = require("socket")
local system = require("system")
local timing = require("timing")

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

string.split = function (self, sep)
  local sep, fields = sep or ":", {}
  local pattern = string.format("([^%s]+)", sep)
  self:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

local onNewAction = function (player)
  if player.action then
    local packet
    if player.action.type == "turnTo" then
      packet = string.format(
        "trn %f %i %i",
        player.action.timestamp,
        player.action.facing.x,
        player.action.facing.y
      )
    elseif player.action.type == "moveTo" then
      packet = string.format(
        "mov %f %i %i",
        player.action.timestamp,
        player.location.x + player.action.delta.x,
        player.location.y + player.action.delta.y
      )
    end
    sock:send(packet)
  end
end

local M = {}

system.add(M)

--- Start client networking.
M.start = function (address, port)
  sock = socket.udp()
  sock:settimeout(0)
  sock:setpeername(address, port)
  
  event.subscribe("newAction", onNewAction)
  
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
    
    -- Split the arguments into table
    args = args:split(" ")

    commands[cmd](args)
  end
end

-- Change facing of a networked entity
commands.trn = function (args)
  local timestamp, netId, x, y = unpack(args)
  timestamp = tonumber(timestamp)
  netId = tonumber(netId)
  x = tonumber(x)
  y = tonumber(y)
  
  -- Update local entity
  local e = entity.get(net2local[netId])
  e.action = action.newTurn({
    x = x,
    y = y,
  }, timestamp)
end

-- Server acknowledge
commands.ok = function (args)
  latency = (socket.gettime() - timeOfLastPacket)
  netTime = tonumber(args[1]) + (latency / 2)
  timing.setOffset(netTime - timing.getTime())
  playerId = tonumber(args[2])
end

-- Make a new networked entity
commands.mk = function (args)
  local netId, pid, type = unpack(args)
  netId = tonumber(netId)
  pid = tonumber(pid)
  local newPlayer
  if pid == playerId then
    newPlayer = player.newLocal()
  else
    newPlayer = player.newRemote()
  end
  linkEntity(newPlayer.id, netId)
end

-- Move a networked entity
commands.mov = function (args)
  local timestamp, netId, x, y = unpack(args)
  timestamp = tonumber(timestamp)
  netId = tonumber(netId)
  x = tonumber(x)
  y = tonumber(y)
  
  -- Update local entity
  local e = entity.get(net2local[netId])
  e.action = action.newMove({
    x = x - e.location.x,
    y = y - e.location.y,
  }, timestamp)
end

return M
